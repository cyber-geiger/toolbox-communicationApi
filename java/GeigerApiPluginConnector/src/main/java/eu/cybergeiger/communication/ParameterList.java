package eu.cybergeiger.communication;

import ch.fhnw.geiger.serialization.Serializer;
import ch.fhnw.geiger.serialization.SerializerHelper;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;
import java.util.Vector;

/**
 * <p>Serializable parameter list.</p>
 */
public class ParameterList implements Serializer {

  private static final long serialVersionUID = 98734028931L;

  List<String> args = new Vector<>();

  /**
   * <p>Serializable list of strings as parameter map.</p>
   *
   * @param args The parameters to be added
   */
  public ParameterList(String... args) {
    this.args.addAll(Arrays.asList(args));
  }

  /**
   * <p>Serializable list of strings as parameter map.</p>
   *
   * @param args The parameters to be added
   */
  public ParameterList(List<String> args) {
    this.args.addAll(args);
  }

  /**
   * <p>Get a parameter based on its position.</p>
   *
   * @param pos the position of the parameter in the list
   * @return the requested parameter
   */
  public String get(int pos) {
    return args.get(pos);
  }

  /**
   * <p>Gets the size of the parameter list.</p>
   *
   * @return the number of parameters in the list
   */
  public int size() {
    return args.size();
  }

  @Override
  public void toByteArrayStream(ByteArrayOutputStream out) throws IOException {
    SerializerHelper.writeLong(out, serialVersionUID);

    SerializerHelper.writeInt(out, size());

    for (String s : args) {
      SerializerHelper.writeString(out, s);
    }

    SerializerHelper.writeLong(out, serialVersionUID);
  }

  /**
   * <p>Reads objects from ByteArrayInputStream and stores them in map.</p>
   *
   * @param in ByteArrayInputStream to be used
   * @return the ParameterList read from byte stream
   * @throws IOException if value cannot be read
   */
  public static ParameterList fromByteArrayStream(ByteArrayInputStream in) throws IOException {
    List<String> l = new Vector<>();

    if (SerializerHelper.readLong(in) != serialVersionUID) {
      throw new ClassCastException();
    }

    // reading size
    int size = SerializerHelper.readInt(in);

    // reading parameter list elements
    for (int i = 0; i < size; i++) {
      l.add(SerializerHelper.readString(in));
    }

    // reading end of list marker
    if (SerializerHelper.readLong(in) != serialVersionUID) {
      throw new ClassCastException();
    }

    return new ParameterList(l);
  }

  @Override
  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append('[');
    boolean first = true;
    for (String p : args) {
      if (!first) {
        sb.append(',');
      } else {
        first = false;
      }
      if (p == null) {
        sb.append("null");
      } else {
        sb.append('"').append(p).append('"');
      }
    }
    sb.append(']');
    return sb.toString();
  }
}
