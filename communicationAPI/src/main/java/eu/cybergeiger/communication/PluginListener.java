package eu.cybergeiger.communication;

/**
 * <p>Interface for plugins listening for events.</p>
 */
public interface PluginListener {

  /**
   * <p>Listener for Geiger events.</p>
   *
   * <p>Any plugin must register for such events and </p>
   *
   * @param url the url the message was sent to
   * @param msg the message
   */
  void pluginEvent(GeigerUrl url, Message msg);

  public byte[] toByteArray();
}
