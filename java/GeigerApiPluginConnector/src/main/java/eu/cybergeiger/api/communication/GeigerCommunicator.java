package eu.cybergeiger.api.communication;

import eu.cybergeiger.api.GeigerApi;
import eu.cybergeiger.api.PluginApi;
import eu.cybergeiger.api.message.Message;
import eu.cybergeiger.api.plugin.PluginInformation;

import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketException;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;
import java.util.logging.Level;

/**
 * Abstract class to define common methods for GeigerCommunicators.
 */
public class GeigerCommunicator {
  public static final int MASTER_PORT = 12348;
  static final long RESPONSE_UID = 5643142302L;

  private final PluginApi api;

  private ServerSocket serverSocket;
  private final Executor executor;


  public GeigerCommunicator(PluginApi api) {
    this.api = api;
    this.executor = Executors.newFixedThreadPool(
      Runtime.getRuntime().availableProcessors()
    );
  }

  public boolean isActive() {
    return serverSocket != null;
  }

  public int getPort() {
    if (serverSocket == null)
      return 0;
    return serverSocket.getLocalPort();
  }

  public void start() throws IOException {
    if (isActive()) return;
    serverSocket = new ServerSocket(0);
    Thread client = new Thread(() -> {
      while (true) {
        try {
          executor.execute(new MessageHandler(serverSocket.accept(), api));
        } catch (IOException e) {
          if (e instanceof SocketException)
            return; // If serverSocket was closed. Exit thread.
          GeigerApi.logger.log(Level.WARNING, "Encountered exception while listening for messages.", e);
        }
      }
    });
    client.setDaemon(true);
    client.start();
  }

  public void sendMessage(PluginInformation info, Message message) throws IOException {
    try (Socket socket = new Socket("localhost", info.getPort())) {
      message.toByteArrayStream(socket.getOutputStream(), info.getSecret());
      socket.getOutputStream().flush();

      // TODO: check for response UID
    }
  }

  public void close() throws IOException {
    serverSocket.close();
  }
}
