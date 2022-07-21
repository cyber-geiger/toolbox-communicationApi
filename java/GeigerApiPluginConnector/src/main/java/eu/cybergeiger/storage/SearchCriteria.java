package eu.cybergeiger.storage;

import eu.cybergeiger.serialization.Serializable;
import eu.cybergeiger.serialization.SerializerHelper;
import eu.cybergeiger.storage.node.Field;
import eu.cybergeiger.storage.node.Node;
import eu.cybergeiger.storage.node.value.NodeValue;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;

/**
 * <p>An object that can hold all possible search criteria.</p>
 *
 * <p>Each criteria can either be set or left blank the search will match all
 * nonempty criteria.
 * </p>
 */
public class SearchCriteria implements Serializable, Comparable<SearchCriteria> {

  private static final long serialVersionUID = 87128319541L;

  /**
   * <p>Defines the type of comparator to be used when accessing an ordinal.</p>
   */
  public enum ComparatorType {
    STRING,
    DATETIME,
    BOOLEAN
  }

  public SearchCriteria() {
  }

  /**
   * <p>Create a Searchcriteria.</p>
   *
   * @param path  the path to search for
   * @param key   the key to search for
   * @param value the value to search for
   */
  public SearchCriteria(String path, String key, String value) {
    setNodePath(path);
    setNodeValueKey(key);
    if (value != null && !"%".equals(value)) {
      setNodeValueValue(value);
    }
  }

  private final Map<Field, String> values = new HashMap<>();

  public String getNodeOwner() {
    return values.get(Field.OWNER);
  }

  public String setNodeOwner(String nodeOwner) {
    return values.put(Field.OWNER, nodeOwner);
  }

  public String getNodeName() {
    return values.get(Field.NAME);
  }

  public String setNodeName(String nodeName) {
    return values.put(Field.NAME, nodeName);
  }

  public String getNodePath() {
    return values.get(Field.PATH);
  }

  public String setNodePath(String nodePath) {
    return values.put(Field.PATH, nodePath);
  }

  public String getNodeValueKey() {
    return values.get(Field.KEY);
  }

  public String setNodeValueKey(String nodeValueKey) {
    return values.put(Field.KEY, nodeValueKey);
  }

  public String getNodeValueValue() {
    return values.get(Field.VALUE);

  }

  public String setNodeValueValue(String nodeValue) {
    return values.put(Field.OWNER, nodeValue);
  }

  public String getNodeValueType() {
    return values.get(Field.TYPE);
  }

  public String setNodeValueType(String nodeValueType) {
    return values.put(Field.OWNER, nodeValueType);
  }

  public String get(Field f) {
    return values.get(f);
  }

  public String set(Field f, String value) {
    return values.put(f, value);
  }

  public String getNodeValueLastModified() {
    return values.get(Field.LASTMODIFIED);
  }

  public String setNodeValueLastModified(String nodeValueLastModified) {
    return values.put(Field.LASTMODIFIED, nodeValueLastModified);
  }

  /**
   * <p>Evaluates a provided node against this criteria.</p>
   *
   * @param node the node to be evaluated
   * @return true iif the node matches the criteria
   * @throws StorageException if the storage backend encounters a problem
   */
  public boolean evaluate(Node node) throws StorageException {
    // evaluate node criteria
    // node path is a sub tree search
    if (!node.getPath().startsWith(getNodePath())) {
      return false;
    }
    // compare other ordinals
    if (values.get(Field.OWNER) != null
      && !regexEvalString(values.get(Field.OWNER), node.getOwner())) {
      return false;
    }
    if (values.get(Field.VISIBILITY) != null
      && !regexEvalString(values.get(Field.VISIBILITY), node.getVisibility().toStringStandard())) {
      return false;
    }
    // getting values to check
    Map<String, NodeValue> nodeValues = node.getValues();

    // evaluate key, type and value criteria
    if (values.get(Field.KEY) == null && (values.get(Field.VALUE) != null
      || values.get(Field.TYPE) != null)) {
      // key is not set but other values are so we find a matching value
      for (Map.Entry<String, NodeValue> e : nodeValues.entrySet()) {
        boolean r3 = values.get(Field.TYPE) == null || values.get(Field.TYPE) != null
          && !regexEvalString(values.get(Field.TYPE), e.getValue().getType());
        boolean r2 = values.get(Field.VALUE) == null || values.get(Field.VALUE) != null
          && !regexEvalString(values.get(Field.VALUE), e.getValue().getValue());
        if (r2 && r3) {
          return true;
        }
      }
      return false;
    } else if (values.get(Field.KEY) != null) {
      // key is set; we just compare an eventual value
      NodeValue nv = nodeValues.get(get(Field.KEY));
      if (nv == null) {
        return false;
      }
      if (!regexEvalString(values.get(Field.TYPE), nv.getType())) {
        return false;
      }
      if (!regexEvalString(values.get(Field.VALUE), nv.getValue())) {
        return false;
      }
    }
    return true;
  }

