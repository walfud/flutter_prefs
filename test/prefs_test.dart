import 'package:test/test.dart';
import 'package:prefs/prefs.dart';

void main() {
  group('Memory Prefs', () {
    Prefs prefs;

    setUp(() async {
      prefs = Prefs.defaultInstance();
      // await prefs.initialize();    // not support: https://github.com/tekartik/sqflite/issues/83 
      print('asdf');
    });

    tearDown(() {});

    test('leaf', () async {
      prefs.setValue('foo', 123);
      expect(prefs.getValue('foo'), 123);

      prefs.setValue('bar', 'song');
      prefs.setValue('bar', 'walfud'); // over write
      expect(prefs.getValue('bar'), 'walfud');
    });

    test('path', () async {
      prefs.setValue('a', 1);
      expect(prefs.getValue('a'), 1);

      // path over write
      prefs.setValue('a.b', 12);
      expect(prefs.getValue('a.b'), 12);

      prefs.setValue('a.c', 13);
      expect(prefs.getValue('a.c'), 13);

      // path value
      Map<String, Object> pathValue = prefs.getValue('a');
      expect(pathValue['b'], 12);
      expect(pathValue['c'], 13);
    });
  });
}
