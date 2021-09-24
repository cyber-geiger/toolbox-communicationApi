import 'package:communicationapi/src/totalcross/MalformedUrlException.dart';
import 'package:communicationapi/src/totalcross/Matcher.dart';

/// <p>GEIGER communication URL object.</p>
class GeigerUrl // with ch_fhnw_geiger_serialization_Serializer
{
  static const int serialVersionUID = 32411423;
  String protocol = 'geiger';
  String pluginId = LocalApi.MASTER;
  String path = '';
  static final Matcher urlPattern = Matcher.compile('(.+?)://([^/]+)/(.*)');

  /// <p>GeigerUrl constructor.</p>
  /// @param spec a well formed URI
  /// @throws MalformedUrlException if a malformed URL was received
  GeigerUrl.fromSpec(String spec) {
    try {
      Matcher m = urlPattern.matcher(spec);
      if (!m.matches()) {
        throw MalformedUrlException(
            'Matcher was unable to match the string \"' +
                spec +
                '\" to regexp ' +
                urlPattern.pattern);
      }
      protocol = m.group(1);
      init(m.group(2), m.group(3));
    } on IllegalStateException catch (e) {
      throw MalformedUrlException('Matcher was unable to match the string \"' +
          spec +
          '\" to regexp ' +
          urlPattern.pattern);
    }
  }

  /// <p>Constructor to create a GEIGER url from id and path.</p>
  /// @param protocol the protocol name, may not be null nor empty
  /// @param pluginId the plugin id name, may not be null nor empty
  /// @param path     the path to call the respective function
  /// @throws MalformedUrlException if the resulting URL is not fulfilling the minimum requirements
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

  /// <p>Get the string representation of a geiger URL.</p>
  /// @return the string representation
  @override
  String toString() {
    return protocol + '://' + pluginId + '/'.codeUnitAt(0).toString() + path;
  }

  /// <p>Gets the plugin id.</p>
  /// @return the plugin id
  String getPlugin() {
    return pluginId;
  }

  /// <p>Gets the protocol of the URL.</p>
  /// @return the protocol prefix
  String getProtocol() {
    return protocol;
  }

  /// <p>Gets the path part of the URL.</p>
  /// @return the path of the URL
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

    /// <p>Convert ByteArrayInputStream to GeigerUrl.</p>
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
