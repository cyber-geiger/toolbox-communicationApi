package eu.cybergeiger.api.communication;

import eu.cybergeiger.api.PluginApi;
import eu.cybergeiger.api.message.Message;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.Socket;
import java.util.Arrays;

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
    try (InputStream in = socket.getInputStream()) {
      byte[] inputData = new byte[4096];
      int numRead;
      ByteArrayOutputStream buffer = new ByteArrayOutputStream();
      while ((numRead = in.read(inputData, 0, inputData.length)) != -1) {
        byte[] convert = Arrays.copyOfRange(inputData, 0, numRead);
        buffer.write(convert);
      }

      ByteArrayInputStream byteArrayInputStream = new ByteArrayInputStream(buffer.toByteArray());
      Message message = Message.fromByteArrayStream(byteArrayInputStream);
      pluginApi.receivedMessage(message);
    } catch (IOException ioe) {
      // TODO handle communications error
      //throw new CommunicationException("Communication Error", ioe);
      ioe.printStackTrace();
    }
  }
}
