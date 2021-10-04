import 'dart:io';

import 'GeigerCommunicator.dart';
import 'LocalApi.dart';
import 'Message.dart';
import 'MessageHandler.dart';
import 'PluginInformation.dart';

/// Communicator for Geiger Core.
class GeigerServer extends GeigerCommunicator {
  // TODO find a way to get number of cores
  final ThreadPool executor = ThreadPool(1);
  static final int port = 1234;
  ServerSocket serverSocket;
  final LocalApi localApi;
  Thread server;
  bool shutdown;

  GeigerServer(this.localApi);

  /// Start the [GeigerServer].
  ///
  /// Throws [IOException] if server could not be started
  @override
  void start() {
    // TODO handle shutdown correctly even when JVM close
    shutdown = false;
    server = Thread(() {
      try {
        serverSocket = ServerSocket(port);

        while (!shutdown) {
          final Socket s = serverSocket.accept();
          print('## GEIGER-Server run method reached');
          // This is only for debugging purposes use lambda for production
          //(new MessageHandler(s, localApi)).run();
          executor.execute(() => MessageHandler(s, localApi));
        }
      } on IOException catch (e) {
        // TODO error handling
        print(e);
      }
    });
    server.setName('GeigerServer');
    server.setDaemon(true);
    server.start();
  }

  /// Stop the [GeigerServer].
  ///
  /// Throws [IOException] if server could not be closed
  void stop() {
// TODO server stop
    shutdown = true;
    var s = Socket('127.0.0.1', port);
    s.close();
  }

  @override
  int getPort() {
    return port;
  }

  static int getDefaultPort() {
    return port;
  }

  @override
  void sendMessage(PluginInformation pluginInformation, Message msg) {
    try {
      var s = Socket('127.0.0.1', pluginInformation.getPort());

      OutputStream out = s.asOutputStream();
      ByteArrayOutputStream bos = ByteArrayOutputStream();
      msg.toByteArrayStream(bos);
      out.write(bos.toByteArray());

      out.close();
      //s.close();
    } on IOException catch (e) {
      // TODO if plugin unknown then try to start the plugin and resend message
      print(e);
    }
  }

  @override
  void startPlugin(PluginInformation pluginInformation) {
    // TODO check how this behaves on different operating systems
    // For android the executable should be the classname of the plugin (which usually is also used
    // for intents)
    // It is the responsibility of the plugin to send the correct string/path according to the
    // current operating system
    //Vm.exec(pluginInformation.getExecutable(), null, 0, true);
  }
}
