import 'dart:io';

import 'CommunicationException.dart';
import 'GeigerUrl.dart';
import 'LocalApi.dart';
import 'Message.dart';
import 'MessageType.dart';
import 'PluginListener.dart';

/// Interface to denote a MessageFilter.
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

/// A helper class for sending and waiting on Messages.
/// TODO should this only be used for Testing?
class CommunicationHelper {
  /// <p>Sends a message and waits for the first message matching the provided message filter.</p>
  /// @param api     the API to be used as communication endpoint
  /// @param msg     the message to be sent
  /// @param filter  the filter matching the expected reply
  /// @param timeout the timeout in milliseconds (-1 for infinite)
  /// @return the response Message
  /// @throws CommunicationException if communication with master fails
  static Message sendAndWait(LocalApi api, Message msg, MessageFilter filter,
      [int timeout = 10000]) {
    var l = Listener(api, filter);
    api.sendMessage(msg.getTargetId()!, msg);
    var result = l.waitForResult(timeout);
    l.dispose();
    return result;
  }
}
