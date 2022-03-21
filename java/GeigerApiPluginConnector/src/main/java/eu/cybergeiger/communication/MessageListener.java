package eu.cybergeiger.communication;

/**
 * Defines a listener for Messages.
 */
public interface MessageListener {
  void gotMessage(int port, Message msg);
}
