package eu.cybergeiger.communication;

public class MenuItem {

  private String menu;
  private GeigerURL action;
  private boolean enabled;

  public MenuItem(String menu, GeigerURL action) {
    this(menu, action, true);
  }

  public MenuItem(String menu, GeigerURL action, boolean enabled) {
    this.menu = menu;
    this.action = action;
    this.enabled = enabled;
  }

  public String getMenu() {
    return this.menu;
  }

  public GeigerURL  getAction() {
    return this.action;
  }

  public boolean isEnabled() {
    return this.enabled;
  }

  public boolean setEnabled(boolean enabled) {
    boolean old=this.enabled;
    this.enabled=enabled;
    return old;
  }

}
