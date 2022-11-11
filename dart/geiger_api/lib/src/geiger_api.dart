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
  static String masterUniversalLink = 'https://master.cyber-geiger.eu';
  static final Logger logger = Logger('GeigerApi');

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

  /// Register the [listener] for specific [events] locally.
  ///
  /// Use [MessageType.allEvents] to register to all event types.
  void registerListener(List<MessageType> events, PluginListener listener);

  /// Remove the [listener] from specific [events] locally.
  ///
  /// Set [events] to `null` to remove the [listener] from all events.
  void deregisterListener(List<MessageType>? events, PluginListener listener);

  /// Send a [message] to a another [plugin].
  ///
  /// If [plugin] is not provided, [pluginId] or alternatively
  /// [message.targetId] is used to retrieve the registered plugin information.
  ///
  /// The messages are sent in the order this function is called.
  Future<void> sendMessage(Message message,
      [String? pluginId, PluginInformation? plugin]);

  /// Send a [message] to a another [plugin] without waiting
  /// for previous dispatches to finish.
  ///
  /// If [plugin] is not provided, [pluginId] or alternatively
  /// [message.targetId] is used to retrieve the registered plugin information.
  Future<void> sendMessageDirect(Message message,
      [String? pluginId, PluginInformation? plugin]);

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
