package eu.cybergeiger.api.message;

/**
 * Defines a listener for Messages.
 */
public interface MessageListener {
  void gotMessage(int port, Message msg);
}
