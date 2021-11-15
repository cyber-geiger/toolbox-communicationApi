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

  GeigerCommunicator(this._communicationEndpoint, bool isMaster) {
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
  MessageListener? getListener() {
    return listener;
  }

  int getPort();

  /// Start a plugin of [pluginInformation] by using the stored executable String.
  void startPlugin(PluginInformation pluginInformation);
}
