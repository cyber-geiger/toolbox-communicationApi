package eu.cybergeiger.communication.communicator;

import eu.cybergeiger.communication.Message;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.net.Socket;

public class ClientMessageHandler implements Runnable {

    private final Socket socket;
    //private LocalApi localApi;

    public ClientMessageHandler(Socket s) {
        this.socket = s;
    }

    @Override
    public void run() {
        try (ObjectInputStream in = new ObjectInputStream(socket.getInputStream())) {
            Message m = (Message) in.readObject();
            // TODO which messages are accepted on client side?
            // do these have types? do we write an interface for them?
            // usually it might be specific to the plugin probably, which leads to a generic action that
            // should be defined in the GeigerURL of the message, so there is just a single type
        } catch (IOException ioe) {
            // TODO handle communications error
            //throw new CommunicationException("Communication Error", ioe);
        } catch (ClassNotFoundException cnfe) {
            // TODO handle wrong objects sent
            //throw new CommunicationException("Wrong object type received", cnfe);
        }
    }
}
