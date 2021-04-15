package eu.cybergeiger.communication.communicator;

import eu.cybergeiger.communication.Message;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import totalcross.net.Socket;

/**
 * Class to handle incoming messages.
 */
public class MessageHandler implements Runnable {
  private Socket socket;
  MessageListener listener;

  public MessageHandler(Socket s, MessageListener listener) {
    this.socket = s;
    this.listener = listener;
  }

  @Override
  public void run() {
    // bytearrayinputstreams
    try (InputStream in = socket.asInputStream()) {
      // TODO deserialization
      ArrayList<byte[]> input = new ArrayList<>();
      for (int i = 0; i < 5; ++i) {
        // read int
        byte[] b = new byte[4];
        int len;
        if (in.read(b, 0, 4) > 0) {
          len = GeigerCommunicator.byteArrayToInt(b);
          input.add(b);
        } else {
          throw new IOException("Could not read message");
        }
        // read value
        byte[] val = new byte[len];
        if (in.read(val, 0, len) > 0) {
          input.add(val);
        } else {
          throw new IOException("Could not read message value");
        }
      }
      Message msg = GeigerCommunicator.byteArrayToMessage(input);
      listener.gotMessage(socket.getPort(), msg);
    } catch (IOException ioe) {
      // TODO handle communications error
      //throw new CommunicationException("Communication Error", ioe);
      ioe.printStackTrace();
    }
  }
}
