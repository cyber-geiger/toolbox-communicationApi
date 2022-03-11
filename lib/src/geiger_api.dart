library geiger_api;

import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:logging/logging.dart';

import '../geiger_api.dart';
import 'plugin/menu_registrar.dart';
import 'plugin/plugin_registrar.dart';

/// The API provided by all communicator interfaces.
abstract class GeigerApi implements PluginRegistrar, MenuRegistrar {
  static const String masterId = '__MASTERPLUGIN__';
  static const String masterExecutor = 'FIXME';
  static final Logger logger = Logger("GeigerApi");

  abstract final String id;

  Future<void> initialize();

  /// Activates the plugin and sets up communication on the specified [port].
  Future<void> activatePlugin();

  /// Authorize the plugin
  void authorizePlugin(PluginInformation plugin);

  /// Deactivates the plugin and makes sure that a plugin is started immediately if contacted.
  ///
  /// If a plugin is properly deactivated no timeout is reached before contacting a plugin.
  Future<void> deactivatePlugin();

  /// Obtain controller to access the storage.
  ///
  /// Throws StorageException in case allocation of storage backed fails
  StorageController? getStorage();

  /// Register a [listener] for specific [events] on the Master.
  ///
  /// Use [MessageType.allEvents] to register for all messages.
  Future<void> registerListener(
      List<MessageType> events, PluginListener listener);

  /// Remove a [listener] waiting for [events].
  ///
  /// Specify `null` for [events] to remove the listener from all events.
  void deregisterListener(List<MessageType>? events, PluginListener listener);

  /// Sends a custom, plugin-specific [message] to a peer plugin with the id [pluginId].
  ///
  /// Mainly used for internal purposes. Plugins may only send messages to the toolbox core.
  Future<void> sendMessage(Message message, [String? pluginId]);

  /// Notify plugin about a menu entry with a specific [url] being pressed.
  ///
  /// Wrapper function used by UI to notify plugins about pressed buttons/menu entries.
  Future<void> menuPressed(GeigerUrl url);

  /// Returns the list of currently registered menu.
  ///
  /// This call is for the toolbox core only.
  List<MenuItem> getMenuList();

  /// Notify all plugins about the event that a scan button has been pressed.
  ///
  /// This call is for the toolbox core only.
  Future<void> scanButtonPressed();

  /// get the declaration of data sharing provided when establishing the agreement.
  Declaration get declaration;

  Future<void> zapState();

  Future<void> close();

  /// Gets a list of PluginInformation of all registered plugins starting with [id].
  ///
  /// For security reasons all PluginInformation have empty secrets.
  Future<List<PluginInformation>> getRegisteredPlugins([String? id]);
}
