library geiger_api;

import 'dart:io';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

import 'communication_api.dart';
import 'message.dart';

class GeigerCommunicator {
  static const int masterPort = 12348;

  final CommunicationApi api;

  late ServerSocket? _server;

  get isActive {
    return _server != null;
  }

  get port {
    return _server?.port ?? 0;
  }

  GeigerCommunicator(this.api);

  Future<void> start() async {
    var server = await ServerSocket.bind(
        InternetAddress.loopbackIPv4, api.isMaster ? masterPort : 0);
    server.listen((socket) async {
      api.receivedMessage(await Message.fromByteArray(ByteStream(socket)));
    });
    _server = server;
  }

  Future<void> close() async {
    await _server?.close();
    _server = null;
  }

  Future<void> sendMessage(int port, Message message) async {
    if (_server == null) {
      throw CommunicationException('GeigerCommunicator not started.');
    }
    var socketFuture = Socket.connect(
      InternetAddress.loopbackIPv4,
      port, /*sourceAddress: InternetAddress('localhost:$port')*/
    );
    ByteSink sink = ByteSink();
    message.toByteArrayStream(sink);
    sink.close();
    var socket = await socketFuture;
    socket.add(await sink.bytes);
    await socket.flush();
    socket.destroy();
  }
}
