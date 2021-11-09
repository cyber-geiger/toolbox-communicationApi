library geiger_api;

import 'geiger_api.dart';
import 'message.dart';
import 'message_listener.dart';
import 'plugin_information.dart';

abstract class GeigerCommunicator {
  static const int defaultMasterPort = 12348;

  MessageListener? listener;
  final GeigerApi _communicationEndpoint;
  int port = defaultMasterPort;

  GeigerCommunicator(GeigerApi this._communicationEndpoint, bool isMaster) {
    if (isMaster) {
      // TODO(mgwerder): start communicator wirth port [defaultMasterPort]
    } else {
      // TODO(mgwerder): start communicator with port -1
    }
  }

  void setListener(MessageListener listener) {
    this.listener = listener;
  }

  Future<void> sendMessage(PluginInformation pluginInformation, Message msg);

  void start();

  /// Convert a bytearray to int.
  ///
  /// The provided [bytes] can only be 4 long.
  /// TODO(mgwerder): this is a specialized implementation of the writeIntLong implementatio. Please collapse sensibly
  static int byteArrayToInt(List<int> bytes) {
    return ((((bytes[0] & 15) << 24) | ((bytes[1] & 15) << 16)) |
            ((bytes[2] & 15) << 8)) |
        (bytes[3] & 15);
  }

  /// Convert int [value] to bytearray of length 4.
  /// TODO(mgwerder): this is a specialized implementation of the writeIntLong implementatio. Please collapse sensibly
  /// FIXME(mgwerder); does not work for negative values
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
