package eu.cybergeiger.communication.server;

import eu.cybergeiger.communication.Message;

import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.Socket;

public class MessageHandler implements Runnable {
    private Socket socket;

    public MessageHandler(Socket s){
        this.socket = s;
    }

    @Override
    public void run() {
        try (ObjectInputStream in = new ObjectInputStream(socket.getInputStream());
                ObjectOutputStream out = new ObjectOutputStream(socket.getOutputStream())) {
            Message m = (Message) in.readObject();

            // Since we only expect one message to be sent over the stream, there is no need for a loop here
            parseType(m);
        } catch (IOException ioe) {
            // TODO handle communications error
            ioe.printStackTrace();
        } catch (ClassNotFoundException cnfe) {
            // TODO handle wrong objects sent
            cnfe.printStackTrace();
        }
    }

    /**
     * parses the message type and relays the message to the corresponding handler
     * @param m the message to be parsed
     */
    private void parseType(Message m) {
        switch(m.getType()) {
            case REGISTER_PLUGIN: {
                handleRegisterPlugin(m);
                break;
            }
            case DEREGISTER_PLUGIN: {
                handleDeregisterPlugin(m);
                break;
            }
            case REGISTER_MENU: {
                handleRegisterMenu(m);
                break;
            }
            case MENU_PRESSED: {
                handleMenuPressed(m);
                break;
            }
            case DEREGISTER_MENU: {
                handleDeregisterMenu(m);
                break;
            }
            case SCAN_PRESSED: {
                handleScanPressed(m);
                break;
            }
            case RETURNING_CONTROL: {
                handleReturningControl(m);
                break;
            }
            case STORAGE_EVENT: {
                handleStorageEvent(m);
                break;
            }
            default: {
                // TODO throw/send back communication error or Ignore message?
            }
        }
    }

    /**
     * Transmits message to plugin listening on port
     * @param m message to transmit
     * @param port port to connect to on localhost
     */
    public void transmit(Message m, int port) {
        try {
            InetSocketAddress address = new InetSocketAddress(InetAddress.getLocalHost(), port);
            Socket s = new Socket();
            s.bind(address);
            s.connect(address, 10000);
            ObjectOutputStream out = new ObjectOutputStream(s.getOutputStream());
            out.writeObject(m);
        } catch (IOException ioe) {
            // TODO
        }
    }

    private void handleRegisterPlugin(Message m) {
        // TODO
        throw new UnsupportedOperationException();
    }

    private void handleDeregisterPlugin(Message m) {
        // TODO
        throw new UnsupportedOperationException();
    }

    private void  handleRegisterMenu(Message m) {
        // TODO
        throw new UnsupportedOperationException();
    }

    private void handleMenuPressed(Message m) {
        // TODO
        throw new UnsupportedOperationException();
    }

    private void handleDeregisterMenu(Message m) {
        // TODO
        throw new UnsupportedOperationException();
    }

    private void handleScanPressed(Message m) {
        // TODO
        throw new UnsupportedOperationException();
    }

    private void handleReturningControl(Message m) {
        // TODO
        throw new UnsupportedOperationException();
    }

    private void handleStorageEvent(Message m) {
        // TODO
        throw new UnsupportedOperationException();
    }
}
