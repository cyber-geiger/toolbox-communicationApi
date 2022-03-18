library geiger_api;

import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:meta/meta.dart';

/// A serializable yet simple String object.
@immutable
class StorableString implements Serializer {
  static const int serialVersionUID = 142224912322198374;
  final String? value;

  const StorableString([this.value]);

  @override
  String toString() {
    return value ?? '';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is StorableString && value == other.value);
  }

  @override
  int get hashCode => Object.hash(StorableString, value.hashCode);

  @override
  void toByteArrayStream(ByteSink out) {
    SerializerHelper.writeLong(out, serialVersionUID);
    SerializerHelper.writeString(out, value);
  }

  static Future<StorableString> fromByteArrayStream(ByteStream in_) async {
    SerializerHelper.castTest('StorableString', serialVersionUID,
        await SerializerHelper.readLong(in_), 1);
    return StorableString(await SerializerHelper.readString(in_));
  }
}
