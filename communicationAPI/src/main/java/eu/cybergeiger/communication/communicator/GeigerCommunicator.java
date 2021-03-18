package eu.cybergeiger.communication.communicator;

import eu.cybergeiger.communication.Message;
import eu.cybergeiger.communication.PluginInformation;

/**
 * <p>Defines the basics for a GEIGER communicator.</p>
 */
public abstract class GeigerCommunicator {
  private MessageListener listener = null;

  void setListener(MessageListener listener) {
    this.listener = listener;
  }

  public abstract void sendMessage(PluginInformation pluginInformation, Message msg);

}
