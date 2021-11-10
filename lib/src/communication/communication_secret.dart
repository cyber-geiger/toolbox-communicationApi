library geiger_api;

import 'dart:convert';
import 'dart:math';

import 'package:geiger_localstorage/geiger_localstorage.dart';

/// Encapsulates secret parameters for communication and provides methods to employ them.
class CommunicationSecret with Serializer {
  static const int serialVersionUID = 8901230;
  static const int DEFAULT_SIZE = 32;
  List<int> secret = [];

  /// Creates a new secret with random content and specified [size] in bytes.
  CommunicationSecret.empty([int size = DEFAULT_SIZE]) {
    setRandomSecret(size);
  }

  /// Wraps an existing [secret].
  CommunicationSecret(List<int>? secret) {
    if (secret == null || secret.isEmpty) {
      setRandomSecret(DEFAULT_SIZE);
    } else {
      this.secret = secret;
    }
  }

  /// Gets the secret.
  List<int> getSecret() {
    return [...secret];
  }

  /// Sets a new Secret with the given [size] in bytes.
  void setRandomSecret(int size) {
    if (size <= 0) {
      throw ArgumentError('size must be greater than 0');
    }
    secret = List.filled(size, 0);
    for (var i = 0; i < size; i++) {
      secret[i] = Random.secure().nextInt(256);
    }
  }

  /// Sets the secret to [newSecret].
  ///
  /// If new secret is `null` or its length is `0` a random secret is generated.
  /// Returns the previously set secret.
  List<int> setSecret(List<int>? newSecret) {
    var ret = secret;
    if (newSecret == null || newSecret.isEmpty) {
      setRandomSecret(DEFAULT_SIZE);
    } else {
      secret = [...newSecret];
    }
    return ret;
  }

  @override
  void toByteArrayStream(ByteSink out) {
    SerializerHelper.writeLong(out, serialVersionUID);
    SerializerHelper.writeString(out, base64.encode(secret));
    SerializerHelper.writeLong(out, serialVersionUID);
  }

  /// Reads objects from ByteArrayInputStream and stores them in map.
  /// @param in ByteArrayInputStream to be used
  /// @return the deserialized Storable String
  /// @throws IOException if value cannot be read
  static Future<CommunicationSecret> fromByteArrayStream(ByteStream in_) async {
    if (await SerializerHelper.readLong(in_) != serialVersionUID) {
      throw Exception('cannot cast');
    }
    final List<int> secret =
        base64.decode(await SerializerHelper.readString(in_) ?? '');
    CommunicationSecret ret = CommunicationSecret(secret);
    if (await SerializerHelper.readLong(in_) != serialVersionUID) {
      throw Exception('Reading end marker fails');
    }
    return ret;
  }

  @override
  String toString() {
    return utf8.decode(secret).hashCode.toString();
  }
}
