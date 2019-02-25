import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
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

    _prefs = Prefs.defaultInstance();
    setState(() {
      _inputKey = 'foo';
      _inputValue = '1234';

      _tips.add('Start');
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
                      onPressed: () {
                        var start = DateTime.now();
                        _prefs.setValue(_inputKey, _inputValue);
                        var end = DateTime.now();
                        var cost = end.microsecondsSinceEpoch - start.microsecondsSinceEpoch;
                        setState(() {
                          _tips.add('set: cost $cost microsecond');
                        });
                      },
                    ),
                    RaisedButton(
                      child: Text('Get'),
                      onPressed: () {
                        var start = DateTime.now();
                        var res = _prefs.getValue(_inputKey);
                        var end = DateTime.now();
                        var cost = end.microsecondsSinceEpoch - start.microsecondsSinceEpoch;
                        setState(() {
                          _tips.add('get($res): cost: $cost microsecond');
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
                  var tip = _tips[_tips.length - 1 - index];
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
}
