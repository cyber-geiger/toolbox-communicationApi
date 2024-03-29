package eu.cybergeiger.api.plugin;

import eu.cybergeiger.api.message.GeigerUrl;
import eu.cybergeiger.api.message.Message;

/**
 * <p>Interface for plugins listening for events.</p>
 */
public interface PluginListener {
  /**
   * <p>Listener for Geiger events.</p>
   *
   * <p>Any plugin must register for such events and </p>
   *
   * @param msg the message
   */
  void pluginEvent(Message msg);
}
