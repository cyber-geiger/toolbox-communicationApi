library geiger_api;

import 'dart:io';

import '../../geiger_api.dart';
import 'communication_exception.dart';
import 'geiger_url.dart';
import 'message.dart';
import 'message_type.dart';
import 'plugin_listener.dart';

/// Interface to denote a message filter.
typedef MessageFilter = bool Function(Message msg);

class Listener with PluginListener {
  final MessageFilter filter;
  final GeigerApi api;
  final Object obj = Object();
  Message? msg;

  Listener(this.api, this.filter);

  Future<void> register() async {
    await api.registerListener(<MessageType>[MessageType.ALL_EVENTS], this);
  }

  @override
  void pluginEvent(GeigerUrl url, Message msg) {
    if (filter(msg)) {
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
      sleep(Duration(milliseconds: 100));
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
  static Future<Message> sendAndWait(
      GeigerApi api, Message msg, MessageFilter filter,
      [int timeout = 10000]) async {
    var l = Listener(api, filter);
    await l.register();
    await api.sendMessage(msg.targetId!, msg);
    var result = l.waitForResult(timeout);
    l.dispose();
    return result;
  }
}
