package eu.cybergeiger.communication;

import org.junit.Test;

import eu.cybergeiger.communication.server.GeigerServer;

import java.io.IOException;

public class TestLocalApi {
    LocalApi localMaster = LocalApiFactory.getLocalApi("master");
    GeigerServer server;

    @Before
    public void setup() {
        server = new GeigerServer();
        try {
            server.start();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Test
    public void testRegisterPlugin() {
        Message ping = new Message("client", "master", MessageType.PING, );
    }
}
