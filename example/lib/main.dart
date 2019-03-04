import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prefs/prefs.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _inputKey = '', _inputValue = '';
  String _output = '';
  List<String> _tips = [];
  Prefs _prefs;
  SharedPreferences _sharedPreferences;
  LibMethodFactory _methodFactory;
  LibMethodFactory _prefsMethodFactory, _sharedpreferencesMethodFactory;

  @override
  void initState() {
    super.initState();
    _prefsMethodFactory = _methodFactory = new LibMethodFactory(
      onSet: () async {
        int debugId = nextDebugId();
        final start = DateTime.now();
        Future<void> res = _prefs
            .setValue(_inputKey, _inputValue, debugId: debugId);
        final end = DateTime.now();
        await res;
        final awaitEnd = DateTime.now();
        setState(() {
          final cost = end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
          final awaitCost = awaitEnd.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
          _tips.add('$debugId'.padLeft(5) + ' -> ' + 'prefs set: cache cost $cost ms, persist cost $awaitCost ms');
        });
      },
      onGet: () {
        final start = DateTime.now();
        final res = _prefs.getValue(_inputKey);
        final end = DateTime.now();
        setState(() {
          _output = res.toString();

          int debugId = nextDebugId();
          final cost = end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
          _tips.add('$debugId'.padLeft(5) + ' -> ' + 'prefs get: cost: $cost ms');
        });
      },
    );
    _sharedpreferencesMethodFactory = new LibMethodFactory(
      onSet: () async {
        int debugId = nextDebugId();
        final start = DateTime.now();
        Future<void> res = _sharedPreferences.setString(
            _inputKey, _inputValue);
        final end = DateTime.now();
        await res;
        final awaitEnd = DateTime.now();
        setState(() {
          final cost = end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
          final awaitCost = awaitEnd.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
          _tips.add('$debugId'.padLeft(5) + ' -> ' + 'shared_preferences set: cache cost $cost ms, persist cost $awaitCost ms');
        });
      },
      onGet: () {
        final start = DateTime.now();
        final res = _sharedPreferences.getString(_inputKey);
        final end = DateTime.now();
        setState(() {
          _output = res.toString();

          int debugId = nextDebugId();
          final cost = end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
          _tips.add('$debugId'.padLeft(5) + ' -> ' + 'shared_preferences get: cost: $cost ms');
        });
      },
    );

    Prefs.setDebugListener((debugId, desc, [obj]) {
      setState(() {
        _tips.add('$debugId'.padLeft(5) + ' -> ' + desc);
      });
    });

    final initializeStartTime = DateTime.now();
    Prefs.defaultInstance(debugId: nextDebugId()).then((prefs) {
      final initializeEndTime = DateTime.now();
      setState(() {
        int debugId = nextDebugId();
        final cost = initializeEndTime.millisecondsSinceEpoch -
            initializeStartTime.millisecondsSinceEpoch;
        _tips.add(
            '$debugId'.padLeft(5) + ' -> ' + 'prefs initialize: cost "$cost" ms');
      });

      _prefs = prefs;
    });

    final sharedPreferenceInitializeStartTime = DateTime.now();
    SharedPreferences.getInstance().then((sharedPreferences) {
      final sharedPreferenceInitializeEndTime = DateTime.now();
      setState(() {
        int debugId = nextDebugId();
        final cost = sharedPreferenceInitializeEndTime.millisecondsSinceEpoch - sharedPreferenceInitializeStartTime.millisecondsSinceEpoch;
        _tips.add(
            '$debugId'.padLeft(5) + ' -> ' + 'shared_preferences initialize: cost "$cost" ms');
      });

      _sharedPreferences = sharedPreferences;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: <Widget>[
            // Compare
            Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Expanded(
                  child: RadioListTile(
                    title: Text('prefs'),
                    value: _prefsMethodFactory,
                    groupValue: _methodFactory,
                    onChanged: _onLibChange,
                  ),
                ),
                Expanded(
                  child: RadioListTile(
                    title: Text('shared_preferences'),
                    value: _sharedpreferencesMethodFactory,
                    groupValue: _methodFactory,
                    onChanged: _onLibChange,
                  ),
                ),
              ],
            ),

            // Input
            Row(
              children: <Widget>[
                Expanded(
                  flex: 4,
                  child: TextField(
                    onChanged: (input) {
                      _inputKey = input;
                    },
                    decoration: InputDecoration(
                      hintText: 'key: foo.bar',
                    ),
                  ),
                ),
                Spacer(flex: 1),
                Expanded(
                  flex: 4,
                  child: TextField(
                    onChanged: (input) {
                      _inputValue = input;
                    },
                    decoration: InputDecoration(
                      hintText: 'value: 1234',
                    ),
                  ),
                ),
                Column(
                  children: <Widget>[
                    RaisedButton(
                      child: Text('Set'),
                      onPressed: _methodFactory.onSet,
                    ),
                    RaisedButton(
                      child: Text('Get'),
                      onPressed: _methodFactory.onGet,
                    ),
                  ],
                ),
              ],
            ),

            // Output
            Text(
              _output,
            ),

            // Tip
            Expanded(
              child: ListView.separated(
                itemBuilder: (BuildContext context, int index) {
                  final tip = _tips[_tips.length - 1 - index];
                  return Text(tip);
                },
                separatorBuilder: (BuildContext context, int index) {
                  return Divider(height: 1);
                },
                itemCount: _tips.length,
              ),
            )
          ],
        ),
      ),
    );
  }

  void _onLibChange(LibMethodFactory factory) => setState(() {
        _methodFactory = factory;
      });

  // Debug
  static int _debugId = 0;

  int nextDebugId() => ++_debugId;
}

class LibMethodFactory {
  Function onSet;
  Function onGet;

  LibMethodFactory({
    this.onSet,
    this.onGet,
  });
}
