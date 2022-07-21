package eu.cybergeiger.api;

import eu.cybergeiger.api.exceptions.DeclarationMismatchException;
import eu.cybergeiger.api.plugin.Declaration;
import org.junit.jupiter.api.Test;

import java.io.IOException;

/**
 * <p>Testing non local communication.</p>
 */
public class TestExternalCommunication extends DartTest {
  @Test
  public void testRegisterExternalPlugin() throws IOException, DeclarationMismatchException {
    CommunicationApiFactory.getLocalApi(
      "",
      "plugin",
      Declaration.DO_NOT_SHARE_DATA
    );
  }

  @Test
  public void testActivatePlugin() throws IOException {
    try {
      // create Master
      PluginApi localMaster = CommunicationApiFactory.getLocalApi("", GeigerApi.MASTER_ID,
        Declaration.DO_NOT_SHARE_DATA);
      // create listener
      SimpleEventListener masterListener = new SimpleEventListener();
      localMaster.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, masterListener);

      // create plugin, this registers and activates the plugin automatically
      PluginApi plugin = CommunicationApiFactory.getLocalApi("", "plugin1",
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
      assertEquals(GeigerApi.MASTER_ID, rcvdMessage.getAction().getPlugin());
      assertEquals("activatePlugin", rcvdMessage.getAction().getPath());

      // check Plugin
      List<Message> receivedEventsPlugin = pluginListener.getEvents();
      assertEquals(2, receivedEventsPlugin.size());
      rcvdMessage = receivedEventsPlugin.get(1);
      assertEquals(MessageType.COMAPI_SUCCESS, rcvdMessage.getType());
      assertEquals(GeigerApi.MASTER_ID, rcvdMessage.getSourceId());
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
      PluginApi localMaster = CommunicationApiFactory.getLocalApi("", GeigerApi.MASTER_ID,
        Declaration.DO_NOT_SHARE_DATA);
      // create listener
      SimpleEventListener masterListener = new SimpleEventListener();
      localMaster.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, masterListener);

      // create plugin, this registers and activates the plugin automatically
      PluginApi plugin = CommunicationApiFactory.getLocalApi("", "plugin1",
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
      assertEquals(GeigerApi.MASTER_ID, rcvdMessage.getAction().getPlugin());
      assertEquals("activatePlugin", rcvdMessage.getAction().getPath());

      // check Plugin
      List<Message> receivedEventsPlugin = pluginListener.getEvents();
      assertEquals(2, receivedEventsPlugin.size());
      rcvdMessage = receivedEventsPlugin.get(1);
      assertEquals(MessageType.COMAPI_SUCCESS, rcvdMessage.getType());
      assertEquals(GeigerApi.MASTER_ID, rcvdMessage.getSourceId());
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
      PluginApi localMaster = CommunicationApiFactory.getLocalApi("", GeigerApi.MASTER_ID,
        Declaration.DO_NOT_SHARE_DATA);
      // create listener
      SimpleEventListener masterListener = new SimpleEventListener();
      localMaster.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, masterListener);

      // create plugin, this registers and activates the plugin automatically
      PluginApi plugin = CommunicationApiFactory.getLocalApi("", "plugin1",
        Declaration.DO_NOT_SHARE_DATA);
      SimpleEventListener pluginListener = new SimpleEventListener();
      plugin.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, pluginListener);

      // register Menu
      plugin.registerMenu("testMenu", new GeigerUrl(GeigerApi.MASTER_ID, "testMenu"));

