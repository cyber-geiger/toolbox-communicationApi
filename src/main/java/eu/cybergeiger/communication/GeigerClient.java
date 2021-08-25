package eu.cybergeiger.communication;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

/**
 * Communicator for Geiger-Plugins.
 */
public class GeigerClient extends GeigerCommunicator {
  // TODO find a way to get number of cores/threads available
  private final Executor executor = Executors.newFixedThreadPool(4);;
  private ServerSocket serverSocket;
  private final LocalApi localApi;
  int port;
  Thread client;
  Boolean shutdown;

  public GeigerClient(LocalApi api) {
    this.localApi = api;
  }

  /**
   * Start the GeigerClient.
   *
   * @throws IOException if GeigerClient could not be started
   */
  public void start() throws IOException {
    // TODO handle shutdown correctly even when JVM close
    shutdown = false;
    client = new Thread(() -> {
      try {
        serverSocket = new ServerSocket(8444);
        port = serverSocket.getLocalPort();
        while (true) {
          final Socket s = serverSocket.accept();
          executor.execute(() -> new MessageHandler(s, localApi));
        }
      } catch (IOException e) {
        // TODO exception handling
        e.printStackTrace();
      }
    });
    client.start();
  }

  /**
   * Stop the GeigerClient.
   *
   * @throws IOException if client could not be stopped
   */
  public void stop() throws IOException {
    shutdown = true;
    Socket s = new Socket("127.0.0.1", port);
    s.close();
  }

  @Override
  public void sendMessage(PluginInformation pluginInformation, Message msg) {
    // Plugin information is ignored as clients only write to master
    try {
      Socket s = new Socket("127.0.0.1", GeigerServer.getDefaultPort());

      OutputStream out = s.getOutputStream();
      ByteArrayOutputStream bos = new ByteArrayOutputStream();
      msg.toByteArrayStream(bos);
      out.write(bos.toByteArray());

      out.close();
      //s.close();
    } catch (java.io.IOException e) {
      // TODO if master unknown try to start master and send again
      e.printStackTrace();
    }
  }

  @Override
  public int getPort() {
    return port;
  }

  @Override
  public void startPlugin(PluginInformation pluginInformation) {
    // TODO check how this behaves on different operating systems
    // maybe not needed for clients, unless they need to start the core somehow?
    // For android the executable should be the classname of the plugin (which usually is also used
    // for intents)
    // It is the responsibility of the plugin to send the correct string/path according to the
    // current operating system
    //Vm.exec(pluginInformation.getExecutable(), null, 0, true);
  }

}
