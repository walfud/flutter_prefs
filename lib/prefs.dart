import 'dart:async';
import 'package:sqflite/sqflite.dart';

class Prefs {
  static const String _spliter = '.';
  static Database _db;

  static void initialize() async {
    _db = await openDatabase('prefs.db', version: 1,
        onCreate: (Database dbOnCreate, int version) async {
      // Prefernece table
      await dbOnCreate.execute("""
        CREATE TABLE `data`(
          id INTEGER PRIMARY KEY AUTOINCREMENT,

          domain TEXT,
          key TEXT,
          value TEXT,
          valueType INTEGER
        );
      """);
    });

    return Future.value(null);
  }

  static Prefs _sInstance;
  static Prefs defaultInstance() {
    if (_sInstance == null) {
      _sInstance = new Prefs(null);
    }

    return _sInstance;
  }

  String name;
  Prefs(this.name);

  Map<String, Object> cache = new Map<String, Object>();
  Future<Object> setValue(String key, Object value) {
    var path = _parsePath(key);

    // Construct path table
    Map<String, Object> currTable = cache;
    for (var i in path.sublist(0, path.length - 1)) {
      if (currTable[i] is! Map) {
        // New path or Overwrite original leaf
        currTable[i] = new Map<String, Object>();
      }

      currTable = currTable[i];
    }

    // Mount value on leaf
    String leaf = path.last;
    currTable[leaf] = value;

    // Persist
    return _db.update(
      'data',
      {
        'value': value,
        'valueType': _getValueType(value),
      },
      where: 'domain=? AND key=?',
      whereArgs: [name, key],
      conflictAlgorithm: ConflictAlgorithm.replace,
    ).then((affectedRowCount) {
      print(affectedRowCount);
    });
  }

  Object getValue(String key) {
    var path = _parsePath(key);

    //
    Map<String, Object> currTable = cache;
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
    if (value is int || value is double) {
      return 1;
    } else if (value is String) {
      return 2;
    } else {
      return 0;
    }
  }
}
