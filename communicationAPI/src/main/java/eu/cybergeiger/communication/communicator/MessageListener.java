package eu.cybergeiger.communication.communicator;

import eu.cybergeiger.communication.Message;

public interface MessageListener {
    void gotMessage(int port, Message msg);
}
