package eu.cybergeiger.communication;

import java.io.Serializable;

/**
 * <p>Represents a menu item for a list of items.</p>
. * FIXME: Menu texts are not internationalizable
 */
public class MenuItem implements Serializable {

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

}
