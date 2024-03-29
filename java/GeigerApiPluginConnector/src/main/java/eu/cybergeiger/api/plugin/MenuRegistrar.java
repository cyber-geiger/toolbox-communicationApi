package eu.cybergeiger.api.plugin;

import eu.cybergeiger.api.exceptions.CommunicationException;
import eu.cybergeiger.api.message.GeigerUrl;

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
   * @param menu   menu item
   */
  void registerMenu(MenuItem menu) throws CommunicationException;

  /**
   * <p>Enable a previously registered menu.</p>
   *
   * @param menu menu string depicting menu hierarchy
   */
  void enableMenu(String menu) throws CommunicationException;

  /**
   * <p>Disable a previously registered menu.</p>
   *
   * @param menu menu string depicting menu hierarchy
   */
  void disableMenu(String menu) throws CommunicationException;

  /**
   * <p>Removing a menu entry from th toolbox core.</p>
   *
   * <p>The method only allows URL with protocol GEIGER (geiger://).</p>
   *
   * @param menu menu string depicting menu hierarchy
   */
  void deregisterMenu(String menu) throws CommunicationException;

}