  private boolean regexEvalString(String regex, String value) {
    if (regex == null) {
      return true;
    }
    return regex.matches(value);
  }

  @Override
  public void toByteArrayStream(ByteArrayOutputStream out) throws IOException {
    // write object identifier
    SerializerHelper.writeLong(out, serialVersionUID);

    // serializing values
    SerializerHelper.writeInt(out, values.size());
    for (Map.Entry<Field, String> e : values.entrySet()) {
      SerializerHelper.writeString(out, e.getKey().name());
      SerializerHelper.writeString(out, e.getValue());
    }

    // write object identifier (end)
    SerializerHelper.writeLong(out, serialVersionUID);
  }

  /**
   * <p>Static deserializer.</p>
   *
   * <p>creates  a search criteria from a ByteArrayStream</p>
   *
   * @param in The input byte stream to be used
   * @return the object parsed from the input stream by the respective class
   * @throws IOException if not overridden or reached unexpectedly the end of stream
   */
  public static SearchCriteria fromByteArrayStream(ByteArrayInputStream in) throws IOException {
    if (SerializerHelper.readLong(in) != serialVersionUID) {
      throw new IOException("failed to parse StorageException (bad stream?)");
    }

    SearchCriteria s = new SearchCriteria();

    int size = SerializerHelper.readInt(in);
    for (int i = 0; i < size; i++) {
      s.values.put(Field.valueOf(SerializerHelper.readString(in)), SerializerHelper.readString(in));
    }

    if (SerializerHelper.readLong(in) != serialVersionUID) {
      throw new IOException("failed to parse StorageException (bad stream end?)");
    }
    return s;
  }

  @Override
  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append("{").append(System.lineSeparator());
    Set<String> tmp = new TreeSet<>();
    for (Field f : values.keySet()) {
      tmp.add(f.toString());
    }
    for (String f : new TreeSet<>(tmp)) {
      sb.append("  ").append(f).append('=').append(values.get(Field.valueOf(f)))
        .append(System.lineSeparator());
    }
    sb.append("}").append(System.lineSeparator());
    return sb.toString();
  }

  /**
   * <p>Wrapper function to simplify serialization.</p>
   *
   * @return the serializer object as byte array
   */
  public byte[] toByteArray() {
    try {
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      toByteArrayStream(out);
      return out.toByteArray();
    } catch (IOException e) {
      return null;
    }
  }

  /**
   * <p>Wrapper function to simplify deserialization.</p>
   *
   * @param buf the buffer to be read
   * @return the deserialized object
   */
  public static SearchCriteria fromByteArray(byte[] buf) {
    return (SearchCriteria) (fromByteArrayInt(buf));
  }

  private static Serializable fromByteArrayInt(byte[] buf) {
    try {
      ByteArrayInputStream in = new ByteArrayInputStream(buf);
      return fromByteArrayStream(in);
    } catch (IOException ioe) {
      ioe.printStackTrace();
      return null;
    }
  }

  @Override
  public int compareTo(SearchCriteria o) {
    return toString().compareTo(o.toString());
  }

  @Override
  public boolean equals(Object o) {
    if (!(o instanceof SearchCriteria)) {
      return false;
    }
    return toString().equals(o.toString());
  }

}
