package eu.cybergeiger.api.communication;

import eu.cybergeiger.api.GeigerApi;
import eu.cybergeiger.api.PluginApi;
import eu.cybergeiger.api.message.Message;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.Socket;
import java.util.logging.Level;

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
    ByteArrayOutputStream out;
    try (InputStream input = socket.getInputStream()) {
      byte[] buffer = new byte[4096];
      int bytesRead;
      out = new ByteArrayOutputStream();
      while ((bytesRead = input.read(buffer)) != -1)
        out.write(buffer, 0, bytesRead);
    } catch (IOException e) {
      GeigerApi.logger.log(Level.WARNING, "Encountered exception while receiving message.", e);
      return;
    }
    Message message;
    try {
      message = Message.fromByteArrayStream(new ByteArrayInputStream(out.toByteArray()));
    } catch (IOException e) {
      GeigerApi.logger.log(Level.WARNING, "Encountered exception while deserializing message.", e);
      return;
    }
    try {
      pluginApi.receivedMessage(message);
    } catch (IOException e) {
      GeigerApi.logger.log(Level.WARNING, "Encountered exception while processing message.", e);
    }
  }
}
