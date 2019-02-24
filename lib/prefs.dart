import 'dart:async';

import 'package:flutter/services.dart';

class Prefs {
  static const MethodChannel _channel = const MethodChannel('prefs');

  static Prefs _sInstance;
  static Prefs defaultInstance() {
    if (_sInstance == null) {
      _sInstance = new Prefs(null);
    }

    return _sInstance;
  }

  String name;
  Prefs(this.name);

  Map<String, Object> cache = new Map();
  void setValue(String key, Object value) {
    return;
  }
  Object getValue(String key) {
    return null;
  }
}
