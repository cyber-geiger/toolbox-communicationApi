import 'dart:collection';

// TODO: Maybe use quiver's DelegatingMap:
// https://pub.dev/documentation/quiver/latest/quiver.collection/DelegatingMap-class.html

/// Serializable Hashmap.
class StorableHashMap<K /*extends Serializer*/, V /*extends Serializer*/ >
    extends Map<K, V> /*implements Serializer*/ {
  static final int serialVersionUID = 14231491232;

  /*void toByteArrayStream(ByteArrayOutputStream out) {
    SerializerHelper.writeLong(out, serialVersionUID);
    SerializerHelper.writeInt(out, size());
    for (Map.Entry e : entrySet()) {
    SerializerHelper.writeObject(out, e.getKey());
    SerializerHelper.writeObject(out, e.getValue());
    }
    SerializerHelper.writeLong(out, serialVersionUID);
    }

  /// Reads objects from ByteArrayInputStream and stores them in map.
  ///
  /// @param in  ByteArrayInputStream to be used
  /// @param map Map to store objects
  /// @throws IOException if value cannot be read
  static void fromByteArrayStream(ByteArrayInputStream in_,
      StorableHashMap map) {
    if (SerializerHelper.readLong(in_) != serialVersionUID) {
      throw new ClassCastException();
    }
    map.clear();
    int size = SerializerHelper.readInt(in_);
    for (int i = 0; i < size; i++) {
      map.put(
          SerializerHelper.readObject(in_), SerializerHelper.readObject(in_));
    }
    if (SerializerHelper.readLong(in_) != serialVersionUID) {
      throw new ClassCastException();
    }
  }*/

  @override
  String toString() {
    var sb = StringBuffer();
    for (MapEntry e in entries) {
      sb.write(e.key.toString());
      sb.write('=');
      sb.write(e.value);
      sb.write('\n');
    }
    return sb.toString();
  }
}
