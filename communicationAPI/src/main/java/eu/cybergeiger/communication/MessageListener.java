package eu.cybergeiger.communication;

/**
 * Defines a Messagelistener.
 */
public interface MessageListener {
  void gotMessage(int port, Message msg);
}
