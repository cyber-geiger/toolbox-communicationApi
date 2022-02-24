library geiger_api;

import 'dart:async';
import 'dart:io';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_api/src/communication/plugin_starter.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

class GeigerCommunicator {
  static const int masterPort = 12348;

  final CommunicationApi api;

  ServerSocket? _server;

  get isActive {
    return _server != null;
  }

  get port {
    return _server?.port ?? 0;
  }

  GeigerCommunicator(this.api);

  Future<void> start() async {
    if (!isActive) {
      var server = await ServerSocket.bind(
          InternetAddress.loopbackIPv4, api.isMaster ? masterPort : 0);
      server.listen((socket) async {
        api.receivedMessage(await Message.fromByteArray(ByteStream(socket)));
      });
      _server = server;
    }
  }

  Future<void> close() async {
    await _server?.close();
    _server = null;
  }

  Future<void> sendMessage(PluginInformation pluginInformation, Message message,
      GeigerApi api) async {
    Socket socket;
    try {
      socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        pluginInformation
            .port, /*sourceAddress: InternetAddress('localhost:$port')*/
      );
    } catch (e) {
      PluginStarter.startPluginInBackground(pluginInformation, api);
      socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        pluginInformation
            .port, /*sourceAddress: InternetAddress('localhost:$port')*/
      );
    }
    ByteSink sink = ByteSink();
    message.toByteArrayStream(sink);
    sink.close();
    socket.add(await sink.bytes);
    await socket.flush();
    socket.destroy();
  }
}
