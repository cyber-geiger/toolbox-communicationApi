package eu.cybergeiger.communication;

import org.junit.Ignore;
import org.junit.Test;

import java.util.Random;

import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.fail;

/**
 * <p>Testing API calling sequence.</p>
 */
public class TestApiCallSequences {

  @Test
  public void testRegisterSequence() {
    LocalApi masterApi = null;
    LocalApi pluginApi = null;
    try {
      // create core localApi
      masterApi = LocalApiFactory.getLocalApi("/master",
          LocalApi.MASTER, Declaration.DO_NOT_SHARE_DATA);
      // wait for master to be fully operational
      Thread.sleep(1000);
      // create plugin localApi
      pluginApi = LocalApiFactory.getLocalApi("/plugin1",
          "plugin1", Declaration.DO_NOT_SHARE_DATA);
      // this should trigger a register and activate call
    } catch (DeclarationMismatchException | InterruptedException e) {
      e.printStackTrace();
      fail();
    }
    assertNotNull(masterApi);
    assertNotNull(pluginApi);

    // TODO how to check if register worked properly?
    // check corelocalApi plugins map if plugin available and vice versa
    // how to check the map if its private?
  }

  @Test
  @Ignore
  public void testDeRegisterSequence() {
    // create core localApi
    // create plugin localApi
    // should register automatically
    // plugin
    // check corelocalApi plugins map if plugin available and vice versa
    // how to check the map if its private?
    fail("not implemented");
  }

  @Test
  @Ignore
  public void testActivateSequence() {
    // create core localApi
    // create plugin localApi
    // should register automatically and activate automatically
    // check if plugin activated
    fail("not implemented");
  }

  @Test
  @Ignore
  public void testDeactivateSequence() {
    // create core localApi
    // create plugin localApi
    // should register and activate automatically
    // deactivate plugin
    // check if deactivated in core
    fail("not implemented");
  }

  @Test
  @Ignore
  public void testPING() {
    LocalApi masterApi = null;
    LocalApi pluginApi = null;
    try {
      // create core localApi
      masterApi = LocalApiFactory.getLocalApi("/master",
          LocalApi.MASTER, Declaration.DO_NOT_SHARE_DATA);
      // wait for master to be fully operational
      Thread.sleep(1000);
      // create plugin localApi
      pluginApi = LocalApiFactory.getLocalApi("/plugin1",
          "plugin1", Declaration.DO_NOT_SHARE_DATA);
      // this should trigger a register and activate call
    } catch (DeclarationMismatchException | InterruptedException e) {
      e.printStackTrace();
      fail();
    }
    assertNotNull(masterApi);
    assertNotNull(pluginApi);

    // TODO PING payload
    byte[] payload = String.valueOf(new Random().nextInt()).getBytes();
    masterApi.sendMessage("plugin1", new Message(LocalApi.MASTER, "plugin1",
        MessageType.PING, new GeigerUrl("plugin1", ""), payload));

    // TODO check if PONG received
  }
}
