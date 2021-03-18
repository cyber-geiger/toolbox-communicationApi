package eu.cybergeiger.communication.communicator;

import eu.cybergeiger.communication.*;

import java.io.IOException;
import java.io.ObjectOutputStream;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.ByteBuffer;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class GeigerClient extends GeigerCommunicator {
    private static final ExecutorService executor = Executors.newCachedThreadPool();
    private static ServerSocket serverSocket;
    private static int geigerCorePort = GeigerServer.getDefaultPort();
    private static LocalApi localApi;
    private static final CommunicationSecret secret = new CommunicationSecret();
    private static final String id = "plugin1";

    public static void main(String[] args) {
        // TODO handle shutdown correctly even when JVM close
        // if GeigerCorePort is not default, it should be sent as first argument
        if(args.length > 0) {
            geigerCorePort = Integer.parseInt(args[0]);
        }
        try {
            // get available port
            serverSocket = new ServerSocket(0);
            // register at Geiger Core with new port
            // TODO get real IDs from somewhere
            // TODO what is an executor? should it be the executable?
            // this should already register and activate the plugin
            try {
                // TODO define executor
                localApi = LocalApiFactory.getLocalApi(id, id, Declaration.DO_NOT_SHARE_DATA);
            } catch(DeclarationMismatchException d) {
                d.printStackTrace();
            }
            // TODO get executable from somewhere
            String executable = "plugin1";
            PluginInformation pluginInfo = new PluginInformation(executable, serverSocket.getLocalPort(), secret);
            // TODO only register if first time
            localApi.sendMessage(LocalApi.MASTER, new Message(id, LocalApi.MASTER, MessageType.REGISTER_PLUGIN,
                    null, ByteBuffer.allocate(4).putInt(serverSocket.getLocalPort()).array()));
            //localApi.activatePlugin();
//            activateSelf();
            // listening for incoming connections
            while(true) {
                final Socket s = serverSocket.accept();
                executor.execute(() -> new MessageHandler(s));
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }


    private static void activateSelf() {
//        try {
//            // connect to core
//            InetSocketAddress address = new InetSocketAddress(InetAddress.getLocalHost(), geigerCorePort);
//            Socket s = new Socket();
//            s.bind(address);
//            s.connect(address, 10000);
//            ObjectOutputStream out = new ObjectOutputStream(s.getOutputStream()); // TODO close
//
//
//            Message m = new Message("plugin1", "__MASTERPLUGIN__", MessageType.REGISTER_PLUGIN,
//                    new GeigerURL(""),
//                    ByteBuffer.allocate(Integer.BYTES).putInt(serverSocket.getLocalPort()).array());
//            out.writeObject(m);
//            out.close();
//            s.close();
//        } catch (IOException ioe) {
//            // TODO
//            ioe.printStackTrace();
//        }
    }

    public void stop() throws IOException{
        serverSocket.close();
    }

    @Override
    public void sendMessage(PluginInformation pluginInformation, Message msg) {
        try {
            // clients send only to master
            InetSocketAddress address = new InetSocketAddress(InetAddress.getLocalHost(), geigerCorePort);
            Socket s = new Socket();
            s.bind(address);
            s.connect(address, 10000);
            ObjectOutputStream out = new ObjectOutputStream(s.getOutputStream());
            out.writeObject(msg);
            out.close();
            s.close();
        } catch(IOException e) {
            e.printStackTrace();
        }
    }
}
