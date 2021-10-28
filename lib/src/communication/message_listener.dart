library geiger_api;

import 'message.dart';

/// Defines a listener for Messages.
abstract class MessageListener {
  void gotMessage(int port, Message msg);
}
