package eu.cybergeiger.api;

import eu.cybergeiger.api.message.GeigerUrl;
import eu.cybergeiger.api.plugin.MenuItem;
import eu.cybergeiger.storage.StorageController;
import eu.cybergeiger.storage.StorageException;
import eu.cybergeiger.storage.Visibility;
import eu.cybergeiger.storage.node.DefaultNode;
import eu.cybergeiger.storage.node.Node;
import eu.cybergeiger.storage.node.value.DefaultNodeValue;
import eu.cybergeiger.storage.node.value.NodeValue;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Class to test the MenuItem implementation.
 */
public class TestMenuItem {
  static final String PLUGIN_ID = "plugin";
  static final String MENU_ID = "menu";
  static final String MENU_PATH = StorageController.PATH_DELIMITER + MENU_ID;
  static final String MENU_NAME = "test";
  static final String MENU_TOOLTIP = "test";
  static final GeigerUrl MENU_ACTION = new GeigerUrl(PLUGIN_ID, MENU_ID);
  static final GeigerUrl OTHER_MENU_ACTION = new GeigerUrl(PLUGIN_ID, "other_" + MENU_ID);

  private Node createMenuNode() throws StorageException {
    return new DefaultNode(
      MENU_PATH,
      PLUGIN_ID,
      Visibility.RED,
      new NodeValue[]{
        new DefaultNodeValue(MenuItem.NAME_KEY, MENU_NAME),
        new DefaultNodeValue(MenuItem.TOOLTIP_KEY, MENU_TOOLTIP)
      },
      new Node[0]
    );
  }


  @Test
  public void testConstructor() throws StorageException {
    Node node = createMenuNode();
    MenuItem item = new MenuItem(node, MENU_ACTION, false);
    assertThat(item.getMenu()).isEqualTo(node);
    assertThat(item.getName()).isEqualTo(MENU_NAME);
    assertThat(item.getTooltip()).isEqualTo(MENU_NAME);
    assertThat(item.getAction()).isEqualTo(MENU_ACTION);
    assertThat(item.isEnabled()).isFalse();
  }

  @Test
  public void testSetEnabled() throws StorageException {
    MenuItem item = new MenuItem(createMenuNode(), MENU_ACTION);
    assertThat(item.isEnabled()).isTrue();
    item.setEnabled(false);
    assertThat(item.isEnabled()).isFalse();
  }

  @Test
  public void testToStringEnabled() throws StorageException {
    assertThat(new MenuItem(createMenuNode(), MENU_ACTION, true).toString())
      .isEqualTo("\"" + MENU_PATH + "\"->" + MENU_ACTION + "(enabled)");
  }

  @Test
  public void testToStringDisabled() throws StorageException {
    assertThat(new MenuItem(createMenuNode(), MENU_ACTION, false).toString())
      .isEqualTo("\"" + MENU_PATH + "\"->" + MENU_ACTION + "(disabled)");
  }

  @Test
  public void testEqualsSame() throws StorageException {
    Node node = createMenuNode();
    assertThat(new MenuItem(node, MENU_ACTION))
      .isEqualTo(new MenuItem(node, MENU_ACTION, true));
  }

  @Test
  public void testEqualsDifferentNode() throws StorageException, InterruptedException {
    Node node1 = createMenuNode();
    // Wait to change lastModified timestamp.
    Thread.sleep(10);
    Node node2 = createMenuNode();
    assertThat(new MenuItem(node1, MENU_ACTION))
      .isNotEqualTo(new MenuItem(node2, MENU_ACTION));
  }

  @Test
  public void testEqualsDifferentAction() throws StorageException {
    Node node = createMenuNode();
    assertThat(new MenuItem(node, MENU_ACTION))
      .isNotEqualTo(new MenuItem(node, OTHER_MENU_ACTION));
  }

  @Test
  public void testEqualsDifferentIsEnabled() throws StorageException {
    Node node = createMenuNode();
    assertThat(new MenuItem(node, MENU_ACTION, true))
      .isNotEqualTo(new MenuItem(node, MENU_ACTION, false));
  }

  @Test
  public void testEqualsDifferentObject() throws StorageException {
    assertThat(new MenuItem(createMenuNode(), MENU_ACTION)).isNotEqualTo(new Object());
  }

  @Test
  public void testHashCodeSame() throws StorageException {
    Node node = createMenuNode();
    assertThat(new MenuItem(node, MENU_ACTION).hashCode())
      .isEqualTo(new MenuItem(node, MENU_ACTION, true).hashCode());
  }

  @Test
  public void testHashCodeDifferentNode() throws StorageException {
    assertThat(new MenuItem(createMenuNode(), MENU_ACTION).hashCode())
      .isNotEqualTo(new MenuItem(createMenuNode(), MENU_ACTION).hashCode());
  }

  @Test
  public void testHashCodeDifferentAction() throws StorageException {
    Node node = createMenuNode();
    assertThat(new MenuItem(node, MENU_ACTION).hashCode())
      .isNotEqualTo(new MenuItem(node, OTHER_MENU_ACTION).hashCode());
  }

  @Test
  public void testHashCodeDifferentIsEnabled() throws StorageException {
    Node node = createMenuNode();
    assertThat(new MenuItem(node, MENU_ACTION, true).hashCode())
      .isNotEqualTo(new MenuItem(node, MENU_ACTION, false).hashCode());
  }
}
