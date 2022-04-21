library geiger_api;

import 'package:cryptography/cryptography.dart' as cryptography;
import 'package:geiger_api/src/utils/hash_type.dart';

class Hash {
  final HashType _hashType;
  final List<int> _bytes;
  final cryptography.Hash _hash;

  Hash(this._hashType, this._bytes) : _hash = cryptography.Hash(_bytes);

  List<int> get bytes => _bytes;
  HashType get hashType => _hashType;

  @override
  String toString() => _hash.toString();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Hash && _hashType == other.hashType && _hash == other._hash);
  }

  @override
  int get hashCode => Object.hash(Hash, _hash.hashCode);
}
