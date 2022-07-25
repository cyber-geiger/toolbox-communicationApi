package eu.cybergeiger.api.communication;

import eu.cybergeiger.api.PluginApi;
import eu.cybergeiger.api.message.Message;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketException;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

/**
 * Abstract class to define common methods for GeigerCommunicators.
 */
public class GeigerCommunicator {
  public static final int MASTER_PORT = 12348;

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
          if (e instanceof SocketException &&
            e.getMessage().equals("socket closed"))
            return;
          e.printStackTrace();
        }
      }
    });
    client.setDaemon(true);
    client.start();
  }

  public void sendMessage(int port, Message message) throws IOException {
    try (Socket socket = new Socket("localhost", port)) {
      ByteArrayOutputStream bos = new ByteArrayOutputStream();
      message.toByteArrayStream(bos);
      socket.getOutputStream().write(bos.toByteArray());
      socket.getOutputStream().flush();
    }
  }

  public void close() throws IOException {
    serverSocket.close();
  }
}
