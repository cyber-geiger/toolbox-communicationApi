package eu.cybergeiger.communication.communicator;

import eu.cybergeiger.communication.*;

import javax.naming.NameNotFoundException;
import java.io.*;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.nio.Buffer;
import java.nio.ByteBuffer;

public class MessageHandler implements Runnable {
  private Socket socket;
  private LocalApi localApi;

  public MessageHandler(Socket s) {
    this.socket = s;
  }

  @Override
  public void run() {
    try (ObjectInputStream in = new ObjectInputStream(socket.getInputStream())) {
      Message m = (Message) in.readObject();
      // Since we only expect one message to be sent over the stream, there is no need for a loop here
      parseType(m);
    } catch (IOException ioe) {
      // TODO handle communications error
      //throw new CommunicationException("Communication Error", ioe);
    } catch (ClassNotFoundException cnfe) {
      // TODO handle wrong objects sent
      //throw new CommunicationException("Wrong object type received", cnfe);
    }
  }

  /**
   * parses the message type and relays the message to the corresponding handler
   *
   * @param m the message to be parsed
   */
  private void parseType(Message m) {
    if (null == LocalApiFactory.getLocalApi(m.getTargetId())) {
      // no localapi has been created
      if(LocalApi.MASTER.equals(m.getTargetId())) {
        try {
          localApi = LocalApiFactory.getLocalApi(LocalApi.MASTER, LocalApi.MASTER, Declaration.DO_NOT_SHARE_DATA);
        } catch(DeclarationMismatchException e) {
          e.printStackTrace();
        }
      } else {
        // we must be in a client
        try {
          localApi = LocalApiFactory.getLocalApi(null, m.getTargetId(), Declaration.DO_NOT_SHARE_DATA);
        } catch (DeclarationMismatchException e) {
          e.printStackTrace();
        }
      }
    }

    switch (m.getType()) {
      case REGISTER_PLUGIN: {
        localApi.registerPlugin(m);
        break;
      }
      case DEREGISTER_PLUGIN: {
        try {
        localApi.deregisterPlugin();
        } catch(NameNotFoundException e) {
        // TODO
        e.printStackTrace();
        }
        break;
      }
      case REGISTER_MENU: {
        localApi.registerMenu(m.getPayloadString(), m.getAction());
        break;
      }
      case ACTIVATE_PLUGIN: {
        localApi.activatePlugin();
        //localApi.activatePlugin(ByteBuffer.wrap(m.getPayload()).getInt());
        //localApi.activatePlugin(Integer.parseInt(m.getPayloadString()));
        break;
      }
      case DEACTIVATE_PLUGIN: {
        localApi.deactivatePlugin();
        break;
      }
      case MENU_PRESSED: {
        localApi.menuPressed(m.getAction());
        break;
      }
      case MENU_ACTIVE: {
        localApi.enableMenu(m.getPayloadString());
        break;
      }
      case MENU_INACTIVE: {
        localApi.disableMenu(m.getPayloadString());
        break;
      }
      case DEREGISTER_MENU: {
        localApi.deregisterMenu(m.getPayloadString());
        break;
      }
      case SCAN_PRESSED: {
        localApi.scanButtonPressed();
        break;
      }
      case SCAN_COMPLETED: {
        // TODO
        //localApi.scanComplete();
        break;
      }
      case RETURNING_CONTROL: {
        handleReturningControl(m);
        break;
      }
      case ALL_EVENTS: {
        handleAllEvents();
        break;
      }
      case PING: {
        handlePing(m);
        break;
      }
      case PONG: {
        handlePong();
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

//  /**
//   * Transmits message to plugin listening on port
//   *
//   * @param m    message to transmit
//   * @param port port to connect to on localhost
//   */
//  public void transmit(Message m, int port) {
//    try {
//      InetSocketAddress address = new InetSocketAddress(InetAddress.getLocalHost(), port);
//      Socket s = new Socket();
//      s.bind(address);
//      s.connect(address, 10000);
//      ObjectOutputStream out = new ObjectOutputStream(s.getOutputStream()); // TODO close
//      out.writeObject(m);
//    } catch (IOException ioe) {
//      // TODO
//    }
//  }

  private void handleReturningControl(Message m) {
    // TODO
    throw new UnsupportedOperationException();
  }

  private void handleStorageEvent(Message m) {
    // TODO
    throw new UnsupportedOperationException();
  }
  private void handleAllEvents() {
    // TODO
    throw new UnsupportedOperationException();
  }

  private void handlePing(Message m) {
    // TODO send PONG
    localApi.sendMessage(m.getSourceId(), new Message(m.getTargetId(), m.getSourceId(), MessageType.PONG, null, new byte[0]));
  }

  private void handlePong() {
    // TODO what todo on PONG?
    File messageOutput = new File("messageOutput.txt");
    try (BufferedWriter writer = new BufferedWriter(new FileWriter(messageOutput))) {
      writer.write("PONG received");
    } catch (IOException i) {
      i.printStackTrace();
    }
    System.out.println("PONG received");
  }
}
