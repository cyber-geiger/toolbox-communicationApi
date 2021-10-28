library geiger_api;

import 'geiger_url.dart';
import 'message.dart';

/// Interface for plugins listening for events.
abstract class PluginListener {
  /// Called when the listened event sends a [msg] to a [url].
  void pluginEvent(GeigerUrl url, Message msg);
}
