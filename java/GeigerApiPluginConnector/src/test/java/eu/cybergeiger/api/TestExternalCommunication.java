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

  /**
   * Checks message equality without requestId.
   */
  private static void assertMessage(Message actual, Message expected) {
    assertThat(actual.getSourceId()).isEqualTo(expected.getSourceId());
    assertThat(actual.getTargetId()).isEqualTo(expected.getTargetId());
    assertThat(actual.getType()).isEqualTo(expected.getType());
    assertThat(actual.getAction()).isEqualTo(expected.getAction());
    assertThat(actual.getPayloadString()).isEqualTo(expected.getPayloadString());
  }

  private static void assertSuccessMessage(Message actual, String function) {
    assertMessage(
      actual,
      new Message(
        GeigerApi.MASTER_ID, PLUGIN_ID,
        MessageType.COMAPI_SUCCESS,
        new GeigerUrl(PLUGIN_ID, function)
      )
    );
  }

  private PluginApi createPlugin() throws IOException {
    return new PluginApi(
      "",
      PLUGIN_ID,
      Declaration.DO_NOT_SHARE_DATA,
      GeigerApi.MASTER_EXECUTOR,
      false,
      true
    );
  }

  @Test
  public void testRegisterExternalPlugin() throws IOException {
    createPlugin().close();
  }

  @Test
  public void testActivatePlugin() throws IOException {
    createPlugin().close();
  }

  @Test
  public void testDeactivatePlugin() throws IOException, InterruptedException,
    TimeoutException {
    try (GeigerApi plugin = createPlugin()) {
      MessageCollector collector = new MessageCollector(plugin);

      plugin.deregisterPlugin();

      assertSuccessMessage(
        collector.awaitMessage(0),
        "deregisterPlugin"
      );
    }
  }

  private MenuItem generateTestMenu() throws StorageException {
    Node menu = new DefaultNode(
      ":" + MENU_ID,
      PLUGIN_ID,
      Visibility.RED,
      new NodeValue[]{
        new DefaultNodeValue(MenuItem.NAME_KEY, "test"),
        new DefaultNodeValue(MenuItem.TOOLTIP_KEY, "test")
      },
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
    try (GeigerApi plugin = createPlugin()) {
      MessageCollector collector = new MessageCollector(plugin);

      plugin.registerMenu(generateTestMenu());

      assertSuccessMessage(
        collector.awaitMessage(0),
        "registerMenu"
      );
    }
  }

  @Test
  public void testDisableMenu() throws IOException, InterruptedException, TimeoutException {
    try (GeigerApi plugin = createPlugin()) {
      MessageCollector collector = new MessageCollector(plugin);

      plugin.registerMenu(generateTestMenu());
      plugin.disableMenu(MENU_ID);

      assertSuccessMessage(
        collector.awaitMessage(1),
        "disableMenu"
      );
    }
  }

  @Test
  public void testMenuPressed() throws IOException, InterruptedException, TimeoutException {
    try (GeigerApi plugin = createPlugin()) {
      MessageCollector collector = new MessageCollector(plugin);

      MenuItem menu = generateTestMenu();
      plugin.registerMenu(menu);

      assertMessage(
        collector.awaitMessage(1),
        new Message(
          GeigerApi.MASTER_ID, PLUGIN_ID,
          MessageType.MENU_PRESSED,
          menu.getAction()
        )
      );
    }
  }
}
