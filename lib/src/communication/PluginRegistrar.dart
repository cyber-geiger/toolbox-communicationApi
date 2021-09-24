abstract class PluginRegistrar {
  /// <p>Registers the plugin to the toolbox framework.</p>
  /// @throws CommunicationException if registering in the master plugin failed
  void registerPlugin();

  /// <p>Unregisters an already registered plugin in the toolbox.</p>
  /// @throws CommunicationException if the provided id is not available in the current auth database
  void deregisterPlugin();
}