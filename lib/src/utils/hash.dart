library geiger_api;

import 'package:collection/collection.dart';
import 'package:geiger_api/src/utils/hash_type.dart';
import 'package:convert/convert.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

class Hash implements Serializer {
  static const int serialVersionUID = 647930842152;
  final HashType hashType;
  final List<int> bytes;

  Hash(this.hashType, this.bytes);

  @override
  void toByteArrayStream(ByteSink out) {
    SerializerHelper.writeLong(out, serialVersionUID);
    SerializerHelper.writeString(out, hashType.name);
    out.sink.add(bytes);
    SerializerHelper.writeLong(out, serialVersionUID);
  }

  static Future<Hash> fromByteArrayStream(ByteStream in_) async {
    SerializerHelper.castTest('Hash', serialVersionUID,
        await SerializerHelper.readLong(in_), 1);

    String? typeName = await SerializerHelper.readString(in_);
    if (typeName == null) {
      throw SerializedException('Hash type not defined.');
    }

    HashType type;
    try {
      type = HashType.values.byName(typeName);
    } on ArgumentError {
      throw SerializedException('Hash type "$typeName" does not exist.');
    }

    final bytes = await in_.popArray(type.hashLength);

    SerializerHelper.castTest('Hash', serialVersionUID,
        await SerializerHelper.readLong(in_), 1);
    return Hash(type, bytes);
  }

  @override
  String toString() => hex.encode(bytes);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Hash &&
            hashType == other.hashType &&
            const ListEquality().equals(bytes, other.bytes));
  }

  @override
  int get hashCode => Object.hash(Hash, bytes);
}
