library geiger_api;

import '../../geiger_api.dart';

/// Interface to denote a message filter.
typedef MessageFilter = bool Function(Message msg);

class Listener with PluginListener {
  final GeigerApi api;
  final Object obj = Object();
  Message tmsg;
  Message? msg;
  List<MessageType> responseTypes;

  Listener(this.api, this.tmsg, this.responseTypes) {
    api.registerListener(responseTypes, this);
  }

  @override
  void pluginEvent(GeigerUrl? url, Message msg) {
    if (this.msg == null &&
        tmsg.requestId == msg.requestId &&
        tmsg.targetId == msg.sourceId &&
        tmsg.sourceId == msg.targetId) {
      this.msg = msg;
    }
  }

  void dispose() {
    api.deregisterListener(responseTypes, this);
  }

  Future<Message> waitForResult(int timeout) async {
    var startTime = DateTime.now().millisecondsSinceEpoch;
    while ((msg == null) &&
        ((timeout < 0) ||
            ((DateTime.now().millisecondsSinceEpoch - startTime) < timeout))) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    var message = msg;
    if (message == null) {
      throw CommunicationException('timeout reached while waiting for reply');
    }
    return message;
  }
}

/// A helper class for sending and waiting on [Message]s.
class CommunicationHelper {
  /// Sends [msg] and waits for the first message matching the provided [filter].
  ///
  /// Will communication using the provided [api] and waits maximum [timeout]
  /// milliseconds. Specify `-1` to remove any time limit.
  ///
  /// Throws [CommunicationException] if communication with master fails
  static Future<Message> sendAndWait(GeigerApi api, Message msg,
      {int timeout = 30000,
      List<MessageType> responseTypes = const [
        MessageType.comapiSuccess,
        MessageType.comapiError
      ]}) async {
    var l = Listener(api, msg, responseTypes);
    await api.sendMessage(msg);
    var result = await l.waitForResult(timeout);
    l.dispose();
    return result;
  }
}
