library geiger_api;

import 'package:geiger_localstorage/geiger_localstorage.dart';

import 'geiger_url.dart';

/// Registrar interface for Menus.
abstract class MenuRegistrar {
  /// Register a menu entry [menu] in the toolbox core.
  ///
  /// [menu] is an unstored, internationalized node reflecting a menu entry. The node path is an identifier which should be prefixed with :menu:<PluginUUID>:<menuIdentifier>.
  /// the following keys should be supported:
  /// - 'name' The name of the menu to appear (internationalizable)
  /// - 'tooltip' for the menu (internationalizable)
  /// - 'help' the help text (internationalizable)
  /// Must also provide the [action] to be triggered.
  Future<void> registerMenu(Node menu, GeigerUrl action);

  /// Enable a previously registered [menuId].
  Future<void> enableMenu(String menuId);

  /// Disable a previously registered [menuId].
  Future<void> disableMenu(String menuId);

  /// Removing a menu entry [menuId] from th toolbox core.
  Future<void> deregisterMenu(String menuId);
}
