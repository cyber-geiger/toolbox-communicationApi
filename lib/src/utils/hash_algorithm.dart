library geiger_api;

import 'dart:convert';

import 'package:geiger_api/src/utils/hash.dart';
import 'package:geiger_api/src/utils/hash_type.dart';

class HashAlgorithm{
  HashType hashType;

  HashAlgorithm(this.hashType);

  Hash hash(List<int> data){
    Function strategy = hashType.strategy;
    return strategy(data);
  }

  Hash hashString(String data){
    Function strategy = hashType.strategy;
    List<int> bytes = utf8.encode(data);
    return strategy(bytes);
  }
}