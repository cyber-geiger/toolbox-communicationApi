package eu.cybergeiger.api.communication;

import eu.cybergeiger.api.PluginApi;
import eu.cybergeiger.api.message.Message;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

/**
 * Abstract class to define common methods for GeigerCommunicators.
 */
public class GeigerCommunicator {
  public static final int MASTER_PORT = 12348;

  private final PluginApi api;

  private ServerSocket serverSocket;
  private Thread client;
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

  public void start() {
    if (isActive()) return;
    client = new Thread(() -> {
      try {
        serverSocket = new ServerSocket(0);
        while (true) {
          Socket socket = serverSocket.accept();
          executor.execute(new MessageHandler(socket, api));
        }
      } catch (IOException e) {
        e.printStackTrace();
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
    client.interrupt();
  }
}
