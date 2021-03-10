package eu.cybergeiger.communication.communicator;

import eu.cybergeiger.communication.Message;
import eu.cybergeiger.communication.PluginInformation;

public abstract class GeigerCommunicator {
    private MessageListener listener = null;

    void setListener(MessageListener listener) {
        this.listener = listener;
    }

    public abstract void sendMessage(PluginInformation pluginInformation, Message msg);

}
