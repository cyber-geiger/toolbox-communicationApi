library geiger_api;

import 'dart:async';
import 'dart:io';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:logging/logging.dart';

class GeigerCommunicator {
  static const int masterPort = 12348;
  static const int responseUID = 5643142302;
  static final Logger _logger = Logger('GeigerCommunicator');

  final CommunicationApi api;

  ServerSocket? _server;
  bool dataReceived = false;

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
      _logger.log(Level.INFO, 'Message received');
      await api.receivedMessage(await Message.fromByteArray(bs));

      _logger.log(Level.INFO, 'Sending response bytes');
      var sink = ByteSink();
      SerializerHelper.writeLong(sink, responseUID);
      sink.close();
      var bytes = await sink.bytes;
      socket.add(bytes);
      await socket.flush();
      _logger.log(Level.INFO, 'Response bytes sent');

      socket.destroy();
    });

    _server = server;
  }

  Future<void> close() async {
    await _server?.close();
    _server = null;
  }

  // Sends a message to a target plugin.
  // iOS: If the target gets killed by the OS, onTimeout is called after 20sec if its a register or active plugin event
  // for any other event its a 5sec timeout
  Future<void> sendMessage(
      PluginInformation target, Message message, Function onTimeout) async {
    final socket =
        await Socket.connect(InternetAddress.loopbackIPv4, target.port);

    _logger.log(Level.INFO, 'Sending message');
    ByteSink sink = ByteSink();
    message.toByteArrayStream(sink, target.secret);
    sink.close();
    socket.add(await sink.bytes);
    await socket.flush();

    // On iOS, no error occurs if the other app gets killed,
    // hence we send a UID after every message sent and expect to receive one within 5sec (or 20sec in case of a register / activate plugin)
    _logger.log(Level.INFO, 'Message sent, waiting for response bytes');
    var responseReceived = false;
    var timeout = 5000;
    if (message.type == MessageType.registerPlugin ||
        message.type == MessageType.activatePlugin) {
      timeout = 20000;
    }

    // If not response bytes are received after a certain time, call the on timeout function
    Future.delayed(Duration(milliseconds: timeout), (() {
      if (!responseReceived) {
        onTimeout();
      }
    }));

    final bs = ByteStream(socket);
    SerializerHelper.castTest(
        'Message', responseUID, await SerializerHelper.readLong(bs), 1);
    responseReceived = true;
    socket.destroy();
  }
}
