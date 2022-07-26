import 'dart:async';

import 'package:geiger_api/geiger_api.dart';

class _ConditionalCompleter<TResult> {
  final bool Function(List<Message>) canComplete;
  final TResult Function(List<Message>) createResult;

  final _completer = Completer<TResult>();

  Future<TResult> get future => _completer.future;

  _ConditionalCompleter(this.canComplete, this.createResult);

  bool complete(List<Message> events) {
    if (!canComplete(events)) return false;
    _completer.complete(createResult(events));
    return true;
  }
}

class MessageCollector implements PluginListener {
  List<Message> messages = [];
  List<_ConditionalCompleter> _completers = [];

  MessageCollector(GeigerApi api) {
    api.registerListener(MessageType.values, this);
  }

  @override
  void pluginEvent(GeigerUrl? url, Message msg) {
    messages.add(msg);
    _completers = _completers
        .where((completer) => !completer.complete(messages))
        .toList();
  }

  Future awaitCount(int count,
      [Duration timeLimit = const Duration(seconds: 5)]) {
    canComplete(List messages) => messages.length >= count;
    if (canComplete(messages)) {
      return Future.value();
    }
    final completer = _ConditionalCompleter(canComplete, (_) => null);
    _completers.add(completer);
    return completer.future.then((value) {
      _completers.remove(completer);
      return value;
    }, onError: (error) {
      _completers.remove(completer);
      throw error;
    }).timeout(timeLimit, onTimeout: () {
      _completers.remove(completer);
      throw TimeoutException(
          'Did not receive enough messages before timeout.', timeLimit);
    });
  }

  Future<Message> awaitMessage(int index,
      [Duration timeLimit = const Duration(seconds: 5)]) async {
    await awaitCount(index + 1, timeLimit);
    return messages[index];
  }
}
