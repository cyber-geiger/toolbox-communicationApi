package eu.cybergeiger.communication;

import eu.cybergeiger.communication.communicator.GeigerServer;
import org.junit.After;
import org.junit.Ignore;
import org.junit.Test;
import org.junit.Before;

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

    @After
    public void tearDown() {
        try {
            server.stop();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Ignore
    @Test
    public void testRegisterPlugin() {
        // TODO
        try {
            GeigerURL testUrl = new GeigerURL("test");
            Message ping = new Message("client", "master", MessageType.PING, testUrl);
        } catch(MalformedURLException e) {
            e.printStackTrace();
        }
    }
}
