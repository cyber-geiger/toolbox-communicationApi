package eu.cybergeiger.communication.communicator;

import ch.fhnw.geiger.totalcross.ByteArrayInputStream;
import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;
import eu.cybergeiger.communication.Message;
import java.io.IOException;
import java.io.InputStream;
import java.util.Arrays;

import totalcross.net.Socket;

/**
 * Class to handle incoming messages.
 */
public class MessageHandler implements Runnable {
  private final Socket socket;
  private final MessageListener listener;

  public MessageHandler(Socket s, MessageListener listener) {
    this.socket = s;
    this.listener = listener;
  }

  @Override
  public void run() {
    Message msg;
    try (InputStream in = socket.asInputStream()) {
      // read bytes
      byte[] inputData = new byte[2048];
      int nRead;
      ByteArrayOutputStream buffer = new ByteArrayOutputStream();
      while((nRead = in.read(inputData, 0, inputData.length)) != -1) {
        // shorten to the written data, TODO maybe not needed?
        byte[] convert = Arrays.copyOfRange(inputData, 0, nRead);
        buffer.write(convert);
      }

      ByteArrayInputStream byteArrayInputStream = new ByteArrayInputStream(buffer.toByteArray());
      msg = Message.fromByteArray(byteArrayInputStream);
      listener.gotMessage(socket.getPort(), msg);
    } catch (IOException ioe) {
      // TODO handle communications error
      //throw new CommunicationException("Communication Error", ioe);
      ioe.printStackTrace();
    }
  }
}
