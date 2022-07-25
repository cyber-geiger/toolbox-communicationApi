package eu.cybergeiger.api;

import eu.cybergeiger.api.message.GeigerUrl;
import eu.cybergeiger.api.message.Message;
import eu.cybergeiger.api.message.MessageType;
import eu.cybergeiger.api.plugin.Declaration;
import eu.cybergeiger.api.plugin.MenuItem;
import eu.cybergeiger.storage.StorageException;
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
  static final String MENU_ID = "menu";

  @Test
  public void testRegisterExternalPlugin() throws IOException {
    new PluginApi(
      "",
      PLUGIN_ID,
      Declaration.DO_NOT_SHARE_DATA
    ).close();
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
    plugin.registerListener(MessageType.getAllTypes(), collector);

    plugin.deregisterPlugin();

    collector.awaitCount(1);
    Message message = collector.getMessages().get(0);
    assertThat(message.getType()).isEqualTo(MessageType.COMAPI_SUCCESS);
    assertThat(message.getSourceId()).isEqualTo(GeigerApi.MASTER_ID);
    GeigerUrl action = message.getAction();
    assertThat(action).isNotNull();
    assertThat(action.getProtocol()).isEqualTo(GeigerUrl.GEIGER_PROTOCOL);
    assertThat(action.getPlugin()).isEqualTo(PLUGIN_ID);
    assertThat(action.getPath()).isEqualTo("deregisterPlugin");

    plugin.close();
  }

  private MenuItem generateTestMenu() throws StorageException {
    Node menu = new DefaultNode(
      ":" + MENU_ID,
      PLUGIN_ID,
      Visibility.RED,
      new NodeValue[]{new DefaultNodeValue(MenuItem.NAME_KEY, "test")},
      new Node[0]
    );
    menu.setLastModified(0);
    return new MenuItem(
      menu,
      new GeigerUrl(PLUGIN_ID, MENU_ID),
      true
    );
  }

  @Test
  public void testRegisterMenu() throws IOException, InterruptedException, TimeoutException {
    GeigerApi plugin = new PluginApi(
      "",
      PLUGIN_ID,
      Declaration.DO_NOT_SHARE_DATA
    );
    MessageCollector collector = new MessageCollector();
    plugin.registerListener(MessageType.getAllTypes(), collector);

    plugin.registerMenu(generateTestMenu());

    collector.awaitCount(1);
    Message message = collector.getMessages().get(0);
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
  public void testDisableMenu()  throws IOException, InterruptedException, TimeoutException {
    GeigerApi plugin = new PluginApi(
      "",
      PLUGIN_ID,
      Declaration.DO_NOT_SHARE_DATA
    );
    MessageCollector collector = new MessageCollector();
    plugin.registerListener(MessageType.getAllTypes(), collector);

    plugin.registerMenu(generateTestMenu());
    plugin.disableMenu(MENU_ID);

    collector.awaitCount(2);
    Message message = collector.getMessages().get(1);
    assertThat(message.getType()).isEqualTo(MessageType.COMAPI_SUCCESS);
    assertThat(message.getSourceId()).isEqualTo(GeigerApi.MASTER_ID);
    GeigerUrl action = message.getAction();
    assertThat(action).isNotNull();
    assertThat(action.getProtocol()).isEqualTo(GeigerUrl.GEIGER_PROTOCOL);
    assertThat(action.getPlugin()).isEqualTo(PLUGIN_ID);
    assertThat(action.getPath()).isEqualTo("disableMenu");

    plugin.close();
  }

  @Test
  public void testMenuPressed()  throws IOException, InterruptedException, TimeoutException  {
    GeigerApi plugin = new PluginApi(
      "",
      PLUGIN_ID,
      Declaration.DO_NOT_SHARE_DATA
    );
    MessageCollector collector = new MessageCollector();
    plugin.registerListener(MessageType.getAllTypes(), collector);

    MenuItem menu = generateTestMenu();
    plugin.registerMenu(menu);

    collector.awaitCount(2);
    Message message = collector.getMessages().get(1);
    assertThat(message.getType()).isEqualTo(MessageType.MENU_PRESSED);
    assertThat(message.getSourceId()).isEqualTo(GeigerApi.MASTER_ID);
    GeigerUrl action = message.getAction();
    assertThat(action).isEqualTo(menu.getAction());

    plugin.close();
  }
}
