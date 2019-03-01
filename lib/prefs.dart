import 'dart:async';
import 'package:sqflite/sqflite.dart';

class Prefs {
  static const String _spliter = '.';
  static Database _db;

  // Value type
  static int unknownValueType = 0;
  static int intValueType = 1;
  static int floatValueType = 2;
  static int stringValueType = 3;
  static int binaryValueType = 4;

  static Future<void> initialize() async {
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

    // TODO: load

    return Future.value(null);
  }

  static Prefs _sInstance;
  static Prefs defaultInstance() {
    if (_sInstance == null) {
      _sInstance = new Prefs(null);
    }

    return _sInstance;
  }

  String _name;
  Prefs(this._name);

  Map<String, Object> _cache = new Map<String, Object>();
  Future<T> setValue<T>(String key, T value) {
    var path = _parsePath(key);

    // Construct path table
    Map<String, Object> currTable = _acquireTable();
    for (var i in path.sublist(0, path.length - 1)) {
      if (currTable[i] is! Map) {
        // New path or Overwrite original leaf
        currTable[i] = new Map<String, Object>();
      }

      currTable = currTable[i];
    }

    // Mount value on leaf
    var leaf = path.last;
    var originValue = currTable[leaf];
    currTable[leaf] = value;

    // Persist
    return originValue == value
        ? Future.value(null)
        : _db.transaction((Transaction txn) async {
            var domainCond = _name == null ? 'domain IS ?' : 'domain=?';
            await txn.delete(
              'data',
              where: '$domainCond AND key like ?',
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

  T getValue<T>(String key) {
    var path = _parsePath(key);

    //
    Map<String, Object> currTable = _acquireTable();
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
  Map<String, Object> _acquireTable() {
    if (_cache[_name] == null) {
      _cache[_name] = new Map<String, Object>();
    }

    return _cache[_name];
  }

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
