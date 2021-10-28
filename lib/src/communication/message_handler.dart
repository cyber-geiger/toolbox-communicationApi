library geiger_api;

import 'dart:io';

import 'geiger_api.dart';
import 'message.dart';
import 'plugin_information.dart';

/// Class to handle incoming messages.
class MessageHandler /*implements Runnable*/ {
  final Socket _socket;
  final GeigerApi _localApi;

  MessageHandler(this._socket, this._localApi);

  void run() {
    Message msg;
    try {
      ByteSink in_ = _socket.asInputStream();
      // read bytes
      var inputData = List<int>.filled(4096, 0);
      int numRead;
      ByteArrayOutputStream buffer = ByteArrayOutputStream();
      while ((numRead = in_.read(inputData, 0, inputData.length)) != -1) {
        // shorten to the written data, TODO maybe not needed?
        var convert = inputData.sublist(0, numRead);
        buffer.write(convert);
      }

      ByteArrayInputStream byteArrayInputStream =
          ByteArrayInputStream(buffer.toByteArray());
      msg = Message.fromByteArray(byteArrayInputStream);

      var pluginInformation = PluginInformation(null, 0);
      print('## got message (' +
          msg.toString() +
          ' ' +
          msg.getType().toString() +
          ' ' +
          (msg.getAction()?.toString() ?? 'null') +
          ')');
      _localApi.receivedMessage(pluginInformation, msg);
    } on IOException catch (ioe) {
      // TODO handle communications error
      //throw new CommunicationException("Communication Error", ioe);
      print(ioe);
    }
  }
}
