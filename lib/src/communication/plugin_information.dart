library geiger_api;

import 'package:geiger_localstorage/geiger_localstorage.dart';

import 'communication_secret.dart';

/// Object for storing vital plugin information.
class PluginInformation with Serializer {
  static const int serialVersionUID = 48032940912340;
  final String? executable;
  final int port;
  late CommunicationSecret secret;

  /// Creates a [PluginInformation] with the given properties:
  ///
  /// - [executable] the string required for platform specific wakeup of a plugin
  /// - [port]       the port of the plugin to be contacted on
  /// - [secret]     the secret required for communicating (if null a new secret is generated)
  PluginInformation(this.executable, this.port, [CommunicationSecret? secret]) {
    this.secret = secret ?? CommunicationSecret.empty();
  }

  /// Gets the port of the plugin.
  int getPort() {
    return port;
  }

  /// The executable string required for starting the plugin.
  String? getExecutable() {
    return executable;
  }

  /// The communication secret required for sending securely between two instances.
  CommunicationSecret getSecret() {
    return secret;
  }

  @override
  void toByteArrayStream(ByteSink out) {
    SerializerHelper.writeLong(out, serialVersionUID);
    SerializerHelper.writeString(out, executable);
    SerializerHelper.writeInt(out, port);
    secret.toByteArrayStream(out);
    SerializerHelper.writeLong(out, serialVersionUID);
  }

  /// Reads objects from ByteArrayInputStream and stores them in map.
  /// @param in ByteArrayInputStream to be used
  /// @return the deserialized Storable String
  /// @throws IOException if value cannot be read
  static Future<PluginInformation> fromByteArrayStream(ByteStream in_) async {
    if (await SerializerHelper.readLong(in_) != serialVersionUID) {
      throw Exception('Cannot cast');
    }
    String executable = await SerializerHelper.readString(in_) ?? '';
    int port = await SerializerHelper.readInt(in_);
    CommunicationSecret secret = await CommunicationSecret.fromByteArrayStream(
        in_);
    if (await SerializerHelper.readLong(in_) != serialVersionUID) {
      throw Exception('Cannot cast');
    }
    return PluginInformation(executable, port, secret);
  }

  /// Wrapper function to simplify serialization.
  /// @return the serializer object as byte array
  Future<List<int>>? toByteArray() {
    try {
      final ByteSink out = ByteSink();
      toByteArrayStream(out);
      out.close();
      return out.bytes;
    } on Exception catch (e) {
      return null;
    }
  }

  /// Wrapper function to simplify deserialization.
  /// @param buf the buffer to be read
  /// @return the deserialized object
  static Future<PluginInformation> fromByteArray(List<int> buf) async {
    ByteStream in_ = ByteStream(null, buf);
    return fromByteArrayStream(in_);
  }

}
