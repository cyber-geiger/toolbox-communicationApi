package eu.cybergeiger.communication.communicator;

import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;
import eu.cybergeiger.communication.Message;
import eu.cybergeiger.communication.PluginInformation;
import java.io.IOException;
import java.io.OutputStream;
import totalcross.net.ServerSocket;
import totalcross.net.Socket;
import totalcross.util.concurrent.ThreadPool;

/**
 * Communicator for Geiger Core.
 */
public class GeigerServer extends GeigerCommunicator {
  // TODO find a way to get number of cores
  private final ThreadPool executor = new ThreadPool(1);
  private static final int port = 1234;
  private ServerSocket serverSocket;
  Thread server;
  Boolean shutdown;

  /**
   * Start the GeigerServer.
   *
   * @throws IOException if server could not be started
   */
  public void start() throws IOException {
    // TODO handle shutdown correctly even when JVM close
    shutdown = false;
    server = new Thread(() -> {
      try {
        serverSocket = new ServerSocket(port);

        while (!shutdown) {
          final Socket s = serverSocket.accept();
          executor.execute(() -> new MessageHandler(s, getListener()));
        }
      } catch (IOException e) {
        // TODO
        e.printStackTrace();
      }
    });
    server.start();
  }

  /**
   * Stop the Geigerserver.
   *
   * @throws IOException if server could not be closed
   */
  public void stop() throws IOException {
    // TODO server stop
    shutdown = true;
    Socket s = new Socket("127.0.0.1", port);
    s.close();
  }

  @Override
  public int getPort() {
    return port;
  }

  public static int getDefaultPort() {
    return port;
  }

  @Override
  public void sendMessage(PluginInformation pluginInformation, Message msg) {
    try {
      Socket s = new Socket("127.0.0.1", pluginInformation.getPort());
      OutputStream out = s.asOutputStream();
      ByteArrayOutputStream bos = new ByteArrayOutputStream();
      msg.toByteArrayStream(bos);
      out.write(bos.toByteArray());
      // TODO maybe an easier way if conversion allows for this
      //ByteArrayOutputStream out = s.asOutputStream();
      //msg.toByteArrayStream(out);
      out.close();
      s.close();
    } catch (IOException e) {
      // TODO if host unknown then try to start the host and resend message
      e.printStackTrace();
    }
  }
}
