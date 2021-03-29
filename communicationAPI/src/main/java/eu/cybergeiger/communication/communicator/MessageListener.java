package eu.cybergeiger.communication.communicator;

import eu.cybergeiger.communication.Message;

/**
 * <p>Interface for message listeners.</p>
 */
public interface MessageListener {

  /**
   * <p>dispatches a message to the specified port on localhost.</p>
   *
   * @param port the port (if <0 contact master port)
   * @param msg  the message to be sent
   */
  void gotMessage(int port, Message msg);
}
