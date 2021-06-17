package eu.cybergeiger.communication;

interface PluginRegistrar {
  /***
   * <p>Registers the plugin to the toolbox framework.</p>
   */
  void registerPlugin() throws CommunicationException;

  /***
   * <p>Unregisters an already registered plugin in the toolbox.</p>
   *
   * @throws CommunicationException if the provided id is not available in the current auth database
   */
  void deregisterPlugin() throws CommunicationException;

}