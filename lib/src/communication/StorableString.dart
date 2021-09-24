
import 'java.dart';
/// <p>A serializable yet simple String object.</p>
class StorableString with ch_fhnw_geiger_serialization_Serializer
{
    static const int serialVersionUID = 142314912322198374;
    final String value;
    StorableString()
    {
        value = "";
    }

    StorableString(String value)
    {
        this.value = value;
    }

    String toString()
    {
        return value;
    }

    bool equals(Object o)
    {
        if (this == o) {
            return true;
        }
        if ((o == null) || (getClass() != o.getClass())) {
            return false;
        }
        StorableString that = o;
        return ((value == null) && (that.value == null)) || ((value != null) && (value == that.value));
    }

    int hashCode()
    {
        return value.hashCode();
    }

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
    }

}
