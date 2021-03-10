package eu.cybergeiger.communication;

import eu.cybergeiger.communication.server.GeigerServer;
import org.junit.Before;
import org.junit.Test;
import java.io.IOException;
import java.net.MalformedURLException;

public class TestExternalCommunication {
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
            Message ping = new Message("client", "master", MessageType.PING, testUrl);
        } catch(MalformedURLException e) {
            e.printStackTrace();

        }

    }
}
