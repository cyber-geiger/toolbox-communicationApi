library geiger_api;

import 'package:geiger_localstorage/geiger_localstorage.dart';

import 'geiger_api.dart';
import 'malformed_url_exception.dart';

/// GEIGER communication URL object.
class GeigerUrl implements Serializer {
  static const int serialVersionUID = 32411423;
  String _protocol = 'geiger';
  String _pluginId = GeigerApi.MASTER_ID;
  String _path = '';
  static final RegExp _urlPattern = RegExp('(.+?)://([^/]+)/(.*)');

  /// Created a [GeigerUrl] with the given [uri].
  ///
  /// Throws [MalformedUrlException] if a malformed URL was received
  GeigerUrl.fromSpec(String uri) {
    /*try {*/
    var m = _urlPattern.firstMatch(uri);
    if (m == null) {
      throw MalformedUrlException('Matcher was unable to match the string "' +
          uri +
          '" to regexp ' +
          _urlPattern.pattern);
    }
    _protocol = m[1]!;
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
  GeigerUrl(String? protocol, String pluginId, String path) {
    protocol ??= 'geiger';
    if (protocol == '') {
      throw MalformedUrlException('protocol cannot be empty');
    }
    _protocol = protocol;
    init(pluginId, path);
  }

  void init(String pluginId, String path) {
    if (pluginId == '') {
      throw MalformedUrlException('pluginId cannot be null nor empty');
    }
    if ('null' == path) {
      path = '';
    }
    _pluginId = pluginId;
    _path = path;
  }

  @override
  String toString() {
    return '$protocol://$_pluginId/$path';
  }

  /// Gets the plugin id.
  String get plugin {
    return _pluginId;
  }

  /// Gets the protocol of the URL.
  String get protocol {
    return _protocol;
  }

  /// Gets the path part of the URL.
  String get path {
    return _path;
  }

  @override
  void toByteArrayStream(ByteSink out) {
    SerializerHelper.writeLong(out, serialVersionUID);
    SerializerHelper.writeString(out, protocol);
    if (_pluginId == null) {
      SerializerHelper.writeInt(out, 0);
    } else {
      SerializerHelper.writeInt(out, 1);
      SerializerHelper.writeString(out, _pluginId);
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
  static Future<GeigerUrl> fromByteArrayStream(ByteStream in_) async {
    if (await SerializerHelper.readLong(in_) != serialVersionUID) {
      throw Exception('cannot cast');
    }
    return GeigerUrl(
        await SerializerHelper.readString(in_) ?? '',
        (await SerializerHelper.readInt(in_) == 1)
            ? await SerializerHelper.readString(in_) ?? ''
            : '',
        (await SerializerHelper.readInt(in_) == 1)
            ? await SerializerHelper.readString(in_) ?? ''
            : '');
  }

  @override
  bool operator ==(Object other) => equals(other);

  bool equals(Object? o) {
    if (identical(this, o)) {
      return true;
    }
    if (o == null || o is! GeigerUrl) {
      return false;
    }
    GeigerUrl geigerUrl = o;
    return (protocol == geigerUrl.protocol &&
            _pluginId == geigerUrl._pluginId) &&
        path == geigerUrl.path;
  }

  @override
  int get hashCode {
    return (protocol + _pluginId + path).hashCode;
  }
}
