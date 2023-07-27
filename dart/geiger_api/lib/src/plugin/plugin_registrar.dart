library geiger_api;

import 'plugin_information.dart';

abstract class PluginRegistrar {
  /// Get the [PluginInformation] of all registered plugins.
  ///
  /// Only the plugins which ids start with [startId] are
  /// returned if [startId] is specified.
  /// For security reasons all [PluginInformation.secret]s are empty.
  Future<List<PluginInformation>> getRegisteredPlugins([String? startId]);

  /// Registers the plugin to the toolbox framework.
  ///
  /// Throws [CommunicationException] if registering in the master plugin failed.
  Future<void> registerPlugin();

  /// Mark this plugin as active on the master.
  ///
  /// Only activated plugins can receive messages.
  Future<void> activatePlugin();

  /// Authorize the plugin.
  void authorizePlugin(PluginInformation plugin);

  /// Mark this plugin as deactivated on the master.
  ///
  /// Deactivated plugins cannot receive messages.
  /// The master plugin will automatically try to start
  /// the plugin if it needs to it send a message.
  Future<void> deactivatePlugin();

  /// Unregisters an already registered plugin in the toolbox.
  ///
  /// Throws [CommunicationException] if the provided id is not available in the current auth database.
  Future<void> deregisterPlugin();
}
