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
        body: Center(
          child: Column(
            children: <Widget>[
              // Input
              Row(
                children: <Widget>[
                  Expanded(
                      child: Row(
                    children: <Widget>[
                      TextField(
                        onChanged: (input) {
                          _inputKey = input;
                        },
                      ),
                      TextField(
                        onChanged: (input) {
                          _inputValue = input;
                        },
                      ),
                    ],
                  )),
                  Column(
                    children: <Widget>[
                      RaisedButton(
                        child: Text('Set'),
                        onPressed: () {
                          var tip = '<<<<< Set';
                          var start = DateTime.now();
                          _prefs.setValue(_inputKey, _inputValue);
                          var end = DateTime.now();
                          var cost = end.microsecondsSinceEpoch - start.microsecondsSinceEpoch;
                          tip += '\n>>>>> Set';
                          setState(() {
                            _tips.add(tip);
                          });
                        },
                      ),
                      RaisedButton(
                        child: Text('Get'),
                        onPressed: () {
                          var tip = '<<<<< Get';
                          var start = DateTime.now();
                          _output = _prefs.getValue(_inputKey);
                          var end = DateTime.now();
                          var cost = end.microsecondsSinceEpoch - start.microsecondsSinceEpoch;
                          tip += '\n>>>>> Get';
                          setState(() {
                            _tips.add(tip);
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
              ListView.separated(
                itemBuilder: (BuildContext context, int index) {
                  var tip = _tips[_tips.length - 1];
                  return Text(tip);
                },
                separatorBuilder: (BuildContext context, int index) {
                  return Divider(height: 1);
                },
                itemCount: _tips.length,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
