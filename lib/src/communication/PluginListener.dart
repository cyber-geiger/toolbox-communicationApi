import 'GeigerUrl.dart';
import 'Message.dart';

/// <p>Interface for plugins listening for events.</p>
abstract class PluginListener {
  /// <p>Listener for Geiger events.</p>
  /// <p>Any plugin must register for such events and </p>
  /// @param url the url the message was sent to
  /// @param msg the message
  void pluginEvent(GeigerUrl url, Message msg);
}
