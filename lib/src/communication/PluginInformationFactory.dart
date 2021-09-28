import 'dart:collection';

import 'CommunicationSecret.dart';
import 'PluginInformation.dart';

/// <p>A factory class to create plugin information entries.</p>
class PluginInformationFactory {
  static final Map<String, PluginInformation> store = HashMap();

  /// <p>Retrieves plugin information for a plugin.</p>
  /// @param id the id of the the plugin
  /// @param executor the executor string required to run the plugin
  /// @param port     the current port of the plugin (-1 denotes unknown)
  /// @param secret   the communication secret
  /// @return returns the information object or null if not available
  static PluginInformation? getPluginInformation(String id,
      [String? executor, int? port, CommunicationSecret? secret]) {
    if (executor == null || port == null || secret == null) {
      return store[id.toLowerCase()];
    }

    var info = store[id.toLowerCase()];
    if (info == null) {
      info = PluginInformation(executor, port, secret);
      setPluginInformation(id, info);
    }
    return info;
  }

  /// <p>Puts a pluginInformation into the store.</p>
  /// @param id   the id of the the plugin
  /// @param info the information object containing all relevant information to contact the plugin
  /// @return the previously set information or null if new
  static PluginInformation? setPluginInformation(
      String id, PluginInformation info) {
    var old = getPluginInformation(id);
    store[id.toLowerCase()] = info;
    return old;
  }

  /// <p>Clears all plugin information from the store.</p>
  static void zap() {
    store.clear();
  }
}
