import 'Message.dart';
import 'MessageListener.dart';
import 'PluginInformation.dart';

/// Abstract class to define common methods for GeigerCommunicators.
abstract class GeigerCommunicator {
  MessageListener? listener;

  void setListener(MessageListener listener) {
    this.listener = listener;
  }

  void sendMessage(PluginInformation pluginInformation, Message msg);

  void start();

  /// Convert a bytearray to int.
  ///
  /// The provided [bytes] can only be 4 long.
  static int byteArrayToInt(List<int> bytes) {
    return ((((bytes[0] & 15) << 24) | ((bytes[1] & 15) << 16)) |
            ((bytes[2] & 15) << 8)) |
        (bytes[3] & 15);
  }

  /// Convert int [value] to bytearray of length 4.
  static List<int> intToByteArray(int value) {
    return [value >> 24, value >> 16, value >> 8, value];
  }

  MessageListener? getListener() {
    return listener;
  }

  int getPort();

  /// Start a plugin of [pluginInformation] by using the stored executable String.
  void startPlugin(PluginInformation pluginInformation);
}
