/// <p>A serializable yet simple String object.</p>
class StorableString /*with Serializer*/ {
  static const int serialVersionUID = 142314912322198374;
  final String value;

  StorableString([this.value = '']);

  @override
  String toString() {
    return value;
  }

  @override
  bool operator ==(Object other) => equals(other);

  bool equals(Object? o) {
    if (this == o) {
      return true;
    }
    if (o == null || !(o is StorableString)) {
      return false;
    }
    StorableString? that = o;
    return value == that.value;
  }

  @override
  int get hashCode => value.hashCode;
/*
    void toByteArrayStream(ch_fhnw_geiger_totalcross_ByteArrayOutputStream out)
    {
        SerializerHelper.writeString(out, this.value);
    }

    /// <p>Reads objects from ByteArrayInputStream and stores them in map.</p>
    /// @param in ByteArrayInputStream to be used
    /// @return the deserialized Storable String
    /// @throws IOException if value cannot be read
    StorableString fromByteArrayStream(ch_fhnw_geiger_totalcross_ByteArrayInputStream in_)
    {
        return new StorableString(SerializerHelper.readString(in_));
    }*/

}
