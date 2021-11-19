library geiger_api;

import 'geiger_url.dart';

/// Registrar interface for Menus.
abstract class MenuRegistrar {
  /// Register a menu entry [menu] in the toolbox core.
  ///
  /// Must also provide the [action] to be triggered.
  Future<void> registerMenu(String menu, GeigerUrl action);

  /// Enable a previously registered [menu].
  Future<void> enableMenu(String menu);

  /// Disable a previously registered [menu].
  Future<void> disableMenu(String menu);

  /// Removing a menu entry [menu] from th toolbox core.
  Future<void> deregisterMenu(String menu);
}
