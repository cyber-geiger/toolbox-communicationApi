abstract class PluginRegistrar {
  /// Registers the plugin to the toolbox framework.
  ///
  /// Throws [CommunicationException] if registering in the master plugin failed.
  void registerPlugin();

  /// Unregisters an already registered plugin in the toolbox.
  ///
  /// Throws [CommunicationException] if the provided id is not available in the current auth database.
  void deregisterPlugin();
}
