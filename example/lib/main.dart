import 'package:flutter/material.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();

    Prefs.setDebugListener((debugId, desc, [obj]) {
      setState(() {
        _tips.add('$debugId'.padLeft(5) + ':' + desc);
      });
    });
    Prefs.defaultInstance(debugId: nextDebugId())
        .then((prefs) {
            _prefs = prefs;

            setState(() {
              _inputKey = 'foo';
              _inputValue = '1234';
            });
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
                      onPressed: () async {
                        int debugId = nextDebugId();
                        final start = DateTime.now();
                        Future<void> res = _prefs.setValue(_inputKey, _inputValue, debugId: debugId);
                        final end = DateTime.now();
                        await res;
                        final awaitEnd = DateTime.now();
                        final cost = end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
                        final awaitCost = awaitEnd.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
                        setState(() {
                          _tips.add('$debugId'.padLeft(5) + ':' + 'set: cost $cost ms, persist cost $awaitCost ms');
                        });
                      },
                    ),
                    RaisedButton(
                      child: Text('Get'),
                      onPressed: () {
                        int debugId = nextDebugId();
                        final start = DateTime.now();
                        final res = _prefs.getValue(_inputKey);
                        final end = DateTime.now();
                        final cost = end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
                        setState(() {
                          _output = res.toString();
                          _tips.add('$debugId'.padLeft(5) + ':' + 'get: cost: $cost ms');
                        });
                      },
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

  // Debug
  static int _debugId = 0;
  int nextDebugId() => ++_debugId;
}
