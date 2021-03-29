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
        // TODO get LocalAPI Master
    }

    @After
    public void tearDown() {
        // TODO stop localAPi Master
    }

    @Test
    public void testCommunication() {
        // TODO start plugin
        // TODO check if plugin registered
        // TODO check if plugin activated
        // TODO send PING from Master -> plugin
        // TODO check if PONG received
    }
}
