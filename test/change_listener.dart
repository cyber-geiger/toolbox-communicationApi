import 'dart:async';

import 'package:geiger_localstorage/geiger_localstorage.dart';

/// Reflects a full change vent
class ChangeEvent {
  final EventType type;
  final Node? oldNode;
  final Node? newNode;

  ChangeEvent(this.type, this.oldNode, this.newNode);

  @override
  String toString() {
    return 'ChangeEvent{type: $type, oldNode: $oldNode, newNode: $newNode}';
  }
}

class _ConditionalCompleter {
  final bool Function(List<ChangeEvent>) canComplete;
  final List<ChangeEvent> Function(List<ChangeEvent>) createResult;

  final _completer = Completer<List<ChangeEvent>>();

  Future<List<ChangeEvent>> get future => _completer.future;

  _ConditionalCompleter(this.canComplete, this.createResult);

  void complete(List<ChangeEvent> events) {
    if (!canComplete(events)) return;
    _completer.complete(createResult(events));
  }
}

class CollectingListener with StorageListener {
  final List<ChangeEvent> events = [];

  final Set<_ConditionalCompleter> completers = {};

  @override
  Future<void> gotStorageChange(
      EventType event, Node? oldNode, Node? newNode) async {
    events.add(ChangeEvent(event, oldNode, newNode));
    for (final completer in completers) {
      completer.complete(events);
    }
  }

  Future<List<ChangeEvent>> awaitCount(int count,
      [Duration timeLimit = const Duration(seconds: 1000)]) {
    bool canComplete(List events) => events.length >= count;
    List<ChangeEvent> createResult(List<ChangeEvent> events) =>
        List<ChangeEvent>.from(events.getRange(0, count));
    if (canComplete(events)) {
      return Future.value(createResult(events));
    }

    final completer = _ConditionalCompleter(canComplete, createResult);
    completers.add(completer);
    return completer.future.then((value) {
      completers.remove(completer);
      return value;
    }, onError: (error) {
      completers.remove(completer);
      throw error;
    }).timeout(timeLimit, onTimeout: () {
      completers.remove(completer);
      throw TimeoutException(
          'Did not receive enough change events before timeout.', timeLimit);
    });
  }
}
