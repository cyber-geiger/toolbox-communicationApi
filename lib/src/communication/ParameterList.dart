/// Serializable parameter list.
class ParameterList /*with Serializer*/ {
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

  /*void toByteArrayStream(ch_fhnw_geiger_totalcross_ByteArrayOutputStream out)
    {
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
    static ParameterList fromByteArrayStream(ch_fhnw_geiger_totalcross_ByteArrayInputStream in_)
    {
        List<String> l = new java_util_Vector();
        if (SerializerHelper.readLong(in_) != serialVersionUID) {
            throw new ClassCastException();
        }
        int size = SerializerHelper.readInt(in_);
        for (int i = 0; i < size; i++) {
            l.add(SerializerHelper.readString(in_));
        }
        if (SerializerHelper.readLong(in_) != serialVersionUID) {
            throw new ClassCastException();
        }
        return new ParameterList(l);
    }*/

  @override
  String toString() {
    var sb = StringBuffer();
    sb.write('['.codeUnitAt(0));
    var first = true;
    for (var p in args) {
      if (!first) {
        sb.write(',');
      } else {
        first = false;
      }
      if (p == null) {
        sb.write('null');
      } else {
        sb.write('"');
        sb.write(p);
        sb.write('"');
      }
    }
    sb.write(']'.codeUnitAt(0));
    return sb.toString();
  }
}
