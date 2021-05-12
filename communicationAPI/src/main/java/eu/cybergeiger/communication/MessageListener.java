package eu.cybergeiger.communication;

import eu.cybergeiger.communication.Message;

/**
 * Defines a Messagelistener.
 */
public interface MessageListener {
  void gotMessage(int port, Message msg);
}
