package eu.cybergeiger.communication;

/**
 * <p>Registrar interface for Menus.</p>
 */
public interface MenuRegistrar {

  /**
   * <p>Register a Menu entry in the toolbox core.</p>
   *
   * <p>The method only allows URL with protocol GEIGER (geiger://).
   * The host reflects the plugin ID.</p>
   *
   * @param menu    menu string depicting menu hierarchy
   * @param action  action URL to be triggered
   */
  void registerMenu(String menu, GeigerUrl action);

  /**
   * <p>Enable a previously registered menu.</p>
   *
   * @param menu  menu string depicting menu hierarchy
   */
  void enableMenu(String menu);

  /**
   * <p>Disable a previously registered menu.</p>
   *
   * @param menu  menu string depicting menu hierarchy
   */
  void disableMenu(String menu);

  /**
   * <p>Removing a menu entry from th toolbox core.</p>
   *
   * <p>The method only allows URL with protocol GEIGER (geiger://).</p>
   *
   * @param menu    menu string depicting menu hierarchy
   */
  void deregisterMenu(String menu);

}
