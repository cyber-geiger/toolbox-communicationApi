import 'MalformedUrlException.dart';

import 'LocalApi.dart';

/// GEIGER communication URL object.
class GeigerUrl // with ch_fhnw_geiger_serialization_Serializer
{
  static const int serialVersionUID = 32411423;
  String protocol = 'geiger';
  String pluginId = LocalApi.MASTER;
  String path = '';
  static final RegExp urlPattern = RegExp('(.+?)://([^/]+)/(.*)');

  /// Created a [GeigerUrl] with the given [uri].
  ///
  /// Throws [MalformedUrlException] if a malformed URL was received
  GeigerUrl.fromSpec(String uri) {
    /*try {*/
    var m = urlPattern.firstMatch(uri);
    if (m == null) {
      throw MalformedUrlException('Matcher was unable to match the string \"' +
          uri +
          '\" to regexp ' +
          urlPattern.pattern);
    }
    protocol = m[1]!;
    init(m[2]!, m[3]!);
    /*} on IllegalStateException catch (e) {
      throw MalformedUrlException('Matcher was unable to match the string \"' +
          spec +
          '\" to regexp ' +
          urlPattern.pattern);
    }*/
  }

  /// Create a [GeigerUrl] with the provided [pluginId], [path], and optionally [protocol].
  ///
  /// Throws MalformedUrlException if the resulting URL is not fulfilling the minimum requirements
  GeigerUrl(String pluginId, String path, {String? protocol}) {
    if (protocol == '') {
      throw MalformedUrlException('protocol cannot be empty');
    }
    if (protocol != null) {
      this.protocol = protocol;
    }
    init(pluginId, path);
  }

  void init(String pluginId, String path) {
    if (pluginId == '') {
      throw MalformedUrlException('pluginId cannot be null nor empty');
    }
    if ('null' == path) {
      path = '';
    }
    this.pluginId = pluginId;
    this.path = path;
  }

  @override
  String toString() {
    return protocol + '://' + pluginId + '/'.codeUnitAt(0).toString() + path;
  }

  /// Gets the plugin id.
  String getPlugin() {
    return pluginId;
  }

  /// Gets the protocol of the URL.
  String getProtocol() {
    return protocol;
  }

  /// Gets the path part of the URL.
  String getPath() {
    return path;
  }

  /*
    void toByteArrayStream(ch_fhnw_geiger_totalcross_ByteArrayOutputStream out)
    {
        SerializerHelper.writeLong(out, serialVersionUID);
        if (protocol == null) {
            SerializerHelper.writeInt(out, 0);
        } else {
            SerializerHelper.writeInt(out, 1);
            SerializerHelper.writeString(out, protocol);
        }
        if (pluginId == null) {
            SerializerHelper.writeInt(out, 0);
        } else {
            SerializerHelper.writeInt(out, 1);
            SerializerHelper.writeString(out, pluginId);
        }
        if (path == null) {
            SerializerHelper.writeInt(out, 0);
        } else {
            SerializerHelper.writeInt(out, 1);
            SerializerHelper.writeString(out, path);
        }
    }

    /// Convert ByteArrayInputStream to GeigerUrl.
    /// @param in ByteArrayInputStream to read from
    /// @return the converted GeigerUrl
    /// @throws IOException if GeigerUrl cannot be read
    static GeigerUrl fromByteArrayStream(ch_fhnw_geiger_totalcross_ByteArrayInputStream in_)
    {
        if (SerializerHelper.readLong(in_) != serialVersionUID) {
            throw ClassCastException();
        }
        return GeigerUrl((SerializerHelper.readInt(in_) == 1) ? SerializerHelper.readString(in_) : null, (SerializerHelper.readInt(in_) == 1) ? SerializerHelper.readString(in_) : null, (SerializerHelper.readInt(in_) == 1) ? SerializerHelper.readString(in_) : null);
    }*/

  @override
  bool operator ==(Object other) => equals(other);

  bool equals(Object? o) {
    if (this == o) {
      return true;
    }
    if (o == null || !(o is GeigerUrl)) {
      return false;
    }
    var geigerUrl = o;
    return (protocol == geigerUrl.protocol && pluginId == geigerUrl.pluginId) &&
        path == geigerUrl.path;
  }

  @override
  int get hashCode {
    return (protocol + pluginId + path).hashCode;
  }
}
