library geiger_api;

import 'dart:async';
import 'dart:io';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

class GeigerCommunicator {
  static const int masterPort = 12348;

  final CommunicationApi api;

  ServerSocket? _server;
  bool receivedData = false;

  bool get isActive {
    return _server != null;
  }

  int get port {
    return _server?.port ?? 0;
  }

  GeigerCommunicator(this.api);

  Future<void> start() async {
    if (isActive) return;
    final server = await ServerSocket.bind(
        InternetAddress.loopbackIPv4, api.isMaster ? masterPort : 0);
    server.listen((socket) async {
      final bs = ByteStream(socket);
      final bytes = await bs.peekBytes(2);
      print('NUM BYTES: ' + bytes.length.toString());
      if(bytes.length > 1){
        await api.receivedMessage(await Message.fromByteArray(bs));
      }
      socket.add(List.from({1}));
      await socket.flush();
    });

    _server = server;
  }

  Future<void> close() async {
    await _server?.close();
    _server = null;
  }

  Future<void> sendMessage(PluginInformation plugin, Message message) async {
    final socket =
        await Socket.connect(InternetAddress.loopbackIPv4, plugin.port);

    
    var subscription = socket.listen((event) {
      print('DATA RECEIVED :' + event.length.toString());
      receivedData = true;
    });

    ByteSink sink = ByteSink();
    message.toByteArrayStream(sink, plugin.secret);
    sink.close();
    socket.add(await sink.bytes);
    await socket.flush();
    var res = await socket.toList();
    if(res.length > 0){
      print("success");
      receivedData = true;
    }
    await Future.delayed(const Duration(milliseconds: 500));
    socket.destroy();
    if(!receivedData){
      await subscription.cancel();
      throw TimeoutException('Did not respond in time.');
    }
    await subscription.cancel();
  }
}
