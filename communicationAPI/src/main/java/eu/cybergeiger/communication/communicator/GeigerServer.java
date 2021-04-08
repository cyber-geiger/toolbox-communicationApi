package eu.cybergeiger.communication.communicator;

import eu.cybergeiger.communication.Message;
import eu.cybergeiger.communication.PluginInformation;
import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * <p>Communication server for GeigerToolbox Master.</p>
 */
public class GeigerServer extends GeigerCommunicator {
  private final ExecutorService executor = Executors.newCachedThreadPool();
  private static final int port = 1234;
  private ServerSocket serverSocket;

  /**
   * <p>Server starts listening for connections on port.</p>
   *
   * @throws IOException if an I/O error occurs when waiting for connections
   */
  public void start() throws IOException {
    // TODO handle shutdown correctly even when JVM close
    serverSocket = new ServerSocket(port);

    while (true) {
      final Socket s = serverSocket.accept();
      executor.execute(() -> new MessageHandler(s));
    }
  }

  /**
   * <p>The server stops listening for connections on port.</p>
   *
   * @throws IOException if an I/O error occurs on closing
   */
  public void stop() throws IOException {
    serverSocket.close();
  }

  public static int getDefaultPort() {
    return port;
  }

  @Override
  public void sendMessage(PluginInformation pluginInformation, Message msg) {
    // TODO
  }
}
