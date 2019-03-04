import 'dart:typed_data';

import './prefs.dart';

class ValueInfo {
  Object value;
  int type;
  String columnName;

  ValueInfo(Object value) {
    this.value = value;
    if (value is int) {
      type = Prefs.intValueType;
      columnName = Prefs.intValueColumnName;
    } else if (value is double) {
      type = Prefs.floatValueType;
      columnName = Prefs.floatValueColumnName;
    } else if (value is String) {
      type = Prefs.stringValueType;
      columnName = Prefs.stringValueColumnName;
    } else if (value is Uint8List) {
      type = Prefs.intValueType;
      columnName = Prefs.binaryValueColumnName;
    } else {
      throw new ArgumentError.value(value, 'type');
    }
  }
}
