library geiger_api;

import 'package:cryptography/dart.dart';
import 'package:geiger_api/src/utils/hash.dart';

enum HashType {
  sha512,
  sha1
}

extension HashTypeExtension on HashType {

  Hash Function(List<int>) get strategy {
    switch(this){
      case HashType.sha512:
        return (List<int> data) => Hash(HashType.sha512, const DartSha512().hashSync(data).bytes);
      case HashType.sha1:
        return (List<int> data) => Hash(HashType.sha1, const DartSha1().hashSync(data).bytes);
      default:
         throw UnimplementedError("Strategy '" + name + "' not implemented.");
    }
  }
  

  // How many bytes the defined strategies / hashes are going to generate
  // e.g. sha512 results in 64 bytes of data
  int get hashLength {
    switch(this){
      case HashType.sha512:
          return 64;
      case HashType.sha1:
          return 20;
      default:
          throw UnimplementedError("Hash length for '" + name + "' not defined.");
    }
  }


}