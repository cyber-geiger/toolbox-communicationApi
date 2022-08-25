package eu.cybergeiger.api.utils;

import eu.cybergeiger.serialization.Serializable;
import eu.cybergeiger.serialization.SerializerHelper;

import java.io.InputStream;
import java.io.OutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/**
 * Serializable Hashmap.
 *
 * @param <K> Keytype
 * @param <V> Valuetype
 */
public class StorableHashMap<K extends Serializable, V extends Serializable>
  extends HashMap<K, V> implements Serializable {

  private static final long serialVersionUID = 14231491232L;

  @Override
  public void toByteArrayStream(OutputStream out) throws IOException {
    SerializerHelper.writeLong(out, serialVersionUID);
    SerializerHelper.writeInt(out, size());
    for (Map.Entry<?, ?> e : entrySet()) {
      SerializerHelper.writeObject(out, e.getKey());
      SerializerHelper.writeObject(out, e.getValue());
    }
    SerializerHelper.writeLong(out, serialVersionUID);
  }

  /**
   * <p>Reads objects from InputStream and stores them in map.</p>
   *
   * @param in  InputStream to be used
   * @param map Map to store objects
   * @throws IOException if value cannot be read
   */
  public static void fromByteArrayStream(InputStream in, StorableHashMap map)
    throws IOException {
    if (SerializerHelper.readLong(in) != serialVersionUID) {
      throw new ClassCastException();
    }
    map.clear();
    int size = SerializerHelper.readInt(in);
    for (int i = 0; i < size; i++) {
      map.put(SerializerHelper.readObject(in), SerializerHelper.readObject(in));
    }
    if (SerializerHelper.readLong(in) != serialVersionUID) {
      throw new ClassCastException();
    }
  }

  @Override
  public String toString() {
    StringBuilder sb = new StringBuilder();
    for (Map.Entry e : entrySet()) {
      sb.append(e.getKey().toString()).append('=').append(e.getValue())
        .append(System.lineSeparator());
    }
    return sb.toString();
  }
}



