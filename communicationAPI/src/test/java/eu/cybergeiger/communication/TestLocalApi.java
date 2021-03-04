package eu.cybergeiger.communication;

import org.junit.Test;
import org.junit.Before;
import eu.cybergeiger.communication.server.GeigerServer;

import java.io.IOException;
import java.net.MalformedURLException;

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
        GeigerURL testUrl;
        try {
            testUrl = new GeigerURL("test");
        } catch(MalformedURLException e) {
            e.printStackTrace();
        }

        Message ping = new Message("client", "master", MessageType.PING, testUrl);
    }
}
