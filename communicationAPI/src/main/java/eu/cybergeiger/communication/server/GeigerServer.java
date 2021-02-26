package eu.cybergeiger.communication.server;

import java.io.IOException;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class GeigerServer {
    private final ExecutorService executor = Executors.newCachedThreadPool();
    private final int port = 1234;
    private ServerSocket serverSocket;

    public void start() throws IOException {
        // TODO handle shutdown correctly even when JVM close
        serverSocket = new ServerSocket(port);

        while(true) {
            final Socket s = serverSocket.accept();
            executor.execute(() -> new MessageHandler(s));
        }
    }

    public void stop() throws IOException{
        serverSocket.close();
    }
}
