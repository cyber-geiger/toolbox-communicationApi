import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:logging/logging.dart';

class LoggerView extends StatefulWidget{
  @override
  LoggerViewState createState() => LoggerViewState();
}

class LoggerViewState extends State {
  static final Logger _logger = Logger('GeigerStorage');
  final ScrollController _firstController = ScrollController();

  List<LogRecord> logs = [];
  int logCount = 0;

  getLoggs(){
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((event) {
      logs.insert(0, event);
      setState(()  {
        logCount = logs.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    getLoggs();
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Row(
            children: <Widget>[
              SizedBox(
                  width: constraints.maxWidth,
                  // Only one scroll position can be attached to the
                  // PrimaryScrollController if using Scrollbars. Providing a
                  // unique scroll controller to this scroll view prevents it
                  // from attaching to the PrimaryScrollController.
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: _firstController,
                    child: ListView.builder(
                        itemCount: logCount,
                        itemBuilder: (BuildContext context, int index) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text('level: ' + logs[index].level.name + '\nMessage: ' + logs[index].message),
                          );
                        }),
                  )),
            ],
          );
        });
  }
}
