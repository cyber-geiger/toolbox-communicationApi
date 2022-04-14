library geiger_api;

import 'package:cryptography/cryptography.dart' as cryptography;
import 'package:geiger_api/src/utils/hash_type.dart';


class Hash {
  final HashType _hashType;
  final List<int> _bytes;
  final cryptography.Hash hash;

  Hash(this._hashType, this._bytes): hash = cryptography.Hash(_bytes);

  List<int> get bytes => _bytes;
  HashType get hashType => _hashType;

  @override
  String toString() => hash.toString();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Hash && hash == other.hash);
  }

  @override
  int get hashCode => Object.hash(Hash, hash.hashCode);
}