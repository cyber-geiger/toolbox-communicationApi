package eu.cybergeiger.api;

import eu.cybergeiger.api.message.GeigerUrl;
import eu.cybergeiger.api.message.Message;
import eu.cybergeiger.api.message.MessageType;
import eu.cybergeiger.api.plugin.Declaration;
import eu.cybergeiger.api.plugin.MenuItem;
import eu.cybergeiger.storage.Visibility;
import eu.cybergeiger.storage.node.DefaultNode;
import eu.cybergeiger.storage.node.Node;
import eu.cybergeiger.storage.node.value.DefaultNodeValue;
import eu.cybergeiger.storage.node.value.NodeValue;
import mocks.MessageCollector;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.util.concurrent.TimeoutException;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <p>Testing non local communication.</p>
 */
public class TestExternalCommunication extends DartTest {
  static final String PLUGIN_ID = "plugin";

  @Test
  public void testRegisterExternalPlugin() throws IOException {
    new PluginApi(
      "",
      PLUGIN_ID,
      Declaration.DO_NOT_SHARE_DATA
    );
  }

  @Test
  public void testActivatePlugin() throws IOException {
    new PluginApi(
      "",
      PLUGIN_ID,
      Declaration.DO_NOT_SHARE_DATA
    ).close();
  }

  @Test
  public void testDeactivatePlugin() throws IOException, InterruptedException,
    TimeoutException {
    GeigerApi plugin = new PluginApi(
      "",
      PLUGIN_ID,
      Declaration.DO_NOT_SHARE_DATA
    );
    MessageCollector collector = new MessageCollector();
    plugin.registerListener(MessageType.values(), collector);

    plugin.deregisterPlugin();

    collector.awaitCount(1);
    Message message = collector.getEvents().get(0);
    assertThat(message.getType()).isEqualTo(MessageType.COMAPI_SUCCESS);
    assertThat(message.getSourceId()).isEqualTo(GeigerApi.MASTER_ID);
    GeigerUrl action = message.getAction();
    assertThat(action).isNotNull();
    assertThat(action.getProtocol()).isEqualTo(GeigerUrl.GEIGER_PROTOCOL);
    assertThat(action.getPlugin()).isEqualTo(PLUGIN_ID);
    assertThat(action.getPath()).isEqualTo("deregisterPlugin");

    plugin.close();
  }

  @Test
  public void testRegisterMenu() throws IOException, InterruptedException, TimeoutException {
    GeigerApi plugin = new PluginApi(
      "",
      PLUGIN_ID,
      Declaration.DO_NOT_SHARE_DATA
    );
    MessageCollector collector = new MessageCollector();
    plugin.registerListener(MessageType.values(), collector);

    Node menu = new DefaultNode(
      ":menu:1111-1111-111111-111111:test",
      PLUGIN_ID,
      Visibility.RED,
      new NodeValue[]{new DefaultNodeValue(MenuItem.NAME_KEY, "test")},
      new Node[0]
    );
    menu.setLastModified(0);
    plugin.registerMenu(new MenuItem(
      menu,
      new GeigerUrl(PLUGIN_ID, "test"),
      false
    ));

    collector.awaitCount(1);
    Message message = collector.getEvents().get(0);
    assertThat(message.getType()).isEqualTo(MessageType.COMAPI_SUCCESS);
    assertThat(message.getSourceId()).isEqualTo(GeigerApi.MASTER_ID);
    GeigerUrl action = message.getAction();
    assertThat(action).isNotNull();
    assertThat(action.getProtocol()).isEqualTo(GeigerUrl.GEIGER_PROTOCOL);
    assertThat(action.getPlugin()).isEqualTo(PLUGIN_ID);
    assertThat(action.getPath()).isEqualTo("registerMenu");

    plugin.close();
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
