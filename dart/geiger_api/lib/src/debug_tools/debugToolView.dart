import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geiger_api/geiger_api.dart';

class DebugToolsView extends StatefulWidget {
  late final MessageLogger logger;
  late final GeigerApi geigerApi;
  const DebugToolsView(this.logger,this.geigerApi);
  @override
  DebugToolsViewState createState() => DebugToolsViewState(logger,geigerApi);
}

class DebugToolsViewState extends State {
  ///Communication api of the app this widget is displayed in
  late final GeigerApi geigerApi;
  late MessageLogger logger;
  DebugToolsViewState(this.logger, this.geigerApi);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: logger.view(),
                ),
                const Flexible(
                  child: LoggerView(),
                  fit: FlexFit.tight,
                )
              ],
            ),
          ),
          Flexible(child: DBTreeView(':', geigerApi))
        ],
      ),
    );
  }
}