      // check master (the first 2 messages should always be registerPlugin and activatePlugin)
      List<Message> receivedEventsMaster = masterListener.getEvents();
      assertEquals(3, receivedEventsMaster.size());
      Message rcvdMessage = receivedEventsMaster.get(2);
      assertEquals(MessageType.REGISTER_MENU, rcvdMessage.getType());
      assertEquals("plugin1", rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals(GeigerApi.MASTER_ID, rcvdMessage.getAction().getPlugin());
      assertEquals("registerMenu", rcvdMessage.getAction().getPath());
      assertEquals(new MenuItem("testMenu", new GeigerUrl(GeigerApi.MASTER_ID, "testMenu")),
        MenuItem.fromByteArray(rcvdMessage.getPayload()));

      // check Plugin (the first 2 messages should always be COMAPI_SUCCESS for
      // registerPlugin and activatePlugin)
      List<Message> receivedEventsPlugin = pluginListener.getEvents();
      assertEquals(3, receivedEventsPlugin.size());
      rcvdMessage = receivedEventsPlugin.get(2);
      assertEquals(MessageType.COMAPI_SUCCESS, rcvdMessage.getType());
      assertEquals(GeigerApi.MASTER_ID, rcvdMessage.getSourceId());
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
      PluginApi localMaster = CommunicationApiFactory.getLocalApi("", GeigerApi.MASTER_ID,
        Declaration.DO_NOT_SHARE_DATA);
      // create listener
      SimpleEventListener masterListener = new SimpleEventListener();
      localMaster.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, masterListener);

      // create plugin, this registers and activates the plugin automatically
      PluginApi plugin = CommunicationApiFactory.getLocalApi("", "plugin1",
        Declaration.DO_NOT_SHARE_DATA);
      SimpleEventListener pluginListener = new SimpleEventListener();
      plugin.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, pluginListener);

      // register and disable Menu
      plugin.registerMenu("testMenu", new GeigerUrl(GeigerApi.MASTER_ID, "testMenu"));
      plugin.disableMenu("testMenu");

      // check master (the first 2 messages should always be registerPlugin and activatePlugin)
      List<Message> receivedEventsMaster = masterListener.getEvents();
      assertEquals(4, receivedEventsMaster.size());
      Message rcvdMessage = receivedEventsMaster.get(3);
      assertEquals(MessageType.DISABLE_MENU, rcvdMessage.getType());
      assertEquals("plugin1", rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals(GeigerApi.MASTER_ID, rcvdMessage.getAction().getPlugin());
      assertEquals("disableMenu", rcvdMessage.getAction().getPath());
      assertEquals("testMenu", new String(rcvdMessage.getPayload()));

      // check Plugin (the first 2 messages should always be COMAPI_SUCCESS for
      // registerPlugin and activatePlugin)
      List<Message> receivedEventsPlugin = pluginListener.getEvents();
      assertEquals(4, receivedEventsPlugin.size());
      rcvdMessage = receivedEventsPlugin.get(3);
      assertEquals(MessageType.COMAPI_SUCCESS, rcvdMessage.getType());
      assertEquals(GeigerApi.MASTER_ID, rcvdMessage.getSourceId());
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
      PluginApi localMaster = CommunicationApiFactory.getLocalApi("", GeigerApi.MASTER_ID,
        Declaration.DO_NOT_SHARE_DATA);
      // create listener
      SimpleEventListener masterListener = new SimpleEventListener();
      localMaster.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, masterListener);

      // create plugin, this registers and activates the plugin automatically
      PluginApi plugin = CommunicationApiFactory.getLocalApi("", "plugin1", Declaration.DO_NOT_SHARE_DATA);
      SimpleEventListener pluginListener = new SimpleEventListener();
      plugin.registerListener(new MessageType[]{MessageType.ALL_EVENTS}, pluginListener);

      // register and disable Menu
      plugin.registerMenu("testMenu", new GeigerUrl(GeigerApi.MASTER_ID, "testMenu"));
      plugin.menuPressed(new GeigerUrl(GeigerApi.MASTER_ID, "testMenu"));

      // check master (the first 2 messages should always be registerPlugin and activatePlugin)
      List<Message> receivedEventsMaster = masterListener.getEvents();
      assertEquals(4, receivedEventsMaster.size());
      Message rcvdMessage = receivedEventsMaster.get(3);
      assertEquals(MessageType.MENU_PRESSED, rcvdMessage.getType());
      assertEquals("plugin1", rcvdMessage.getSourceId());
      assertEquals("geiger", rcvdMessage.getAction().getProtocol());
      assertEquals(GeigerApi.MASTER_ID, rcvdMessage.getAction().getPlugin());
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