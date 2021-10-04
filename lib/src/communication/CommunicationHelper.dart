import 'dart:io';

import 'CommunicationException.dart';
import 'GeigerUrl.dart';
import 'LocalApi.dart';
import 'Message.dart';
import 'MessageType.dart';
import 'PluginListener.dart';

/// Interface to denote a message filter.
abstract class MessageFilter {
  bool filter(Message msg);
}

class Listener with PluginListener {
  final MessageFilter filter;
  final LocalApi api;
  final Object obj = Object();
  Message? msg;

  Listener(this.api, this.filter) {
    api.registerListener([MessageType.ALL_EVENTS], this);
  }

  @override
  void pluginEvent(GeigerUrl url, Message msg) {
    if (filter.filter(msg)) {
      this.msg = msg;
      // synchronized(obj, {
      // obj.notifyAll();
      // });
    }
  }

  void dispose() {
    api.deregisterListener([MessageType.ALL_EVENTS], this);
  }

  Message waitForResult(int timeout) {
    var startTime = DateTime.now().millisecondsSinceEpoch;
    while ((msg == null) &&
        ((timeout < 0) ||
            ((DateTime.now().millisecondsSinceEpoch - startTime) < timeout))) {
      // try {
      /*synchronized(obj, {
          obj.wait(100);
        });*/
      sleep(Duration(milliseconds: 100));
      // } on InterruptedException catch (e) {}
    }
    var message = msg;
    if (message == null) {
      throw CommunicationException('timeout reached');
    }
    return message;
  }
}

/// A helper class for sending and waiting on [Message]s.
/// TODO should this only be used for Testing?
class CommunicationHelper {
  /// Sends [msg] and waits for the first message matching the provided [filter].
  ///
  /// Will communication using the provided [api] and waits maximum [timeout]
  /// milliseconds. Specify `-1` to remove any time limit.
  ///
  /// Throws [CommunicationException] if communication with master fails
  static Message sendAndWait(LocalApi api, Message msg, MessageFilter filter,
      [int timeout = 10000]) {
    var l = Listener(api, filter);
    api.sendMessage(msg.getTargetId()!, msg);
    var result = l.waitForResult(timeout);
    l.dispose();
    return result;
  }
}
