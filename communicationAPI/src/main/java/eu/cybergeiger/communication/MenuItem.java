package eu.cybergeiger.communication;

import ch.fhnw.geiger.serialization.Serializer;
import ch.fhnw.geiger.serialization.SerializerHelper;
import ch.fhnw.geiger.totalcross.ByteArrayInputStream;
import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;
import java.io.IOException;

/**
 * <p>Represents a menu item for a list of items.</p>
 * . * FIXME: Menu texts are not internationalizable
 */
public class MenuItem implements Serializer {

  private static final long serialVersionUID = 481231212L;

  private String menu;
  private GeigerUrl action;
  private boolean enabled;

  /**
   * <p>Creates a new,enabled menu item and assigns an action URL.</p>
   *
   * @param menu   the menu name
   * @param action the action url
   */
  public MenuItem(String menu, GeigerUrl action) {
    this(menu, action, true);
  }


  /**
   * <p>Creates a new menu item and assigns an action URL.</p>
   *
   * @param menu    the menu name
   * @param action  the action url
   * @param enabled is the menu entry currently enabled
   */
  public MenuItem(String menu, GeigerUrl action, boolean enabled) {
    this.menu = menu;
    this.action = action;
    this.enabled = enabled;
  }

  /**
   * <p>Returns the menu string.</p>
   *
   * @return the menu string
   */
  public String getMenu() {
    return this.menu;
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
    SerializerHelper.writeLong(out, serialVersionUID);
    SerializerHelper.writeString(out, menu);
    action.toByteArrayStream(out);
    SerializerHelper.writeInt(out, enabled ? 1 : 0);
    SerializerHelper.writeLong(out, serialVersionUID);
  }

  /**
   * <p>Reads objects from ByteArrayInputStream and stores them in map.</p>
   *
   * @param in ByteArrayInputStream to be used
   * @return the deserialized Storable String
   * @throws IOException if value cannot be read
   */
  public static MenuItem fromByteArrayStream(ByteArrayInputStream in) throws IOException {
    if (SerializerHelper.readLong(in) != serialVersionUID) {
      throw new ClassCastException();
    }

    String menu = SerializerHelper.readString(in);
    GeigerUrl url = GeigerUrl.fromByteArrayStream(in);
    boolean enabled = SerializerHelper.readInt(in) == 1;

    if (SerializerHelper.readLong(in) != serialVersionUID) {
      throw new ClassCastException();
    }

    return new MenuItem(menu, url, enabled);
  }

  @Override
  public String toString() {
    return '"' + menu + "\"->" + action + "(" + (enabled ? "enabled" : "disabled") + ")";
  }

  /**
   * <p>Wrapper function to simplify serialization.</p>
   *
   * @return the serializer object as byte array
   */
  public byte[] toByteArray() {
    try {
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      toByteArrayStream(out);
      return out.toByteArray();
    } catch (IOException e) {
      return null;
    }
  }

  /**
   * <p>Wrapper function to simplify deserialization.</p>
   *
   * @param buf the buffer to be read
   * @return the deserialized object
   */
  public static MenuItem fromByteArray(byte[] buf) {
    try {
      return (MenuItem) (Serializer.fromByteArray(buf));
    } catch (IOException ioe) {
      return null;
    }
  }


}
