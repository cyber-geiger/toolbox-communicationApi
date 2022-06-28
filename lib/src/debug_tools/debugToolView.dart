import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geiger_api/geiger_api.dart';
import 'db_tree_view.dart';
import 'message_logger.dart';

class DebugToolsView extends StatefulWidget {
  late final MessageLogger logger;
  late final GeigerApi api;
  DebugToolsView(this.logger,this.api);
  @override
  DebugToolsViewState createState() => DebugToolsViewState(logger,api);
}

class DebugToolsViewState extends State {
  late final GeigerApi api;
  late MessageLogger logger;
  DebugToolsViewState(this.logger, this.api);

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
          Flexible(child: StorageView(':', api))
        ],
      ),
    );
  }
}
