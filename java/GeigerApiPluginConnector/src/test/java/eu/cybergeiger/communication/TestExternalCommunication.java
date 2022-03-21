package eu.cybergeiger.communication;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.fail;

import ch.fhnw.geiger.localstorage.StorageException;
import java.util.List;

import mocks.SimpleEventListener;
import org.junit.Ignore;
import org.junit.Test;

/**
 * <p>Testing non local communication.</p>
 */
public class TestExternalCommunication {

  @Test
  public void testRegisterExternalPlugin() throws StorageException {
    try {
      // create Master
      LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER,
          Declaration.DO_NOT_SHARE_DATA);
      // create listener
      SimpleEventListener masterListener = new SimpleEventListener();
      localMaster.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, masterListener);
      //Thread.sleep(1000);

      // create plugin, this registers and activates the plugin automatically
      LocalApi plugin = LocalApiFactory.getLocalApi("", "plugin1",
          Declaration.DO_NOT_SHARE_DATA);
      //SimpleEventListener pluginListener = new SimpleEventListener();
      //plugin.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, pluginListener);
      //Thread.sleep(1000);

      // check master
      List<Message> receivedEventsMaster = masterListener.getEvents();
      assertEquals("checking if register and activate events have been received",
          2, receivedEventsMaster.size());
      Message rcvdMessage = receivedEventsMaster.get(0);
      assertEquals(MessageType.REGISTER_PLUGIN, rcvdMessage.getType());
      assertEquals("plugin1", rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals(LocalApi.MASTER, rcvdMessage.getAction().getPlugin());
      assertEquals("registerPlugin", rcvdMessage.getAction().getPath());

      // check Plugin
      //ArrayList<Message> receivedEventsPlugin = pluginListener.getEvents();
      //assertEquals(2, receivedEventsPlugin.size());
      //rcvdMessage = receivedEventsPlugin.get(0);
      //assertEquals(MessageType.COMAPI_SUCCESS, rcvdMessage.getType());
      //assertEquals(LocalApi.MASTER, rcvdMessage.getSourceId());
      //assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      //assertEquals("plugin1", rcvdMessage.getAction().getPlugin());
      //assertEquals("registerPlugin", rcvdMessage.getAction().getPath());
    } catch (DeclarationMismatchException e) {
      fail(e.getMessage());
    }
  }

  @Test
  public void testActivatePlugin() throws StorageException {
    try {
      // create Master
      LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER,
          Declaration.DO_NOT_SHARE_DATA);
      // create listener
      SimpleEventListener masterListener = new SimpleEventListener();
      localMaster.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, masterListener);

      // create plugin, this registers and activates the plugin automatically
      LocalApi plugin = LocalApiFactory.getLocalApi("", "plugin1",
          Declaration.DO_NOT_SHARE_DATA);
      SimpleEventListener pluginListener = new SimpleEventListener();
      plugin.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, pluginListener);

      // check master
      List<Message> receivedEventsMaster = masterListener.getEvents();
      assertEquals(2, receivedEventsMaster.size());
      Message rcvdMessage = receivedEventsMaster.get(1);
      assertEquals(MessageType.ACTIVATE_PLUGIN, rcvdMessage.getType());
      assertEquals("plugin1", rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals(LocalApi.MASTER, rcvdMessage.getAction().getPlugin());
      assertEquals("activatePlugin", rcvdMessage.getAction().getPath());

      // check Plugin
      List<Message> receivedEventsPlugin = pluginListener.getEvents();
      assertEquals(2, receivedEventsPlugin.size());
      rcvdMessage = receivedEventsPlugin.get(1);
      assertEquals(MessageType.COMAPI_SUCCESS, rcvdMessage.getType());
      assertEquals(LocalApi.MASTER, rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals("plugin1", rcvdMessage.getAction().getPlugin());
      assertEquals("activatePlugin", rcvdMessage.getAction().getPath());
    } catch (DeclarationMismatchException e) {
      fail(e.getMessage());
    }
  }

  @Test
  public void testDeactivatePlugin() throws Exception {
    try {
      // create Master
      LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER,
          Declaration.DO_NOT_SHARE_DATA);
      // create listener
      SimpleEventListener masterListener = new SimpleEventListener();
      localMaster.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, masterListener);

      // create plugin, this registers and activates the plugin automatically
      LocalApi plugin = LocalApiFactory.getLocalApi("", "plugin1",
          Declaration.DO_NOT_SHARE_DATA);
      SimpleEventListener pluginListener = new SimpleEventListener();
      plugin.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, pluginListener);

      // deregister
      plugin.deregisterPlugin();

      // check master
      List<Message> receivedEventsMaster = masterListener.getEvents();
      assertEquals(2, receivedEventsMaster.size());
      Message rcvdMessage = receivedEventsMaster.get(1);
      assertEquals(MessageType.ACTIVATE_PLUGIN, rcvdMessage.getType());
      assertEquals("plugin1", rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals(LocalApi.MASTER, rcvdMessage.getAction().getPlugin());
      assertEquals("activatePlugin", rcvdMessage.getAction().getPath());

      // check Plugin
      List<Message> receivedEventsPlugin = pluginListener.getEvents();
      assertEquals(2, receivedEventsPlugin.size());
      rcvdMessage = receivedEventsPlugin.get(1);
      assertEquals(MessageType.COMAPI_SUCCESS, rcvdMessage.getType());
      assertEquals(LocalApi.MASTER, rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals("plugin1", rcvdMessage.getAction().getPlugin());
      assertEquals("activatePlugin", rcvdMessage.getAction().getPath());
    } catch (DeclarationMismatchException e) {
      fail(e.getMessage());
    }
  }

  @Test
  public void testRegisterMenu() throws Exception {
    try {
      // create Master
      LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER,
          Declaration.DO_NOT_SHARE_DATA);
      // create listener
      SimpleEventListener masterListener = new SimpleEventListener();
      localMaster.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, masterListener);

      // create plugin, this registers and activates the plugin automatically
      LocalApi plugin = LocalApiFactory.getLocalApi("", "plugin1",
          Declaration.DO_NOT_SHARE_DATA);
      SimpleEventListener pluginListener = new SimpleEventListener();
      plugin.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, pluginListener);

      // register Menu
      plugin.registerMenu("testMenu", new GeigerUrl(LocalApi.MASTER, "testMenu"));

      // check master (the first 2 messages should always be registerPlugin and activatePlugin)
      List<Message> receivedEventsMaster = masterListener.getEvents();
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
      List<Message> receivedEventsPlugin = pluginListener.getEvents();
      assertEquals(3, receivedEventsPlugin.size());
      rcvdMessage = receivedEventsPlugin.get(2);
      assertEquals(MessageType.COMAPI_SUCCESS, rcvdMessage.getType());
      assertEquals(LocalApi.MASTER, rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals("plugin1", rcvdMessage.getAction().getPlugin());
      assertEquals("registerMenu", rcvdMessage.getAction().getPath());
    } catch (DeclarationMismatchException e) {
      fail(e.getMessage());
    }
  }

  @Test
  public void testDisableMenu() throws Exception {
    try {
      // create Master
      LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER,
          Declaration.DO_NOT_SHARE_DATA);
      // create listener
      SimpleEventListener masterListener = new SimpleEventListener();
      localMaster.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, masterListener);

      // create plugin, this registers and activates the plugin automatically
      LocalApi plugin = LocalApiFactory.getLocalApi("", "plugin1",
          Declaration.DO_NOT_SHARE_DATA);
      SimpleEventListener pluginListener = new SimpleEventListener();
      plugin.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, pluginListener);

      // register and disable Menu
      plugin.registerMenu("testMenu", new GeigerUrl(LocalApi.MASTER, "testMenu"));
      plugin.disableMenu("testMenu");

      // check master (the first 2 messages should always be registerPlugin and activatePlugin)
      List<Message> receivedEventsMaster = masterListener.getEvents();
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
      List<Message> receivedEventsPlugin = pluginListener.getEvents();
      assertEquals(4, receivedEventsPlugin.size());
      rcvdMessage = receivedEventsPlugin.get(3);
      assertEquals(MessageType.COMAPI_SUCCESS, rcvdMessage.getType());
      assertEquals(LocalApi.MASTER, rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals("plugin1", rcvdMessage.getAction().getPlugin());
      assertEquals("disableMenu", rcvdMessage.getAction().getPath());
    } catch (DeclarationMismatchException e) {
      fail(e.getMessage());
    }
  }

  @Test
  public void testMenuPressed() throws Exception {
    try {
      // create Master
      LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER,
          Declaration.DO_NOT_SHARE_DATA);
      // create listener
      SimpleEventListener masterListener = new SimpleEventListener();
      localMaster.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, masterListener);

      // create plugin, this registers and activates the plugin automatically
      LocalApi plugin = LocalApiFactory.getLocalApi("", "plugin1", Declaration.DO_NOT_SHARE_DATA);
      SimpleEventListener pluginListener = new SimpleEventListener();
      plugin.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, pluginListener);

      // register and disable Menu
      plugin.registerMenu("testMenu", new GeigerUrl(LocalApi.MASTER, "testMenu"));
      plugin.menuPressed(new GeigerUrl(LocalApi.MASTER, "testMenu"));

      // check master (the first 2 messages should always be registerPlugin and activatePlugin)
      List<Message> receivedEventsMaster = masterListener.getEvents();
      assertEquals(4, receivedEventsMaster.size());
      Message rcvdMessage = receivedEventsMaster.get(3);
      assertEquals(MessageType.MENU_PRESSED, rcvdMessage.getType());
      assertEquals("plugin1", rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals(LocalApi.MASTER, rcvdMessage.getAction().getPlugin());
      assertEquals("testMenu", rcvdMessage.getAction().getPath());

      fail("not implemented");
    } catch (DeclarationMismatchException e) {
      fail(e.getMessage());
    }
  }

  @Test
  @Ignore
  public void testRegisterListener() {
    fail("not implemented");
  }

  @Test
  @Ignore
  public void testDeregisterListener() {
    fail("not implemented");
  }

  @Test
  @Ignore
  public void testGetMenuList() {
    fail("not implemented");
  }

  @Test
  @Ignore
  public void testScanButtonPressed() {

    fail("not implemented");
  }
}
