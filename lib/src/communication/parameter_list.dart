library geiger_api;

import 'package:geiger_localstorage/geiger_localstorage.dart';

/// Serializable parameter list.
class ParameterList with Serializer {
  static const int serialVersionUID = 98734028931;
  List<String> args = List.empty(growable: true);

  /// Creates a [ParameterList] with the provided [args.
  ParameterList(List<String> args) {
    this.args.addAll(args);
  }

  /// Get a parameter based on its [position].
  String get(int position) {
    return args[position];
  }

  /// Gets the size of the parameter list.
  int size() {
    return args.length;
  }

  @override
  void toByteArrayStream(ByteSink out) {
    SerializerHelper.writeLong(out, serialVersionUID);
    SerializerHelper.writeInt(out, size());
    for (String s in args) {
      SerializerHelper.writeString(out, s);
    }
    SerializerHelper.writeLong(out, serialVersionUID);
  }

  /// Reads objects from ByteArrayInputStream and stores them in map.
  /// @param in ByteArrayInputStream to be used
  /// @return the ParameterList read from byte stream
  /// @throws IOException if value cannot be read
  static Future<ParameterList> fromByteArrayStream(ByteStream in_) async {
    List<String> l = <String>[];
    SerializerHelper.castTest('ParameterList', serialVersionUID,
        await SerializerHelper.readLong(in_), 1);
    int size = await SerializerHelper.readInt(in_);
    for (int i = 0; i < size; i++) {
      l.add(await SerializerHelper.readString(in_) ?? '');
    }
    SerializerHelper.castTest('ParameterList', serialVersionUID,
        await SerializerHelper.readLong(in_), 2);
    return ParameterList(l);
  }

  @override
  String toString() {
    var sb = StringBuffer();
    sb.write('['.codeUnitAt(0));
    var first = true;
    for (String p in args) {
      if (!first) {
        sb.write(',');
      } else {
        first = false;
      }
      sb.write('"');
      sb.write(p);
      sb.write('"');
    }
    sb.write(']'.codeUnitAt(0));
    return sb.toString();
  }
}
