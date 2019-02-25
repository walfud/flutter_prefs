import 'dart:async';

import 'package:flutter/services.dart';

class Prefs {
  static const MethodChannel _channel = const MethodChannel('prefs');
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

  Map<String, Object> cache = new Map<String, Object>();
  void setValue(String key, Object value) {
    if (key == null || key.isEmpty) {
      throw ArgumentError('`key` MUST NOT empty');
    }

    final keys = key.split(_spliter);

    // Construct path
    Map<String, Object> currTable = cache;
    for (var path in keys.sublist(0, keys.length - 1)) {
      if (currTable[path]?.runtimeType != Map) {
        // New path or Overwrite original leaf
        currTable[path] = new Map<String, Object>();
      }

      currTable = currTable[path];
    }

    // Mount value on leaf
    String leaf = keys.last;
    currTable[leaf] = value;

    return;
  }

  Object getValue(String key) {
    return null;
  }
}
