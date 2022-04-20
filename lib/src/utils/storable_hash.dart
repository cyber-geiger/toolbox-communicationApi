
library geiger_api;
import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

class StorableHash implements Serializer {

  static const int serialVersionUID = 647930842152;
  final Hash _hash;

  StorableHash(this._hash);

  Hash get hash => _hash;

  @override
  void toByteArrayStream(ByteSink out) {
    HashAlgorithm algo = HashAlgorithm(_hash.hashType);
    Hash hash = algo.hash(_hash.bytes);
    SerializerHelper.writeLong(out, serialVersionUID);
    SerializerHelper.writeString(out, hash.hashType.name);
    out.sink.add(hash.bytes);
    SerializerHelper.writeLong(out, serialVersionUID);
  }

  static Future<StorableHash> fromByteArrayStream(ByteStream in_) async {
    SerializerHelper.castTest('StorableHash', serialVersionUID,
        await SerializerHelper.readLong(in_), 1);

    String? type = await SerializerHelper.readString(in_);
    if(type == null){
      throw CommunicationException("Hash type not serialized");
    }
    
    HashType hashType;
    try {
      hashType = HashType.values.byName(type);
    } on ArgumentError {
      throw CommunicationException('Hash type is not defined / does not exist.');
    }

    Hash hash = Hash(hashType, await in_.popArray(hashType.hashLength));

    SerializerHelper.castTest('StorableHash', serialVersionUID,
        await SerializerHelper.readLong(in_), 1);
    return StorableHash(hash);
  }

  @override
  String toString() => _hash.toString();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is StorableHash && _hash == other.hash);
  }

  @override
  int get hashCode => Object.hash(StorableHash, hash.hashCode);
}