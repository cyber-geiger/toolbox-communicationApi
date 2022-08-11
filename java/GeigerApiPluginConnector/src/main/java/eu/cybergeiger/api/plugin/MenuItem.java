package eu.cybergeiger.api.plugin;

import eu.cybergeiger.api.message.GeigerUrl;
import eu.cybergeiger.serialization.Serializable;
import eu.cybergeiger.serialization.SerializerHelper;
import eu.cybergeiger.storage.StorageException;
import eu.cybergeiger.storage.node.DefaultNode;
import eu.cybergeiger.storage.node.Node;
import eu.cybergeiger.storage.node.value.DefaultNodeValue;
import eu.cybergeiger.storage.node.value.NodeValue;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Objects;

/**
 * <p>Represents a menu item for a list of items.</p>
 */
public class MenuItem implements Serializable {
  private static final long serialVersionUID = 481231212L;

  public static final String NAME_KEY = "name";
  public static final String TOOLTIP_KEY = "tooltip";

  private final Node menu;
  private final GeigerUrl action;
  private boolean enabled;

  /**
   * <p>Creates a new,enabled menu item and assigns an action URL.</p>
   *
   * @param menu   Node with NAME_KEY and TOOLTIP_KEY value.
   * @param action the action url
   */
  public MenuItem(Node menu, GeigerUrl action) {
    this(menu, action, true);
  }


  /**
   * <p>Creates a new menu item and assigns an action URL.</p>
   *
   * @param menu    Node with NAME_KEY and TOOLTIP_KEY value.
   * @param action  the action url
   * @param enabled is the menu entry currently enabled
   */
  public MenuItem(Node menu, GeigerUrl action, boolean enabled) {
    this.menu = menu;
    this.action = action;
    this.enabled = enabled;
  }

  /**
   * <p>Returns the menu string.</p>
   *
   * @return the menu string
   */
  public Node getMenu() {
    return this.menu;
  }

  private String getMenuValue(String key, String languageRange) throws StorageException {
    NodeValue value = menu.getValue(key);
    if (value == null)
      throw new StorageException("Menu node \"" + menu.getPath() + "\" has no \"" + key + "\" value.");
    return value.getValue(languageRange);
  }

  public String getName() throws StorageException {
    return getName(DefaultNodeValue.DEFAULT_LOCALE.toLanguageTag());
  }

  public String getName(String languageRange) throws StorageException {
    return getMenuValue(NAME_KEY, languageRange);
  }

  public String getTooltip() throws StorageException {
    return getTooltip(DefaultNodeValue.DEFAULT_LOCALE.toLanguageTag());
  }

  public String getTooltip(String languageRange) throws StorageException {
    return getMenuValue(TOOLTIP_KEY, languageRange);
  }

  /**
   * <p>Returns the action URL.</p>
   *
   * @return the action url
   */
  public GeigerUrl getAction() {
    return this.action;
  }

  /**
   * <p>Returns the menu state.</p>
   *
   * @return true if the menu entry is currently enabled
   */
  public boolean isEnabled() {
    return this.enabled;
  }

  /**
   * <p>Enables or disables the menu entry.</p>
   *
   * @param enabled the new state of the menu entry
   * @return the previously set state
   */
  public boolean setEnabled(boolean enabled) {
    boolean old = this.enabled;
    this.enabled = enabled;
    return old;
  }

  @Override
  public void toByteArrayStream(ByteArrayOutputStream out) throws IOException {
    SerializerHelper.writeMarker(out, serialVersionUID);
    menu.toByteArrayStream(out);
    action.toByteArrayStream(out);
    SerializerHelper.writeInt(out, enabled ? 1 : 0);
    SerializerHelper.writeMarker(out, serialVersionUID);
  }

  /**
   * <p>Reads objects from ByteArrayInputStream and stores them in map.</p>
   *
   * @param in ByteArrayInputStream to be used
   * @return the deserialized Storable String
   * @throws IOException if value cannot be read
   */
  public static MenuItem fromByteArrayStream(ByteArrayInputStream in) throws IOException {
    SerializerHelper.testMarker(in, serialVersionUID);
    Node menu = DefaultNode.fromByteArrayStream(in, null);
    GeigerUrl url = GeigerUrl.fromByteArrayStream(in);
    boolean enabled = SerializerHelper.readInt(in) == 1;
    SerializerHelper.testMarker(in, serialVersionUID);
    return new MenuItem(menu, url, enabled);
  }

  @Override
  public String toString() {
    return '"' + menu.getPath() + "\"->" + action + "(" + (enabled ? "enabled" : "disabled") + ")";
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    }
    if (o == null || getClass() != o.getClass()) {
      return false;
    }
    MenuItem menuItem = (MenuItem) o;
    return enabled == menuItem.enabled
      && Objects.equals(menu, menuItem.menu)
      && Objects.equals(action, menuItem.action);
  }

  @Override
  public int hashCode() {
    return Objects.hash(menu, action, enabled);
  }

  /**
   * <p>Wrapper function to simplify serialization.</p>
   *
   * @return the serializer object as byte array
   */
  public byte[] toByteArray() throws IOException {
    ByteArrayOutputStream out = new ByteArrayOutputStream();
    toByteArrayStream(out);
    return out.toByteArray();
  }

  /**
   * <p>Wrapper function to simplify deserialization.</p>
   *
   * @param buf the buffer to be read
   * @return the deserialized object
   */
  public static MenuItem fromByteArray(byte[] buf) throws IOException {
    return fromByteArrayStream(new ByteArrayInputStream(buf));
  }

  public MenuItem clone() {
    try {
      return fromByteArray(toByteArray());
    } catch (IOException e) {
      throw new RuntimeException("Cloning MenuItem failed.", e);
    }
  }
}
