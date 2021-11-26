library geiger_api;

import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:meta/meta.dart';

/// A serializable yet simple String object.
@immutable
class StorableString implements Serializer {
  static const int serialVersionUID = 142314912322198374;
  final String? _value;

  const StorableString([this._value]);

  String? value() {
    return _value;
  }

  @override
  String toString() {
    return _value ?? '';
  }

  @override
  bool operator ==(Object other) => equals(other);

  bool equals(Object? o) {
    if (identical(this, o)) {
      return true;
    }
    if (o == null || o is! StorableString) {
      return false;
    }
    StorableString? that = o;
    return _value == that._value;
  }

  @override
  int get hashCode => _value.hashCode;

  @override
  void toByteArrayStream(ByteSink out) {
    SerializerHelper.writeString(out, _value);
  }

  /// Reads objects from ByteArrayInputStream and stores them in map.
  /// @param in ByteArrayInputStream to be used
  /// @return the deserialized Storable String
  /// @throws IOException if value cannot be read
  static Future<StorableString> fromByteArrayStream(ByteStream in_) async {
    return StorableString(await SerializerHelper.readString(in_));
  }
}
