import 'CommunicationSecret.dart';

/// <p>Object for storing vital plugin information.</p>
class PluginInformation /*with ch_fhnw_geiger_serialization_Serializer*/ {
  static const int serialVersionUID = 48032940912340;
  final String? executable;
  final int port;
  late CommunicationSecret secret;

  /// <p>Constructor for plugin information.</p>
  /// @param executable the string required for platform specific wakeup of a plugin
  /// @param port       the port of the plugin to be contacted on
  /// @param secret     the secret required for communicating (if null a new secret is generated)
  PluginInformation(this.executable, this.port, [CommunicationSecret? secret]) {
    this.secret = secret ?? CommunicationSecret.empty();
  }

  /// <p>Gets the port of the plugin.</p>
  /// @return the port an active plugin may be reached on
  int getPort() {
    return port;
  }

  /// <p>The executable string required for starting the plugin.</p>
  /// @return the executable string
  String? getExecutable() {
    return executable;
  }

  /// <p>The communication secret required for sending securely between two instances.</p>
  /// @return the requested secret
  CommunicationSecret getSecret() {
    return secret;
  }

  /*void toByteArrayStream(ch_fhnw_geiger_totalcross_ByteArrayOutputStream out)
    {
        SerializerHelper.writeLong(out, serialVersionUID);
        SerializerHelper.writeString(out, executable);
        SerializerHelper.writeInt(out, port);
        secret.toByteArrayStream(out);
        SerializerHelper.writeLong(out, serialVersionUID);
    }

    /// <p>Reads objects from ByteArrayInputStream and stores them in map.</p>
    /// @param in ByteArrayInputStream to be used
    /// @return the deserialized Storable String
    /// @throws IOException if value cannot be read
    static PluginInformation fromByteArrayStream(ch_fhnw_geiger_totalcross_ByteArrayInputStream in_)
    {
        if (SerializerHelper.readLong(in_) != serialVersionUID) {
            throw new ClassCastException();
        }
        String executable = SerializerHelper.readString(in_);
        int port = SerializerHelper.readInt(in_);
        CommunicationSecret secret = CommunicationSecret_.fromByteArrayStream(in_);
        if (SerializerHelper.readLong(in_) != serialVersionUID) {
            throw new ClassCastException();
        }
        return new PluginInformation(executable, port, secret);
    }

    /// <p>Wrapper function to simplify serialization.</p>
    /// @return the serializer object as byte array
    List<int> toByteArray()
    {
        try {
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream out = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
            toByteArrayStream(out);
            return out.toByteArray();
        } on java_io_IOException catch (e) {
            return null;
        }
    }

    /// <p>Wrapper function to simplify deserialization.</p>
    /// @param buf the buffer to be read
    /// @return the deserialized object
    static PluginInformation fromByteArray(List<int> buf)
    {
        try {
            ch_fhnw_geiger_totalcross_ByteArrayInputStream in_ = new ch_fhnw_geiger_totalcross_ByteArrayInputStream(buf);
            return fromByteArrayStream(in_);
        } on java_io_IOException catch (ioe) {
            ioe.printStackTrace();
            return null;
        }
    }*/

  int get hashCode {
    return (executable + ':' + port.toString() + ':' + secret.toString())
        .hashCode;
  }
}
