package eu.cybergeiger.communication;

import eu.cybergeiger.communication.communicator.GeigerServer;
import org.junit.After;
import org.junit.Test;
import org.junit.Before;

import java.io.File;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.nio.file.Files;

import static org.junit.Assert.assertEquals;

public class TestExternalCommunication {
    LocalApi localMaster;
    GeigerServer server;

    @Before
    public void setup() {
        try {
            localMaster = LocalApiFactory.getLocalApi(LocalApi.MASTER, LocalApi.MASTER, Declaration.DO_NOT_SHARE_DATA);
        } catch (DeclarationMismatchException e) {
            e.printStackTrace();
        }
        server = new GeigerServer();
        Thread t = new Thread(new Runnable() {
            @Override
            public void run() {
                try {
                    server.start();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        });
    }

    @After
    public void tearDown() {
        try {
            server.stop();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    @Test
    public void testRegisterPlugin() {
        // TODO get path dynamically
        //String executable = TestExternalCommunication.class.getProtectionDomain().getCodeSource().getLocation().getPath();
        String path = "C:\\Users\\Sacha\\Desktop\\IMVS\\projekte\\GEIGER\\toolbox-communicationApi\\communicationAPI\\src\\test\\resources\\communicationApi.jar";
        ProcessBuilder pb = new ProcessBuilder("java", "-cp", path, "eu.cybergeiger.communication.communicator.GeigerClient");
        try {
            Process p = pb.start();
            // wait for registration
            Thread.sleep(1000);
            // send Ping
            localMaster.sendMessage("plugin1", new Message(LocalApi.MASTER, "plugin1", MessageType.PING, null, new byte[0]));
            // wait for answer
            Thread.sleep(1000);
            // check output
            String line = Files.readAllLines(new File(getClass().getResource("messageOutput.txt").getPath()).toPath()).get(0);
            assertEquals("PONG received", line);
        } catch (IOException e) {
            e.printStackTrace();
        } catch (InterruptedException ie) {
            ie.printStackTrace();
        }
    }
}
