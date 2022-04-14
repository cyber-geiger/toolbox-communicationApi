library geiger_api;

import 'package:geiger_api/src/utils/hash.dart';
import 'package:geiger_api/src/utils/hash_type.dart';

class HashAlgorithm{
  HashType hashType;
  
  HashAlgorithm(this.hashType);

  Hash hash(List<int> data){
    var strategy = hashType.strategy;
    return strategy(data);
  }
}