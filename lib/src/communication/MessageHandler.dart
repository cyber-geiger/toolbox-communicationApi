import 'dart:io';

import 'LocalApi.dart';
import 'Message.dart';
import 'PluginInformation.dart';

/// Class to handle incoming messages.
class MessageHandler /*implements Runnable*/ {
  final Socket socket;
  final LocalApi localApi;

  MessageHandler(this.socket, this.localApi);

  void run() {
    Message msg;
    try {
      InputStream in_ = socket.asInputStream();
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
      print('## got message (' + msg.toString() + ')');
      localApi.receivedMessage(pluginInformation, msg);
    } on IOException catch (ioe) {
      // TODO handle communications error
      //throw new CommunicationException("Communication Error", ioe);
      print(ioe);
    }
  }
}
