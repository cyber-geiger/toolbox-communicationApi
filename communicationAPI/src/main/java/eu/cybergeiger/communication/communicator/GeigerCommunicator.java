package eu.cybergeiger.communication.communicator;

import eu.cybergeiger.communication.GeigerUrl;
import eu.cybergeiger.communication.Message;
import eu.cybergeiger.communication.MessageType;
import eu.cybergeiger.communication.PluginInformation;
import java.net.MalformedURLException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;

/**
 * Abstract class to define common methods for GeigerCommunicators.
 */
public abstract class GeigerCommunicator {
  private MessageListener listener = null;

  void setListener(MessageListener listener) {
    this.listener = listener;
  }

  public abstract void sendMessage(PluginInformation pluginInformation, Message msg);

  /**
   * Converts a Message into bytearrays the format for each entry is
   * int length string value The order is important for "deserialization".
   * The order is sourceID, TargetID, MessageType, GeigerURl, payload
   *
   * @param msg message to convert to byte array
   * @return ArrayList containing the message as bytearrays
   */
  public static ArrayList<byte[]> messageToByteArrays(Message msg) {
    ArrayList<byte[]> output = new ArrayList<>();
    // sourceId
    output.add(intToByte(msg.getSourceId().length()));
    output.add(msg.getSourceId().getBytes(StandardCharsets.UTF_8));
    //targetId
    output.add(intToByte(msg.getTargetId().length()));
    output.add(msg.getTargetId().getBytes(StandardCharsets.UTF_8));
    //messagetype
    output.add(intToByte(msg.getType().toString().length()));
    output.add(msg.getType().toString().getBytes(StandardCharsets.UTF_8));
    //geigerurl
    output.add(intToByte(msg.getAction().toString().length()));
    output.add(msg.getAction().toString().getBytes(StandardCharsets.UTF_8));
    //payload
    byte[] payload = msg.getPayload();
    output.add(intToByte(payload.length));
    output.add(payload);
    return output;
  }

  /**
   * Creates Message form Arraylist of bytearrays.
   *
   * @param input arraylist of byte arrays containing Message information
   * @return Message
   */
  public static Message byteArrayToMessage(ArrayList<byte[]> input) {
    // SourceId
    String sourceId = new String(input.get(1));
    // TargetId
    String targetId = new String(input.get(3));
    // MessageType
    MessageType msgType = MessageType.valueOf(new String(input.get(5)));
    // GeigerURL
    GeigerUrl url;
    try {
      url = new GeigerUrl(new String(input.get(7)));
    } catch (MalformedURLException e) {
      url = null;
    }
    // assemble message
    return new Message(sourceId, targetId, msgType, url, input.get(9));
  }

  /**
   * Convenience function to convert int to bytearray.
   *
   * @param a int to convert
   * @return bytearray representing the int
   */
  private static byte[] intToByte(int a) {
    String s = String.valueOf(a);
    return s.getBytes(StandardCharsets.UTF_8);
  }

  /**
   * Convert bytearray to int.
   *
   * @param bytes bytearray containing 4 bytes
   * @return int denoting the given bytes
   */
  public static int byteArrayToInt(byte[] bytes) {
    return ((bytes[0] & 0xFF) << 24)
        | ((bytes[1] & 0xFF) << 16)
        | ((bytes[2] & 0xFF) << 8)
        | ((bytes[3] & 0xFF));
  }

  public MessageListener getListener() {
    return listener;
  }

  public abstract int getPort();
}
