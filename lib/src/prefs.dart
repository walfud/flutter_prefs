import 'dart:async';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';
import 'package:tuple/tuple.dart';

import './value_info.dart';

typedef void DebugListener(int id, String desc, [Object obj]);

class Prefs {
  static const String _spliter = '.';

  // Value type
  static const int intValueType = 1;
  static const int floatValueType = 2;
  static const int stringValueType = 3;
  static const int binaryValueType = 4;

  // Value column name
  static const String intValueColumnName = 'intValue';
  static const String floatValueColumnName = 'floatValue';
  static const String stringValueColumnName = 'stringValue';
  static const String binaryValueColumnName = 'binaryValue';

  // Factory
  // We maintain a static instance map for both efficiency and consistency
  static Map<String, Prefs> _instanceMap = {};

  static Future<Prefs> defaultInstance({int debugId}) => getInstance(debugId: debugId);

  static Future<Prefs> getInstance({
    String name = '',
    int debugId,
  }) async {
    name = name ?? '';
    if (_instanceMap[name] == null) {
      _instanceMap[name] = new Prefs._internal(name);
      await _instanceMap[name]._initialize();

      safeDebugCall(debugId, 'instance: create new instance "$name"');
    } else {
      safeDebugCall(debugId, 'instance: reuse "$name"');
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
        CREATE TABLE data(
          id INTEGER PRIMARY KEY AUTOINCREMENT,

          domain TEXT,
          key TEXT,
          
          valueType INTEGER,
          intValue INTEGER,
          floatValue REAL,
          stringValue TEXT,
          binaryValue BLOB
        );
      ''');

      await dbOnCreate.execute('''
        CREATE INDEX domainKeyIndex ON data(domain, key);
      ''');
    });

    // Load
    final rows = await _db.query('data',
        where: 'domain=?', whereArgs: [_name], orderBy: 'id ASC');
    for (var row in rows) {
      String key = row['key'];
      int valueType = row['valueType'];
      switch (valueType) {
        case intValueType:
          _setCacheValue<int>(key, row[intValueColumnName]);
          break;
        case floatValueType:
          _setCacheValue<double>(key, row[floatValueColumnName]);
          break;
        case stringValueType:
          _setCacheValue<String>(key, row[stringValueColumnName]);
          break;
        case binaryValueType:
          _setCacheValue<Uint8List>(key, row[binaryValueColumnName]);
          break;
        default:
          throw new ArgumentError.value(valueType, 'valueType');
      }
    }

    return Future.value(null);
  }

  Future<T> setValue<T>(String key, T value, { int debugId }) {
    // Cache
    final originValueAndRemovedKeys = _setCacheValue(key, value, debugId: debugId);
    final removedPrefixPaths = originValueAndRemovedKeys.item1;
    final originValue = originValueAndRemovedKeys.item2;

    // Persist
    return originValue == value && removedPrefixPaths.isEmpty
        ? Future.value(null)
        : _db.transaction((Transaction txn) async {
            // Remove prefix path
            if (removedPrefixPaths.isNotEmpty) {
              final removedPrefixCount = await txn.delete(
                'data',
                where: 'domain=? AND key IN (?)',
                whereArgs: [_name, removedPrefixPaths.join(',')],
              );
              safeDebugCall(debugId, 'set: db delete "$removedPrefixCount" prefix path');
            }

            // Remove postfix path
            final removedPostfixCount = await txn.delete(
              'data',
              where: 'domain=? AND key like ?',
              whereArgs: [_name, '$key%'],
            );
            safeDebugCall(debugId, 'set: db delete "$removedPostfixCount" postfix path');

            final valueInfo = new ValueInfo(value);
            final newId = await txn.insert(
              'data',
              {
                'domain': _name,
                'key': key,
                'valueType': valueInfo.type,
                valueInfo.columnName: value,
              },
            );
            safeDebugCall(debugId, 'set: db insert row id "$newId"');
          });
  }

  Tuple2<List<String>, Object> _setCacheValue<T>(String key, T value, { int debugId }) {
    List<String> removedPrefixPaths = [];

    final pathAndLeaf = _parsePathAndLeaf(key);

    // Construct path table
    Map<String, Object> currTable = _cache;
    List<String> passby = [];
    final path = pathAndLeaf.item1;
    for (var i in path) {
      passby.add(i);

      if (currTable[i] == null) {
        // New path
        currTable[i] = new Map<String, Object>();
      } else if (currTable[i] is! Map) {
        // Overwrite original leaf
        currTable[i] = new Map<String, Object>();
        removedPrefixPaths.add(passby.join(_spliter));
      }

      currTable = currTable[i];
    }

    // Mount value on leaf
    final leaf = pathAndLeaf.item2;
    final originValue = currTable[leaf];
    currTable[leaf] = value;

    return new Tuple2(removedPrefixPaths, originValue);
  }

  T getValue<T>(String key) {
    final pathAndLeaf = _parsePathAndLeaf(key);

    //
    Map<String, Object> currTable = _cache;
    final path = pathAndLeaf.item1;
    for (var i in path) {
      if (currTable[i] is! Map) {
        // New path or Overwrite original leaf
        return null;
      }

      currTable = currTable[i];
    }

    String leaf = pathAndLeaf.item2;
    return currTable[leaf];
  }

  Tuple2<List<String>, String> _parsePathAndLeaf(String key) {
    if (key == null || key.isEmpty) {
      throw ArgumentError('`key` MUST NOT empty');
    }

    final nodes = key.split(_spliter);
    return new Tuple2(nodes.sublist(0, nodes.length - 1), nodes.last);
  }

  // Debug
  static DebugListener _debugListener;
  static void setDebugListener(DebugListener listener) {
    _debugListener = listener;
  }

  static void safeDebugCall(int id, String desc, [Object obj]) {
    if (_debugListener != null) {
      _debugListener(id, desc, obj);
    }
  }
}
