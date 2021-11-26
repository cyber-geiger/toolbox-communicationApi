library geiger_api;

import 'package:geiger_api/src/serialization/communication_serializer.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

// TODO: Maybe use quiver's DelegatingMap:
// https://pub.dev/documentation/quiver/latest/quiver.collection/DelegatingMap-class.html

/// Serializable Hashmap.
class StorableHashMap<K extends Serializer, V extends Serializer>
    with Serializer
    implements Map<K, V> {
  static const int serialVersionUID = 14231491232;

  final Map<K, V> _map = <K, V>{};

  @override
  void toByteArrayStream(ByteSink out) {
    SerializerHelper.writeLong(out, serialVersionUID);
    SerializerHelper.writeInt(out, length);
    for (MapEntry<K, V> e in entries) {
      writeObject(out, e.key);
      writeObject(out, e.value);
    }
    SerializerHelper.writeLong(out, serialVersionUID);
  }

  /// Reads objects from ByteArrayInputStream and stores them in map.
  ///
  /// @param in  ByteArrayInputStream to be used
  /// @param map Map to store objects
  /// @throws IOException if value cannot be read
  static Future<StorableHashMap> fromByteArrayStream(
      ByteStream in_, StorableHashMap map) async {
    if (await SerializerHelper.readLong(in_) != serialVersionUID) {
      throw Exception('cannot cast');
    }
    map.clear();
    int size = await SerializerHelper.readInt(in_);
    for (int i = 0; i < size; i++) {
      map[(await readObject(in_))!] = (await readObject(in_))!;
    }
    if (await SerializerHelper.readLong(in_) != serialVersionUID) {
      throw Exception('cannot cast');
    }
    return map;
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    for (MapEntry e in entries) {
      sb.write(e.key.toString());
      sb.write('=');
      sb.write(e.value);
      sb.write('\n');
    }
    return sb.toString();
  }

  @override
  V? operator [](Object? key) {
    return _map[key];
  }

  @override
  void operator []=(K key, V value) {
    _map[key] = value;
  }

  @override
  void addAll(Map<K, V> other) {
    _map.addAll(other);
  }

  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    _map.addEntries(newEntries);
  }

  @override
  Map<RK, RV> cast<RK, RV>() {
    return _map.cast<RK, RV>();
  }

  @override
  void clear() {
    _map.clear();
  }

  @override
  bool containsKey(Object? key) {
    return _map.containsKey(key);
  }

  @override
  bool containsValue(Object? value) {
    return _map.containsValue(value);
  }

  @override
  Iterable<MapEntry<K, V>> get entries {
    return _map.entries;
  }

  @override
  void forEach(void Function(K key, V value) action) {
    _map.forEach(action);
  }

  @override
  bool get isEmpty {
    return _map.isEmpty;
  }

  @override
  bool get isNotEmpty {
    return _map.isNotEmpty;
  }

  @override
  Iterable<K> get keys {
    return _map.keys;
  }

  @override
  int get length {
    return _map.length;
  }

  @override
  Map<K2, V2> map<K2, V2>(MapEntry<K2, V2> Function(K key, V value) convert) {
    return _map.map(convert);
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    return _map.putIfAbsent(key, ifAbsent);
  }

  @override
  V? remove(Object? key) {
    return _map.remove(key);
  }

  @override
  void removeWhere(bool Function(K key, V value) test) {
    return _map.removeWhere(test);
  }

  @override
  void updateAll(V Function(K key, V value) update) {
    _map.updateAll(update);
  }

  @override
  Iterable<V> get values {
    return _map.values;
  }

  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    return _map.update(key, update, ifAbsent: ifAbsent);
  }
}
