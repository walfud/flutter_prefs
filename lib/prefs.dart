import 'dart:async';
import 'package:sqflite/sqflite.dart';

class Prefs {
  static const String _spliter = '.';

  // Value type
  static const int unknownValueType = 0;
  static const int intValueType = 1;
  static const int floatValueType = 2;
  static const int stringValueType = 3;
  static const int binaryValueType = 4;

  // Factory
  // We maintain a static instance map for both effeciency and consistency
  static Map<String, Prefs> _instanceMap = {};
  static Future<Prefs> defaultInstance() => getInstance();
  static Future<Prefs> getInstance([String name = '']) async {
    name = name ?? '';
    if (_instanceMap[name] == null) {
      _instanceMap[name] = new Prefs._internal(name);
      await _instanceMap[name]._initialize();
    }

    return _instanceMap[name];
  }

  // Private constructor
  String _name;
  Prefs._internal(this._name);

  Database _db;
  Map<String, Object> _cache = new Map<String, Object>();
  Future<void> _initialize() async {
    _db = await openDatabase('prefs.db', version: 1,
        onCreate: (Database dbOnCreate, int version) async {
      await dbOnCreate.execute('''
        CREATE TABLE `data`(
          id INTEGER PRIMARY KEY AUTOINCREMENT,

          domain TEXT,
          key TEXT,
          value TEXT,
          valueType INTEGER
        );
      ''');

      await dbOnCreate.execute('''
        CREATE INDEX domainKeyIndex ON data(domain, key);
      ''');
    });

    // Load
    final rows = await _db.query('data', where: 'domain=?', whereArgs: [_name]);
    for (var row in rows) {
      String key = row['key'];
      Object value = row['value'];
      int valueType = row['valueType'];
      switch (valueType) {
        case intValueType:
          _setCacheValue(key, value as int);
          break;
        case floatValueType:
          _setCacheValue(key, value as double);
          break;
        case stringValueType:
          _setCacheValue(key, value as String);
          break;
          // case binaryValueType:
          //   _setCacheValue(key, value as );
          break;
        default:
          break;
      }
    }

    return Future.value(null);
  }

  Future<T> setValue<T>(String key, T value) {
    // Cache
    final originValue = _setCacheValue(key, value);

    // Persist
    return originValue == value
        ? Future.value(null)
        : _db.transaction((Transaction txn) async {
            await txn.delete(
              'data',
              where: 'domain=? AND key like ?',
              whereArgs: [_name, '$key%'],
            );

            await txn.insert(
              'data',
              {
                'domain': _name,
                'key': key,
                'value': value,
                'valueType': _getValueType(value),
              },
            );
          });
  }

  Object _setCacheValue<T>(String key, T value) {
    final path = _parsePath(key);

    // Construct path table
    Map<String, Object> currTable = _cache;
    for (var i in path.sublist(0, path.length - 1)) {
      if (currTable[i] is! Map) {
        // New path or Overwrite original leaf
        currTable[i] = new Map<String, Object>();
      }

      currTable = currTable[i];
    }

    // Mount value on leaf
    final leaf = path.last;
    final originValue = currTable[leaf];
    currTable[leaf] = value;

    return originValue;
  }

  T getValue<T>(String key) {
    final path = _parsePath(key);

    //
    Map<String, Object> currTable = _cache;
    for (var i in path.sublist(0, path.length - 1)) {
      if (currTable[i] is! Map) {
        // New path or Overwrite original leaf
        return null;
      }

      currTable = currTable[i];
    }

    String leaf = path.last;
    return currTable[leaf];
  }

  List<String> _parsePath(String key) {
    if (key == null || key.isEmpty) {
      throw ArgumentError('`key` MUST NOT empty');
    }

    return key.split(_spliter);
  }

  // Utils
  static int _getValueType(Object value) {
    if (value is int) {
      return intValueType;
    } else if (value is double) {
      return floatValueType;
    } else if (value is String) {
      return stringValueType;
      // } else if (value is ) {
      //   return binaryValueType;
    } else {
      return unknownValueType;
    }
  }
}
