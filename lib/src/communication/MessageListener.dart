import 'Message.dart';

/// Defines a listener for Messages.
abstract class MessageListener {
  void gotMessage(int port, Message msg);
}
