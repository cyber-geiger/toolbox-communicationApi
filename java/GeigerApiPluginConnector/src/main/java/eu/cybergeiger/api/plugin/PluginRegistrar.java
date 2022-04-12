package eu.cybergeiger.api.plugin;

import eu.cybergeiger.api.exceptions.CommunicationException;

public interface PluginRegistrar {
  /***
   * <p>Registers the plugin to the toolbox framework.</p>
   *
   * @throws CommunicationException if registering in the master plugin failed
   */
  void registerPlugin() throws CommunicationException;

  /**
   * <p>Activates the plugin and sets up communication.</p>
   */
  void activatePlugin() throws CommunicationException;

  /**
   * <p>deactivates the plugin and makes sure that a plugin is started immediately if contacted.</p>
   *
   * <p>If a plugin is properly deactivated no timeout is reached before contacting a plugin.</p>
   */
  void deactivatePlugin() throws CommunicationException;

  /***
   * <p>Unregisters an already registered plugin in the toolbox.</p>
   *
   * @throws CommunicationException if the provided id is not available in the current auth database
   */
  void deregisterPlugin() throws CommunicationException;

}