package eu.cybergeiger.communication;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

/**
 * Abstract class to define common methods for GeigerCommunicators.
 */
public abstract class GeigerCommunicator {
  private MessageListener listener = null;

  void setListener(MessageListener listener) {
    this.listener = listener;
  }

  public abstract void sendMessage(PluginInformation pluginInformation, Message msg);

  public abstract void start() throws IOException;

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
