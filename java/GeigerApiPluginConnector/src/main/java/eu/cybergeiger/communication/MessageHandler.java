package eu.cybergeiger.communication;

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
  private final LocalApi localApi;

  public MessageHandler(Socket s, LocalApi api) {
    this.socket = s;
    this.localApi = api;
  }

  @Override
  public void run() {
    System.out.println("## MessageHandler reached");
    Message msg;
    try (InputStream in = socket.getInputStream()) {
      // read bytes
      byte[] inputData = new byte[4096];
      int numRead;
      ByteArrayOutputStream buffer = new ByteArrayOutputStream();
      while ((numRead = in.read(inputData, 0, inputData.length)) != -1) {
        // shorten to the written data, TODO maybe not needed?
        byte[] convert = Arrays.copyOfRange(inputData, 0, numRead);
        buffer.write(convert);
      }

      ByteArrayInputStream byteArrayInputStream = new ByteArrayInputStream(buffer.toByteArray());
      msg = Message.fromByteArray(byteArrayInputStream);

      PluginInformation pluginInformation = new PluginInformation(null, 0);
      System.out.println("## got message (" + msg + " " + msg.getType() + " " + msg.getAction() + ")");
      localApi.receivedMessage(pluginInformation, msg);
    } catch (IOException ioe) {
      // TODO handle communications error
      //throw new CommunicationException("Communication Error", ioe);
      ioe.printStackTrace();
    }
  }
}
