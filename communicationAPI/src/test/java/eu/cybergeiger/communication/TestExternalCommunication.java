package eu.cybergeiger.communication;

import eu.cybergeiger.communication.communicator.GeigerServer;
import java.io.IOException;
import java.net.MalformedURLException;
import org.junit.After;
import org.junit.Before;
import org.junit.Ignore;
import org.junit.Test;

/**
 * <p>Testing non local communication.</p>
 */
public class TestExternalCommunication {
  LocalApi localMaster = LocalApiFactory.getLocalApi("master");
  GeigerServer server;

  /**
   * <p>Start new server listener.</p>
   */
  @Before
  public void setup() {
    server = new GeigerServer();
    try {
      server.start();
    } catch (IOException e) {
      e.printStackTrace();
    }
  }

  /**
   * <p>stop server listener.</p>
   */
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
  public void testPluginCore() {
    // TODO
    // idea create LocalApi for plugin, localApi fore core
    // use plugin.sendMessage Ping

    // systemlistener for Ping?

  }
}
