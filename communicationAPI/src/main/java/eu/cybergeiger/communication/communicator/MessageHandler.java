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
    Message msg;
    try (InputStream in = socket.asInputStream()) {
      // TODO deserialize
      //msg = Message.fromByteArray(in);
      msg = null;
      listener.gotMessage(socket.getPort(), msg);
    } catch (IOException ioe) {
      // TODO handle communications error
      //throw new CommunicationException("Communication Error", ioe);
      ioe.printStackTrace();
    }
  }
}
