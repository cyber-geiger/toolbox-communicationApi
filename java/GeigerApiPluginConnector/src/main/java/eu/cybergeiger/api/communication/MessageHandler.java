package eu.cybergeiger.api.communication;

import eu.cybergeiger.api.PluginApi;
import eu.cybergeiger.api.message.Message;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.Socket;

/**
 * Class to handle incoming messages.
 */
public class MessageHandler implements Runnable {
  private final Socket socket;
  private final PluginApi pluginApi;

  public MessageHandler(Socket socket, PluginApi api) {
    this.socket = socket;
    this.pluginApi = api;
  }

  @Override
  public void run() {
    try (InputStream input = socket.getInputStream()) {
      byte[] buffer = new byte[4096];
      int bytesRead;
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      while ((bytesRead = input.read(buffer)) != -1)
        out.write(buffer, 0, bytesRead);

      ByteArrayInputStream byteArrayInputStream = new ByteArrayInputStream(out.toByteArray());
      Message message = Message.fromByteArrayStream(byteArrayInputStream);
      pluginApi.receivedMessage(message);
    } catch (IOException e) {
      e.printStackTrace();
    }
  }
}
