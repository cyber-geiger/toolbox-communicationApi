package eu.cybergeiger.communication;

import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Arrays;

import org.junit.Assert;
import org.junit.Test;

import static org.junit.Assert.*;

/**
 * <p>Testing non local communication.</p>
 */
public class TestExternalCommunication {

  @Test
  public void testPing() throws Exception, DeclarationMismatchException {
    LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER, Declaration.DO_NOT_SHARE_DATA);
    GeigerUrl testUrl = new GeigerUrl("geiger://master/test");
    Message ping = new Message(LocalApi.MASTER, LocalApi.MASTER, MessageType.PING, testUrl, "payload".getBytes(StandardCharsets.UTF_8));
    Message reply = CommunicationHelper.sendAndWait(localMaster, ping,
        (Message msg) -> Arrays.equals(msg.getPayload(), ping.getPayload()) && msg.getType() == MessageType.PONG
    );
    Assert.assertEquals("comparing payloads",
        new String(ping.getPayload(),StandardCharsets.UTF_8), new String(reply.getPayload(),StandardCharsets.UTF_8));
    Assert.assertEquals("checking message type", MessageType.PONG, reply.getType());
    Assert.assertEquals("checking recipient of reply", ping.getSourceId(), reply.getTargetId());
    Assert.assertEquals("checking sender of reply", ping.getTargetId(), reply.getSourceId());
  }

  @Test
  public void testRegisterPlugin() throws Exception, DeclarationMismatchException {
    LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER, Declaration.DO_NOT_SHARE_DATA);
    //MockListener masterListener = new MockListener();
    //localMaster.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, masterListener);
    GeigerUrl testUrl = new GeigerUrl("geiger://master/test");
    PluginInformation info = new PluginInformation("./plugin1", 4321);
    Message request = new Message(LocalApi.MASTER, LocalApi.MASTER, MessageType.REGISTER_PLUGIN, testUrl, info.toByteArray());
    Message reply = CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) -> msg.getType() == MessageType.COMAPI_SUCCESS);
    //ArrayList<Message> receivedEventsMaster = masterListener.getEvents();
    Assert.assertEquals("checking URl", "registerPlugin", reply.getAction().getPath());
    Assert.assertEquals("checking message type", MessageType.COMAPI_SUCCESS, reply.getType());
    Assert.assertEquals("checking recipient of reply", request.getSourceId(), reply.getTargetId());
    Assert.assertEquals("checking sender of reply", request.getTargetId(), reply.getSourceId());
  }

  @Test
  public void testRegisterExternalPlugin() {
    try {
      // create Master
      LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER, Declaration.DO_NOT_SHARE_DATA);
      // create listener
      MockListener masterListener = new MockListener();
      localMaster.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, masterListener);
      Thread.sleep(1000);
      // create plugin, this registers and activates the plugin automatically
      LocalApi plugin = LocalApiFactory.getLocalApi("", "plugin1", Declaration.DO_NOT_SHARE_DATA);
      MockListener pluginListener = new MockListener();
      plugin.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, pluginListener);
      Thread.sleep(1000);
      // check master
      ArrayList<Message> receivedEventsMaster = masterListener.getEvents();
      assertEquals(2, receivedEventsMaster.size());
      Message rcvdMessage = receivedEventsMaster.get(0);
      assertEquals(MessageType.REGISTER_PLUGIN, rcvdMessage.getType());
      assertEquals("plugin1", rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals(LocalApi.MASTER, rcvdMessage.getAction().getPlugin());
      assertEquals("registerPlugin", rcvdMessage.getAction().getPath());

      // check Plugin
      ArrayList<Message> receivedEventsPlugin = pluginListener.getEvents();
      assertEquals(2, receivedEventsPlugin.size());
      rcvdMessage = receivedEventsPlugin.get(0);
      assertEquals(MessageType.COMAPI_SUCCESS, rcvdMessage.getType());
      assertEquals(LocalApi.MASTER, rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals("plugin1", rcvdMessage.getAction().getPlugin());
      assertEquals("registerPlugin", rcvdMessage.getAction().getPath());
    }catch(DeclarationMismatchException | InterruptedException e) {
      fail(e.getMessage());
    }
  }

  @Test
  public void testActivatePlugin() {
    try {
      // create Master
      LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER, Declaration.DO_NOT_SHARE_DATA);
      // create listener
      MockListener masterListener = new MockListener();
      localMaster.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, masterListener);

      // create plugin, this registers and activates the plugin automatically
      LocalApi plugin = LocalApiFactory.getLocalApi("", "plugin1", Declaration.DO_NOT_SHARE_DATA);
      MockListener pluginListener = new MockListener();
      plugin.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, pluginListener);

      // check master
      ArrayList<Message> receivedEventsMaster = masterListener.getEvents();
      assertEquals(2, receivedEventsMaster.size());
      Message rcvdMessage = receivedEventsMaster.get(1);
      assertEquals(MessageType.ACTIVATE_PLUGIN, rcvdMessage.getType());
      assertEquals("plugin1", rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals(LocalApi.MASTER, rcvdMessage.getAction().getPlugin());
      assertEquals("activatePlugin", rcvdMessage.getAction().getPath());

      // check Plugin
      ArrayList<Message> receivedEventsPlugin = pluginListener.getEvents();
      assertEquals(2, receivedEventsPlugin.size());
      rcvdMessage = receivedEventsPlugin.get(1);
      assertEquals(MessageType.COMAPI_SUCCESS, rcvdMessage.getType());
      assertEquals(LocalApi.MASTER, rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals("plugin1", rcvdMessage.getAction().getPlugin());
      assertEquals("activatePlugin", rcvdMessage.getAction().getPath());
    }catch(DeclarationMismatchException e) {
      fail(e.getMessage());
    }
  }

  @Test
  public void testDeactivatePlugin() {
    try {
      // create Master
      LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER, Declaration.DO_NOT_SHARE_DATA);
      // create listener
      MockListener masterListener = new MockListener();
      localMaster.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, masterListener);

      // create plugin, this registers and activates the plugin automatically
      LocalApi plugin = LocalApiFactory.getLocalApi("", "plugin1", Declaration.DO_NOT_SHARE_DATA);
      MockListener pluginListener = new MockListener();
      plugin.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, pluginListener);

      // deregister
      plugin.deregisterPlugin();

      // check master
      ArrayList<Message> receivedEventsMaster = masterListener.getEvents();
      assertEquals(2, receivedEventsMaster.size());
      Message rcvdMessage = receivedEventsMaster.get(1);
      assertEquals(MessageType.ACTIVATE_PLUGIN, rcvdMessage.getType());
      assertEquals("plugin1", rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals(LocalApi.MASTER, rcvdMessage.getAction().getPlugin());
      assertEquals("activatePlugin", rcvdMessage.getAction().getPath());

      // check Plugin
      ArrayList<Message> receivedEventsPlugin = pluginListener.getEvents();
      assertEquals(2, receivedEventsPlugin.size());
      rcvdMessage = receivedEventsPlugin.get(1);
      assertEquals(MessageType.COMAPI_SUCCESS, rcvdMessage.getType());
      assertEquals(LocalApi.MASTER, rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals("plugin1", rcvdMessage.getAction().getPlugin());
      assertEquals("activatePlugin", rcvdMessage.getAction().getPath());
    }catch(DeclarationMismatchException e) {
      fail(e.getMessage());
    }
  }

  @Test
  public void testRegisterListener() {
    fail("not implemented");
  }

  @Test
  public void testRegisterMenu() {
    try {
      // create Master
      LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER, Declaration.DO_NOT_SHARE_DATA);
      // create listener
      MockListener masterListener = new MockListener();
      localMaster.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, masterListener);

      // create plugin, this registers and activates the plugin automatically
      LocalApi plugin = LocalApiFactory.getLocalApi("", "plugin1", Declaration.DO_NOT_SHARE_DATA);
      MockListener pluginListener = new MockListener();
      plugin.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, pluginListener);

      // register Menu
      plugin.registerMenu("testMenu", new GeigerUrl(LocalApi.MASTER, "testMenu"));

      // check master (the first 2 messages should always be registerPlugin and activatePlugin)
      ArrayList<Message> receivedEventsMaster = masterListener.getEvents();
      assertEquals(3, receivedEventsMaster.size());
      Message rcvdMessage = receivedEventsMaster.get(2);
      assertEquals(MessageType.REGISTER_MENU, rcvdMessage.getType());
      assertEquals("plugin1", rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals(LocalApi.MASTER, rcvdMessage.getAction().getPlugin());
      assertEquals("registerMenu", rcvdMessage.getAction().getPath());
      assertEquals(new MenuItem("testMenu", new GeigerUrl(LocalApi.MASTER, "testMenu")),
          MenuItem.fromByteArray(rcvdMessage.getPayload()));

      // check Plugin (the first 2 messages should always be COMAPI_SUCCESS for
      // registerPlugin and activatePlugin)
      ArrayList<Message> receivedEventsPlugin = pluginListener.getEvents();
      assertEquals(3, receivedEventsPlugin.size());
      rcvdMessage = receivedEventsPlugin.get(2);
      assertEquals(MessageType.COMAPI_SUCCESS, rcvdMessage.getType());
      assertEquals(LocalApi.MASTER, rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals("plugin1", rcvdMessage.getAction().getPlugin());
      assertEquals("registerMenu", rcvdMessage.getAction().getPath());
    }catch(DeclarationMismatchException e) {
      fail(e.getMessage());
    }
  }

  @Test
  public void testDisableMenu() {
    try {
      // create Master
      LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER, Declaration.DO_NOT_SHARE_DATA);
      // create listener
      MockListener masterListener = new MockListener();
      localMaster.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, masterListener);

      // create plugin, this registers and activates the plugin automatically
      LocalApi plugin = LocalApiFactory.getLocalApi("", "plugin1", Declaration.DO_NOT_SHARE_DATA);
      MockListener pluginListener = new MockListener();
      plugin.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, pluginListener);

      // register and disable Menu
      plugin.registerMenu("testMenu", new GeigerUrl(LocalApi.MASTER, "testMenu"));
      plugin.disableMenu("testMenu");

      // check master (the first 2 messages should always be registerPlugin and activatePlugin)
      ArrayList<Message> receivedEventsMaster = masterListener.getEvents();
      assertEquals(4, receivedEventsMaster.size());
      Message rcvdMessage = receivedEventsMaster.get(3);
      assertEquals(MessageType.DISABLE_MENU, rcvdMessage.getType());
      assertEquals("plugin1", rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals(LocalApi.MASTER, rcvdMessage.getAction().getPlugin());
      assertEquals("disableMenu", rcvdMessage.getAction().getPath());
      assertEquals("testMenu", new String(rcvdMessage.getPayload()));

      // check Plugin (the first 2 messages should always be COMAPI_SUCCESS for
      // registerPlugin and activatePlugin)
      ArrayList<Message> receivedEventsPlugin = pluginListener.getEvents();
      assertEquals(4, receivedEventsPlugin.size());
      rcvdMessage = receivedEventsPlugin.get(3);
      assertEquals(MessageType.COMAPI_SUCCESS, rcvdMessage.getType());
      assertEquals(LocalApi.MASTER, rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals("plugin1", rcvdMessage.getAction().getPlugin());
      assertEquals("disableMenu", rcvdMessage.getAction().getPath());
    }catch(DeclarationMismatchException e) {
      fail(e.getMessage());
    }
  }

  @Test
  public void testMenuPressed() {
    try {
      // create Master
      LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER, Declaration.DO_NOT_SHARE_DATA);
      // create listener
      MockListener masterListener = new MockListener();
      localMaster.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, masterListener);

      // create plugin, this registers and activates the plugin automatically
      LocalApi plugin = LocalApiFactory.getLocalApi("", "plugin1", Declaration.DO_NOT_SHARE_DATA);
      MockListener pluginListener = new MockListener();
      plugin.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, pluginListener);

      // register and disable Menu
      plugin.registerMenu("testMenu", new GeigerUrl(LocalApi.MASTER, "testMenu"));
      plugin.menuPressed(new GeigerUrl(LocalApi.MASTER, "testMenu"));

      // check master (the first 2 messages should always be registerPlugin and activatePlugin)
      ArrayList<Message> receivedEventsMaster = masterListener.getEvents();
      assertEquals(4, receivedEventsMaster.size());
      Message rcvdMessage = receivedEventsMaster.get(3);
      assertEquals(MessageType.MENU_PRESSED, rcvdMessage.getType());
      assertEquals("plugin1", rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals(LocalApi.MASTER, rcvdMessage.getAction().getPlugin());
      assertEquals("testMenu", rcvdMessage.getAction().getPath());

      fail("not implemented");
    }catch(DeclarationMismatchException e) {
      fail(e.getMessage());
    }
  }

  @Test
  public void registerListener() {
    fail("not implemented");
  }

  @Test
  public void deregisterListener() {
    fail("not implemented");
  }

  @Test
  public void testGetMenuList() {
    fail("not implemented");
  }

  @Test
  public void testScanButtonPressed() {

    fail("not implemented");
  }


}
