package eu.cybergeiger.communication;

import java.io.IOException;

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

  /**
   * <p>Convert int to bytearray.</p>
   *
   * @param value the int to convert
   * @return bytearray representing the int
   */
  public static byte[] intToByteArray(int value) {
    return new byte[] {
        (byte) (value >>> 24),
        (byte) (value >>> 16),
        (byte) (value >>> 8),
        (byte) value};
  }

  public MessageListener getListener() {
    return listener;
  }

  public abstract int getPort();

  /**
   * <p>Start a plugin by using the stored executable String.</p>
   *
   * @param pluginInformation the Information of the plugin to start
   */
  public abstract void startPlugin(PluginInformation pluginInformation);

}
