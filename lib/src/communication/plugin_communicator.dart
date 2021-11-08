library geiger_api;

import 'package:communicationapi/src/communication/geiger_api.dart';
import 'package:communicationapi/src/communication/geiger_communicator.dart';
import 'package:communicationapi/src/communication/message.dart';
import 'package:communicationapi/src/communication/plugin_information.dart';

class PluginCommunicator extends GeigerCommunicator {
  PluginCommunicator(GeigerApi comm, bool isMaster) : super(comm, isMaster) {}

  @override
  int getPort() {
    // TODO(mgwerder): implement getPort
    throw UnimplementedError();
  }

  @override
  Future<void> sendMessage(PluginInformation pluginInformation, Message msg) {
    // TODO(mgwerder): implement sendMessage
    throw UnimplementedError();
  }

  @override
  void start() {
    // TODO(mgwerder): implement start
    throw UnimplementedError();
  }

  @override
  void startPlugin(PluginInformation pluginInformation) {
    // TODO(mgwerder): implement startPlugin
    throw UnimplementedError();
  }
}
