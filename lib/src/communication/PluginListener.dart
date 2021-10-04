import 'GeigerUrl.dart';
import 'Message.dart';

/// Interface for plugins listening for events.
abstract class PluginListener {
  /// Called when the listened event sends a [msg] to a [url].
  void pluginEvent(GeigerUrl url, Message msg);
}
