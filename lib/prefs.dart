import 'dart:async';
import 'package:sqflite/sqflite.dart';

class Prefs {
  static const String _spliter = '.';

  static Prefs _sInstance;
  static Prefs defaultInstance() {
    if (_sInstance == null) {
      _sInstance = new Prefs(null);
    }

    return _sInstance;
  }

  String name;
  Prefs(this.name);

  Future<void> initialize() async {
    Database db = await openDatabase('prefs.db', version: 1, onCreate: (Database dbOnCreate, int version) async {
      // Prefernece table
      await dbOnCreate.execute("""
        CREATE TABLE `data`(
          id INTEGER PRIMARY KEY AUTOINCREMENT,

          domain TEXT,
          path TEXT,
          valueType INTEGER,
          valueData TEXT
        );
      """);
    });

    return Future.value(null);
  }

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

    // TODO: sqlite write

    return new Future.value(null);
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
}
