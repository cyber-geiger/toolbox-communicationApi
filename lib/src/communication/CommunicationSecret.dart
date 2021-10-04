import 'dart:convert';
import 'dart:math';

/// <p>Encapsulates secret parameters for communication and provides methods to employ them.</p>
class CommunicationSecret /*with Serializer*/ {
  static const int serialVersionUID = 8901230;
  static const int DEFAULT_SIZE = 32;
  List<int> secret = [];

  /// <p>Creates a new secret with random content and specified size.</p>
  /// @param size the size of the secret in bytes
  CommunicationSecret.empty([int size = DEFAULT_SIZE]) {
    setRandomSecret(size);
  }

  /// <p>Creates a secret which is already known.</p>
  /// @param secret the already known secret
  CommunicationSecret(List<int>? secret) {
    if (secret == null || secret.isEmpty) {
      setRandomSecret(DEFAULT_SIZE);
    } else {
      this.secret = secret;
    }
  }

  /// <p>Gets the secret.</p>
  /// @return the current secret
  List<int> getSecret() {
    return [...secret];
  }

  /// <p>Sets a new Secret with size.</p>
  /// @param size the size of the new secret
  void setRandomSecret(int size) {
    if (size <= 0) {
      throw ArgumentError('size must be greater than 0');
    }
    secret = List.filled(size, 0);
    for (var i = 0; i < size; i++) {
      var value = Random.secure().nextInt(pow(2, 51).toInt());
      secret[i] = value;
    }
  }

  /// <p>Sets the secret.</p>
  /// If new secret is null or its length is 0 a random secret is generated
  /// @param newSecret the new secret bytes
  /// @return the previously set secret
  List<int> setSecret(List<int>? newSecret) {
    var ret = secret;
    if (newSecret == null || newSecret.isEmpty) {
      setRandomSecret(DEFAULT_SIZE);
    } else {
      secret = [...newSecret];
    }
    return ret;
  }

  /*void toByteArrayStream(ch_fhnw_geiger_totalcross_ByteArrayOutputStream out)
    {
        SerializerHelper.writeLong(out, serialVersionUID);
        SerializerHelper.writeString(out, Base64.encodeToString(secret));
        SerializerHelper.writeLong(out, serialVersionUID);
    }

    /// <p>Reads objects from ByteArrayInputStream and stores them in map.</p>
    /// @param in ByteArrayInputStream to be used
    /// @return the deserialized Storable String
    /// @throws IOException if value cannot be read
    static CommunicationSecret fromByteArrayStream(ch_fhnw_geiger_totalcross_ByteArrayInputStream in_)
    {
        if (SerializerHelper.readLong(in_) != serialVersionUID) {
            throw new ClassCastException("Reading start marker fails");
        }
        List<int> secret = Base64.decode(SerializerHelper.readString(in_));
        CommunicationSecret ret = new CommunicationSecret(secret);
        if (SerializerHelper.readLong(in_) != serialVersionUID) {
            throw new ClassCastException("Reading end marker fails");
        }
        return ret;
    }*/

  @override
  String toString() {
    return utf8.decode(secret).hashCode.toString();
  }
}
