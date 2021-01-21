package eu.cybergeiger.communication;

import javax.naming.NameNotFoundException;

public interface PluginRegistrar {
  /***
   * <p>Registers the plugin to the toolbox framework.</p>
   *
   * @param id an id identifying the current plugin
   */
  void registerPlugin(String id);

  /***
   * <p>Unregisters an already registered plugin in the toolbox.</p>
   *
   * @param id The id to deregister
   * @throws NameNotFoundException if the provided id is not available in the current auth database
   */
  void deregisterPlugin(String id) throws NameNotFoundException;

}