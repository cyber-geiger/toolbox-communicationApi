package eu.cybergeiger.communication;

import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;

import java.io.OutputStream;
import totalcross.io.IOException;
import totalcross.net.ServerSocket;
import totalcross.net.Socket;
import totalcross.util.concurrent.ThreadPool;

/**
 * Communicator for Geiger-Plugins.
 */
public class GeigerClient extends GeigerCommunicator {
  // TODO find a way to get number of cores/threads available
  private final ThreadPool executor = new ThreadPool(4);
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
        serverSocket = new ServerSocket(0);
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

      OutputStream out = s.asOutputStream();
      ByteArrayOutputStream bos = new ByteArrayOutputStream();
      msg.toByteArrayStream(bos);
      out.write(bos.toByteArray());

      out.close();
      s.close();
    } catch (java.io.IOException e) {
      // TODO if master unknown try to start master and send again
      e.printStackTrace();
    }
  }

  @Override
  public int getPort() {
    return port;
  }

}
