import 'dart:io';
import 'GeigerCommunicator.dart';
import 'LocalApi.dart';

// TODO: reimplement this without threads

/// Communicator for Geiger-Plugins.
class GeigerClient extends GeigerCommunicator {
  // TODO find a way to get number of cores/threads available
  final ThreadPool executor = ThreadPool(4);
  ServerSocket serverSocket;
  final LocalApi localApi;
  int port;
  Thread client;
  bool shutdown;

  GeigerClient(this.localApi);

  /// Start the GeigerClient.
  ///
  /// @throws IOException if GeigerClient could not be started
  void start() {
    // TODO handle shutdown correctly even when JVM close
    shutdown = false;
    client = Thread(() {
      try {
        serverSocket = ServerSocket(8444);
        port = serverSocket.getLocalPort();
        while (true) {
          final Socket s = serverSocket.accept();
          executor.execute(() => MessageHandler(s, localApi));
        }
      } on IOException catch (e) {
        // TODO exception handling
        e.printStackTrace();
      }
    });
    client.start();
  }

  /// Stop the GeigerClient.
  ///
  /// @throws IOException if client could not be stopped
  void stop() {
    shutdown = true;
    Socket s = Socket("127.0.0.1", port);
    s.close();
  }


  void sendMessage(PluginInformation pluginInformation, Message msg) {
    // Plugin information is ignored as clients only write to master
    try {
      Socket s = Socket("127.0.0.1", GeigerServer.getDefaultPort());

      OutputStream out = s.asOutputStream();
      ByteArrayOutputStream bos = ByteArrayOutputStream();
      msg.toByteArrayStream(bos);
      out.write(bos.toByteArray());

      out.close();
      //s.close();
    } on java.io.IOException catch (e) {
      // TODO if master unknown try to start master and send again
      e.printStackTrace();
    }
  }


  int getPort() {
    return port;
  }


  void startPlugin(PluginInformation pluginInformation) {
    // TODO check how this behaves on different operating systems
    // maybe not needed for clients, unless they need to start the core somehow?
    // For android the executable should be the classname of the plugin (which usually is also used
    // for intents)
    // It is the responsibility of the plugin to send the correct string/path according to the
    // current operating system
    //Vm.exec(pluginInformation.getExecutable(), null, 0, true);
  }

}
