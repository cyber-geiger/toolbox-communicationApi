// This file is duplicated in client_app and master_app
import 'package:flutter/material.dart';
import 'package:geiger_api/geiger_api.dart';

class MessageLogger implements PluginListener {
  final int bufferSize;
  final Widget Function(Message) toWidget;

  final List<Message> messages = [];
  final List<Widget> messageWidgets = [];

  final Set<Function(Message)> _listeners = {};

  MessageLogger([this.bufferSize = 100, this.toWidget = MessageView.new]);

  void addListener(Function(Message) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(Message) listener) {
    _listeners.remove(listener);
  }

  MessageLogView view({Key? key}) {
    return MessageLogView(this, key: key);
  }

  @override
  void pluginEvent(GeigerUrl? url, Message msg) {
    if (messages.length == bufferSize) {
      messages.removeAt(0);
      messageWidgets.removeAt(0);
    }

    debugPrint(msg.action?.path);

    messages.add(msg);
    messageWidgets.add(toWidget(msg));
    for (final listener in _listeners) {
      listener(msg);
    }
  }
}

class MessageView extends StatefulWidget {
  final Message message;

  const MessageView(this.message, {Key? key}) : super(key: key);

  @override
  State<MessageView> createState() => _MessageViewState();
}

class _MessageViewState extends State<MessageView> {
  void _showDetails() {
    showDialog(
        context: context,
        builder: (_) {
          return Dialog(
              child: Container(
                  padding: const EdgeInsets.only(
                      left: 20, right: 20, bottom: 15, top: 15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Message ${widget.message.type}",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 10),
                      Table(
                        children: [
                          TableRow(children: [
                            const TableCell(child: Text("Source:")),
                            TableCell(child: Text(widget.message.sourceId))
                          ]),
                          TableRow(children: [
                            const TableCell(child: Text("Target:")),
                            TableCell(
                                child:
                                    Text(widget.message.targetId ?? "Unknown"))
                          ]),
                          TableRow(children: [
                            const TableCell(child: Text("Request ID:")),
                            TableCell(child: Text(widget.message.requestId))
                          ]),
                          TableRow(children: [
                            const TableCell(child: Text("Action:")),
                            TableCell(
                                child: Text(widget.message.action?.toString() ??
                                    "None"))
                          ]),
                          TableRow(children: [
                            const TableCell(child: Text("Has payload:")),
                            TableCell(
                                child: Text(widget.message.payload.isEmpty
                                    ? 'No'
                                    : 'Yes'))
                          ]),
                          TableRow(children: [
                            const TableCell(child: Text("Hash:")),
                            TableCell(
                                child: Text(widget.message.hash.toString()))
                          ]),
                        ],
                      )
                    ],
                  )));
        });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: _showDetails,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(
              child: Text.rich(TextSpan(children: [
            TextSpan(
                text: widget.message.sourceId,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const WidgetSpan(child: Icon(Icons.arrow_right_alt)),
            TextSpan(text: " " + widget.message.type.toString())
          ])))
        ]));
  }
}

class MessageLogView extends StatefulWidget {
  final MessageLogger logger;

  const MessageLogView(this.logger, {Key? key}) : super(key: key);

  @override
  State<MessageLogView> createState() => _MessageLogViewState();
}

class _MessageLogViewState extends State<MessageLogView> {
  @override
  void initState() {
    super.initState();
    widget.logger.addListener(_onMessage);
  }

  @override
  void dispose() {
    super.dispose();
    widget.logger.addListener(_onMessage);
  }

  void _onMessage(Message _) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Received messages:'),
        Expanded(
            child: ListView(
          children: widget.logger.messageWidgets.toList(),
        ))
      ],
    );
  }
}
