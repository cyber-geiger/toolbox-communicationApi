import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class LoggerView extends StatefulWidget {
  const LoggerView({Key? key}) : super(key: key);

  @override
  LoggerViewState createState() => LoggerViewState();
}

class LoggerViewState extends State {
  final ScrollController _firstController =
      ScrollController(initialScrollOffset: 8);

  List<LogRecord> logs = [];
  int logCount = 0;
  String activeLevel = Level.INFO.name;

  void getLoggs(Level warningLevel) {
    Logger.root.level = warningLevel;
    Logger.root.onRecord.listen((event) {
      if (logs.length > 100) {
        logs.removeRange(99, logs.length - 1);
      }
      logs.insert(0, event);
      activeLevel = warningLevel.name;
      setState(() {
        logCount = logs.length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    getLoggs(Level.INFO);
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return Column(
        children: <Widget>[
          Column(
            children: [
              const Center(
                child: Text('Log View'),
              ),
              Center(
                child: Text('Active Log Level: ' + activeLevel),
              ),
            ],
          ),
          Row(
            children: [
              TextButton(
                  onPressed: () => getLoggs(Level.FINEST),
                  child: const Text('All Levels')),
              TextButton(
                  onPressed: () => getLoggs(Level.INFO),
                  child: const Text('Info')),
              TextButton(
                  onPressed: () => getLoggs(Level.WARNING),
                  child: const Text('Warning')),
            ],
          ),
          Expanded(
            child: SizedBox(
                width: constraints.maxWidth,
                // Only one scroll position can be attached to the
                // PrimaryScrollController if using Scrollbars. Providing a
                // unique scroll controller to this scroll view prevents it
                // from attaching to the PrimaryScrollController.
                child: Scrollbar(
                  thumbVisibility: true,
                  controller: _firstController,
                  child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: logCount,
                      itemBuilder: (BuildContext context, int index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('level: ' +
                              logs[index].level.name +
                              '\nLogger: ' +
                              logs[index].loggerName +
                              '\nMessage: ' +
                              logs[index].message),
                        );
                      }),
                )),
          )
        ],
      );
    });
  }
}
