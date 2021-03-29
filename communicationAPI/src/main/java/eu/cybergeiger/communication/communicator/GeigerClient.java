package eu.cybergeiger.communication.communicator;

import eu.cybergeiger.communication.Message;
import eu.cybergeiger.communication.PluginInformation;
import java.io.OutputStream;
import java.util.ArrayList;
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
  int port;
  Thread client;
  Boolean shutdown;

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
          executor.execute(() -> new MessageHandler(s, getListener()));
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
      // ObjectOutputStream ou = new ObjectOutputStream(s.asOutputStream());
      OutputStream out = s.asOutputStream();
      // write all objects in the format: int size, String
      ArrayList<byte[]> messageByte = messageToByteArrays(msg);
      for (byte[] b : messageByte) {
        out.write(b);
      }
      out.close();
      s.close();
    } catch (java.io.IOException e) {
      e.printStackTrace();
    }
  }

  @Override
  public int getPort() {
    return port;
  }

}
