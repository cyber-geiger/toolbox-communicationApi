package eu.cybergeiger.communication.communicator;

import eu.cybergeiger.communication.GeigerUrl;
import eu.cybergeiger.communication.Message;
import eu.cybergeiger.communication.MessageType;
import eu.cybergeiger.communication.PluginInformation;
import java.io.IOException;
import java.io.ObjectOutputStream;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.ByteBuffer;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 *  <p>Communicator client to be used by GEIGER plugins.</p>
 */
public class GeigerClient extends GeigerCommunicator {
  private static final ExecutorService executor = Executors.newCachedThreadPool();
  private static ServerSocket serverSocket;
  private static int geigerCorePort = GeigerServer.getDefaultPort();

  /**
   * <p>Starts the serversocket to listen for connections after registering itself at MASTER.</p>
   *
   * @param args the first arg is the GEIGER toolboxcore port if it is different from default.
   */
  public static void main(String[] args) {
    // TODO handle shutdown correctly even when JVM close
    // if GeigerCorePort is not default, it should be sent as first argument
    if (args.length > 0) {
      geigerCorePort = Integer.parseInt(args[0]);
    }
    try {
      // get available port
      serverSocket = new ServerSocket(0);
      // register at Geiger Core with new port
      registerSelf();
      // listening for incoming connections
      while (true) {
        final Socket s = serverSocket.accept();
        executor.execute(() -> new MessageHandler(s));
      }
    } catch (IOException e) {
      e.printStackTrace();
    }
  }


  private static void registerSelf() {
    try {
      // connect to core
      InetSocketAddress address = new InetSocketAddress(InetAddress.getLocalHost(), geigerCorePort);
      Socket s = new Socket();
      s.bind(address);
      s.connect(address, 10000);
      ObjectOutputStream out = new ObjectOutputStream(s.getOutputStream()); // TODO close
      // TODO get real IDs from somewhere
      // this sends the current listening port as payload
      Message m = new Message("plugin1", "masterID", MessageType.REGISTER_PLUGIN,
          new GeigerUrl(""),
          ByteBuffer.allocate(Integer.BYTES).putInt(serverSocket.getLocalPort()).array());
      out.writeObject(m);
      out.close();
      s.close();
    } catch (IOException ioe) {
      // TODO
      ioe.printStackTrace();
    }
  }

  public void stop() throws IOException {
    serverSocket.close();
  }

  @Override
  public void sendMessage(PluginInformation pluginInformation, Message msg) {
    // TODO
  }
}
