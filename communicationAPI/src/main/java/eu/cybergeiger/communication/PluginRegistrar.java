package eu.cybergeiger.communication;

import javax.naming.NameNotFoundException;

interface PluginRegistrar {
  /***
   * <p>Registers the plugin to the toolbox framework.</p>
   */
  void registerPlugin();

  /***
   * <p>Unregisters an already registered plugin in the toolbox.</p>
   *
   * @throws NameNotFoundException if the provided id is not available in the current auth database
   */
  void deregisterPlugin() throws NameNotFoundException;

}