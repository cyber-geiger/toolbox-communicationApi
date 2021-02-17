package eu.cybergeiger.communication;

public interface PluginListener {

  /**
   * <p>Listener for Geiger events.</p>
   *
   * <p>Any plugin must register for such events and </p>
   *
   * @param url
   * @param msg
   */
  void pluginEvent(GeigerURL url, Message msg);

}
