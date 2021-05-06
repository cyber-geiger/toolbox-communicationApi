package eu.cybergeiger.communication;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/**
 * Serializable Hashmap.
 *
 * @param <K> Keytype
 * @param <V> Valuetype
 */
public class StorableHashMap<K extends Serializer, V extends Serializer>
    extends HashMap<K, V> implements Serializer {

  private static final long serialVersionUID = 14231491232L;

  @Override
  public void toByteArrayStream(ByteArrayOutputStream out) throws IOException {
    SerializerHelper.writeLong(out, serialVersionUID);
    SerializerHelper.writeInt(out, size());
    for (Map.Entry e : entrySet()) {
      writeObject(out, e.getKey());
      writeObject(out, e.getValue());
    }
  }

  private void writeObject(ByteArrayOutputStream out, Object o) throws IOException {
    if (o instanceof String) {
      SerializerHelper.writeString(out, (String) o);
    } else if (o.getClass().isAssignableFrom(Serializer.class)) {
      ((Serializer) (o)).toByteArrayStream(out);
    } else {
      throw new ClassCastException();
    }
  }

  /**
   * <p>Reads objects from ByteArrayInputStream and stores them in map.</p>
   *
   * @param in ByteArrayInputStream to be used
   * @param map Map to store objects
   * @throws IOException if value cannot be read
   */
  public static void fromByteArrayStream(ByteArrayInputStream in, StorableHashMap map)
      throws IOException {
    synchronized (map) {
      map.clear();
      int size = SerializerHelper.readInt(in);
      for (int i = 0; i < size; i++) {
        map.put(SerializerHelper.readObject(in), SerializerHelper.readObject(in));
      }
    }
  }


}
