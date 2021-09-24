
import 'java.dart';
/// <p>Serializable parameter list.</p>
class ParameterList with ch_fhnw_geiger_serialization_Serializer
{
    static const int serialVersionUID = 98734028931;
    java_util_List<String> args = new java_util_Vector();
    /// <p>Serializable list of strings as parameter map.</p>
    /// @param args The parameters to be added
    ParameterList(List<String> args /*XXX*/)
    {
        this.args.addAll(Arrays.asList(args));
    }

    /// <p>Serializable list of strings as parameter map.</p>
    /// @param args The parameters to be added
    ParameterList(java_util_List<String> args)
    {
        this.args.addAll(args);
    }

    /// <p>Get a parameter based on its position.</p>
    /// @param pos the position of the parameter in the list
    /// @return the requested parameter
    String get(int pos)
    {
        return args.get(pos);
    }

    /// <p>Gets the size of the parameter list.</p>
    /// @return the number of parameters in the list
    int size()
    {
        return args.size();
    }

    void toByteArrayStream(ch_fhnw_geiger_totalcross_ByteArrayOutputStream out)
    {
        SerializerHelper.writeLong(out, serialVersionUID);
        SerializerHelper.writeInt(out, size());
        for (String s in args) {
            SerializerHelper.writeString(out, s);
        }
        SerializerHelper.writeLong(out, serialVersionUID);
    }

    /// <p>Reads objects from ByteArrayInputStream and stores them in map.</p>
    /// @param in ByteArrayInputStream to be used
    /// @return the ParameterList read from byte stream
    /// @throws IOException if value cannot be read
    static ParameterList fromByteArrayStream(ch_fhnw_geiger_totalcross_ByteArrayInputStream in_)
    {
        java_util_List<String> l = new java_util_Vector();
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
    }

    String toString()
    {
        StringBuilder sb = new StringBuilder();
        sb.append('['.codeUnitAt(0));
        bool first = true;
        for (String p in args) {
            if (!first) {
                sb.append(','.codeUnitAt(0));
            } else {
                first = false;
            }
            if (p == null) {
                sb.append("null");
            } else {
                sb.append('"'.codeUnitAt(0)).append(p).append('"'.codeUnitAt(0));
            }
        }
        sb.append(']'.codeUnitAt(0));
        return sb.toString();
    }

}
