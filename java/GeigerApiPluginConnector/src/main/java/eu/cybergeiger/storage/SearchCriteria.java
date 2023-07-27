package eu.cybergeiger.storage;

import eu.cybergeiger.serialization.Serializable;
import eu.cybergeiger.serialization.SerializerHelper;
import eu.cybergeiger.storage.node.Field;

import java.io.InputStream;
import java.io.OutputStream;
import java.io.IOException;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Map;

/**
 * <p>An object that can hold all possible search criteria.</p>
 *
 * <p>Each criteria can either be set or left blank the search will match all
 * nonempty criteria.
 * </p>
 */
public class SearchCriteria implements Serializable, Comparable<SearchCriteria> {
  private static final long serialVersionUID = 87128319541L;

  private final Map<Field, String> values = new HashMap<>();

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

  public String getNodeOwner() {
    return get(Field.OWNER);
  }

  public String setNodeOwner(String nodeOwner) {
    return set(Field.OWNER, nodeOwner);
  }

  public String getNodeName() {
    return get(Field.NAME);
  }

  public String setNodeName(String nodeName) {
    return set(Field.NAME, nodeName);
  }

  public String getNodePath() {
    return get(Field.PATH);
  }

  public String setNodePath(String nodePath) {
    return set(Field.PATH, nodePath);
  }

  public Visibility getNodeVisibility() {
    return Visibility.valueOfStandard(get(Field.VISIBILITY));
  }

  public Visibility setNodeVisibility(Visibility visibility) {
    String oldValue = set(Field.PATH, visibility.toStringStandard());
    return oldValue == null ? null : Visibility.valueOfStandard(oldValue);
  }

  public String getNodeValueKey() {
    return get(Field.KEY);
  }

  public String setNodeValueKey(String nodeValueKey) {
    return set(Field.KEY, nodeValueKey);
  }

  public String getNodeValueValue() {
    return get(Field.VALUE);

  }

  public String setNodeValueValue(String nodeValue) {
    return set(Field.OWNER, nodeValue);
  }

  public String getNodeValueType() {
    return get(Field.TYPE);
  }

  public String setNodeValueType(String nodeValueType) {
    return set(Field.OWNER, nodeValueType);
  }

  public String getNodeValueLastModified() {
    return get(Field.LASTMODIFIED);
  }

  public String setNodeValueLastModified(String nodeValueLastModified) {
    return set(Field.LASTMODIFIED, nodeValueLastModified);
  }

  public String get(Field f) {
    return values.get(f);
  }

  public String set(Field f, String value) {
    return values.put(f, value);
  }

  @Override
  public void toByteArrayStream(OutputStream out) throws IOException {
    SerializerHelper.writeMarker(out, serialVersionUID);
    SerializerHelper.writeInt(out, values.size());
    for (Map.Entry<Field, String> e : values.entrySet()) {
      SerializerHelper.writeString(out, e.getKey().toStringStandard());
      SerializerHelper.writeString(out, e.getValue());
    }
    SerializerHelper.writeMarker(out, serialVersionUID);
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
  public static SearchCriteria fromByteArrayStream(InputStream in) throws IOException {
    SerializerHelper.testMarker(in, serialVersionUID);
    SearchCriteria criteria = new SearchCriteria();
    int size = SerializerHelper.readInt(in);
    for (int i = 0; i < size; i++) {
      criteria.set(Field.valueOfStandard(SerializerHelper.readString(in)), SerializerHelper.readString(in));
    }
    SerializerHelper.testMarker(in, serialVersionUID);
    return criteria;
  }

  @Override
  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append("{").append(System.lineSeparator());
    values.keySet()
      .stream()
      .sorted(Comparator.comparing(Field::toStringStandard))
      .forEach(field -> sb
        .append("  ")
        .append(field.toStringStandard())
        .append('=')
        .append(get(field))
        .append(System.lineSeparator()));
    sb.append("}").append(System.lineSeparator());
    return sb.toString();
  }

  @Override
  public int compareTo(SearchCriteria o) {
    return toString().compareTo(o.toString());
  }

  @Override
  public boolean equals(Object o) {
    return o instanceof SearchCriteria && toString().equals(o.toString());
  }
}
