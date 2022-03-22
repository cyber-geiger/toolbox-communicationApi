package eu.cybergeiger.api.communication;

import eu.cybergeiger.api.CommunicationApi;
import eu.cybergeiger.api.message.Message;
import eu.cybergeiger.api.plugin.PluginInformation;

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
  private final CommunicationApi communicationApi;

  public MessageHandler(Socket s, CommunicationApi api) {
    this.socket = s;
    this.communicationApi = api;
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
      communicationApi.receivedMessage(pluginInformation, msg);
    } catch (IOException ioe) {
      // TODO handle communications error
      //throw new CommunicationException("Communication Error", ioe);
      ioe.printStackTrace();
    }
  }
}
