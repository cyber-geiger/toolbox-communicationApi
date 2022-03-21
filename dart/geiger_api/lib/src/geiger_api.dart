library geiger_api;

import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:logging/logging.dart';

import '../geiger_api.dart';
import 'plugin/menu_registrar.dart';
import 'plugin/plugin_registrar.dart';

/// The API provided by all communicator interfaces.
abstract class GeigerApi implements PluginRegistrar, MenuRegistrar {
  static const String masterId = '__MASTERPLUGIN__';

  // Is writable to allow examples to specify another master.
  static String masterExecutor = 'FIXME';
  static final Logger logger = Logger("GeigerApi");

  /// Identifier of plugin.
  String get id;

  /// Data sharing [Declaration].
  Declaration get declaration;

  /// [StorageController] to access the master storage.
  StorageController get storage;

  /// Initialize asynchronous parts of the plugin.
  ///
  /// Must be called once after contruction.
  Future<void> initialize();

  /// Retrieve the [StorageController] to access the master storage.
  ///
  /// Throws [StorageException] in case allocation of the storage backend fails.
  @Deprecated('Use [storage]')
  StorageController getStorage() {
    return storage;
  }

  /// Get the [PluginInformation] of all registered plugins.
  ///
  /// Only the plugins which ids start with [startId] are
  /// returned if [startId] is specified.
  /// For security reasons all [PluginInformation.secret]s are empty.
  /// TODO: should only be available on master?
  Future<List<PluginInformation>> getRegisteredPlugins([String? startId]);

  /// Register the [listener] for specific [events] locally.
  ///
  /// Use [MessageType.allEvents] to register to all event types.
  void registerListener(List<MessageType> events, PluginListener listener);

  /// Remove the [listener] from specific [events] locally.
  ///
  /// Set [events] to `null` to remove the [listener] from all events.
  void deregisterListener(List<MessageType>? events, PluginListener listener);

  /// Send a [message] to a another plugin with the id [pluginId].
  ///
  /// If [pluginId] is not specified, [message.targetId] is used.
  /// Non-master plugins can only send messages to the master.
  Future<void> sendMessage(Message message, [String? pluginId]);

  /// Notify plugin about a [MenuItem] with a specific [url] being pressed.
  Future<void> menuPressed(GeigerUrl url);

  /// Get a list of all registered [MenuItem]s.
  ///
  /// Can only be called on the master.
  List<MenuItem> getMenuList();

  /// Notify all plugins that the scan button was pressed.
  ///
  /// Can only be called on the master.
  Future<void> scanButtonPressed();

  /// Reset the GeigerApi by removing all registered plugins and [MenuItem]s.
  Future<void> zapState();

  /// Release all resources.
  Future<void> close();
}
