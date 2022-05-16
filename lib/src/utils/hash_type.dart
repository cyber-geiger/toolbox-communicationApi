library geiger_api;

import 'package:cryptography/dart.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:geiger_api/src/utils/hash.dart';

enum HashType { sha512, sha1 }

extension HashTypeExtension on HashType {
  Hash hashBytes(List<int> payload) {
    crypto.Hash hash;
    switch (this) {
      case HashType.sha512:
        hash = const DartSha512().hashSync(payload);
        break;
      case HashType.sha1:
        hash = const DartSha1().hashSync(payload);
        break;
      default:
        throw UnimplementedError("Strategy '$name' not implemented.");
    }
    return Hash(this, hash.bytes);
  }

  /// Hash length in bytes.
  int get hashLength {
    switch (this) {
      case HashType.sha512:
        return 64;
      case HashType.sha1:
        return 20;
      default:
        throw UnimplementedError("Hash length for '$name' not defined.");
    }
  }
}
