package eu.cybergeiger.storage.node;

import eu.cybergeiger.serialization.SerializerHelper;
import eu.cybergeiger.storage.StorageController;
import eu.cybergeiger.storage.StorageException;
import eu.cybergeiger.storage.Visibility;
import eu.cybergeiger.storage.node.value.DefaultNodeValue;
import eu.cybergeiger.storage.node.value.NodeValue;
import eu.cybergeiger.storage.utils.SwitchableBoolean;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

/**
 * <p>The implementation of the node interface.</p>
 *
 * <p>This Class denotes one node containing sub-nodes in a tree-like structure. Each node may have
 * n children. Each node may be a skeleton-only node (contains only name and a reference to a
 * mapper), or may be materialized (contains all data). Typically when fetching a node, the node
 * is materialized but its sub-nodes are skeleton-only nodes. All skeleton nodes materialize
 * automatically if their data is accessed.</p>
 */
public class DefaultNode implements Node {
  private static final long serialVersionUID = 11239348938L;

  /* an indicator whether the current object is a skeleton */
  private final SwitchableBoolean skeleton = new SwitchableBoolean(false);

  /* Contains the mapper for a skeleton to fetch any subsequent  data */
  private StorageController controller = null;

  /* contains the ordinals of a node */
  private final Map<Field, String> ordinals = new HashMap<>();

  /* contains the key/value pairs of a node */
  private final Map<String, NodeValue> values = new HashMap<>();

  /* Holds all child nodes as tuples, where the name is used as a key and
     the value is of type StorageNode */
  // TODO concurrency
  private final Map<String, Node> childNodes = new HashMap<>();

  /**
   * <p>Constructor creating a skeleton node.</p>
   *
   * @param path       the path of the node
   * @param controller the controller to fetch the full node
   */
  public DefaultNode(String path, String owner, StorageController controller) throws StorageException {
    skeleton.set(true);
    setOwner(owner);
    try {
      set(Field.PATH, path);
    } catch (StorageException e) {
      throw new RuntimeException("Oops.... this should not happen... contact developer", e);
    }
    this.controller = controller;
  }

  private DefaultNode(Node node) throws StorageException {
    this(node.getPath(), node.getOwner());
    update(node);
  }

  /**
   * <p>create a empty node for the given path.</p>
   *
   * @param path the node path
   */
  public DefaultNode(String path, String owner) throws StorageException {
    this(getNameFromPath(path), owner, getParentFromPath(path));
  }

  /**
   * <p>Create a node with the given name and parent path.</p>
   *
   * @param name   name of the node
   * @param parent fully qualified parent name (path without name)
   */
  public DefaultNode(String name, String owner, String parent) throws StorageException {
    this(name, owner, parent, Visibility.RED);
  }

  /**
   * <p>creates a fully fledged new empty node.</p>
   *
   * @param name   the name for the node
   * @param parent the parent of the node (may be null if root node is the parent)
   * @param vis    visibility of the node
   */
  public DefaultNode(String name, String owner, String parent, Visibility vis) throws StorageException {
    if (parent == null) parent = "";
    setOwner(owner);
    try {
      set(Field.PATH, parent + StorageController.PATH_DELIMITER + name);
      set(Field.VISIBILITY, vis.toStringStandard());
    } catch (StorageException e) {
      throw new RuntimeException("Oops.... this should not happen... contact developer", e);
    }
    this.skeleton.set(false);
  }

  /**
   * <p>creates a fully fledged new empty node.</p>
   *
   * @param path        the path of  the node
   * @param isTombstone true if the node is a tombstone node
   */
  public DefaultNode(String path, String owner, boolean isTombstone) throws StorageException {
    this(path, owner);
    set(Field.TOMBSTONE, isTombstone ? "true" : "false");
  }

  /**
   * <p>create a fully fledged standard node.</p>
   *
   * @param path       the node path
   * @param visibility the visbility of the node or null if default
   * @param nodeValues the node values to be stored or null if none
   * @param childNodes the child nodes to be included or null if none
   */
  public DefaultNode(String path, String owner, Visibility visibility, NodeValue[] nodeValues, Node[] childNodes) throws StorageException {
    this(path, owner);
    if (visibility != null) {
      setVisibility(visibility);
    }
    if (nodeValues != null) {
      for (NodeValue nv : nodeValues) {
        addValue(nv);
      }
    }
    if (childNodes != null) {
      for (Node n : childNodes) {
        this.childNodes.put(n.getName(), n);
      }
    }
  }

  /**
   * <p>Converts current node into a materialized node from a skeleton.</p>
   */
  private void init() throws StorageException {
    synchronized (skeleton) {
      if (skeleton.get()) {
        update(controller.get(getPath()));
        skeleton.set(false);
        controller = null;
      }
    }
  }

  /**
   * <p>Returns the name part from a fully qualified node path.</p>
   *
   * @param path the fully qualified path of which the name is extracted
   * @return the name part of the path
   */
  public static String getNameFromPath(String path) {
    if (path == null) {
      return null;
    }
    return path.substring(path.lastIndexOf(StorageController.PATH_DELIMITER) + 1);
  }

  /**
   * <p>Returns the fully qualified node path of the parental node.</p>
   *
   * @param path the fully qualified path of which the parental node is extracted
   * @return the fully qualified path to the parental node
   */
  public static String getParentFromPath(String path) {
    if (path == null) {
      return null;
    }
    if (!path.contains(StorageController.PATH_DELIMITER)) {
      return "";
    }
    return path.substring(0, path.lastIndexOf(StorageController.PATH_DELIMITER));
  }

  @Override
  public NodeValue getValue(String key) throws StorageException {
    init();
    synchronized (values) {
      NodeValue value = values.get(key);
      if (value == null) return null;
      return value.deepClone();
    }
  }

  @Override
  public NodeValue updateValue(NodeValue value) throws StorageException {
    init();
    NodeValue ret = getValue(value.getKey());
    if (ret == null) {
      throw new StorageException("Value " + value.getKey() + " not found in node " + getName());
    }
    synchronized (values) {
      value.touch();
      setLastModified(value.getLastModified());
      values.put(value.getKey(), value);
    }
    return ret;
  }

  @Override
  public void addValue(NodeValue value) throws StorageException {
    init();
    if (getValue(value.getKey()) != null) {
      throw new StorageException("value does already exist");
    }
    synchronized (values) {
      value.touch();
      setLastModified(value.getLastModified());
      values.put(value.getKey(), value);
    }
  }

  @Override
  public NodeValue removeValue(String key) throws StorageException {
    init();
    synchronized (values) {
      touch();
      return values.remove(key);
    }
  }

  @Override
  public void addChild(Node node) throws StorageException {
    init();
    synchronized (childNodes) {
      if (!childNodes.containsKey(node.getName())) {
        childNodes.put(node.getName(), node);
      }
    }
  }

  @Override
  public String getOwner() {
    try {
      return get(Field.OWNER);
    } catch (StorageException e) {
      throw new RuntimeException("Oops.... this should not happen... contact developer", e);
    }
  }

  @Override
  public String setOwner(String newOwner) throws StorageException {
    if (newOwner == null) {
      throw new NullPointerException();
    }
    if (newOwner.contains(":")) {
      throw new StorageException("Owner may not contain \":\" character.");
    }
    try {
      return set(Field.OWNER, newOwner);
    } catch (StorageException e) {
      throw new RuntimeException("Oops.... this should not happen... contact developer", e);
    }
  }

  @Override
  public String getName() {
    try {
      return getNameFromPath(get(Field.PATH));
    } catch (StorageException e) {
      throw new RuntimeException("Oops.... this should not happen... contact developer", e);
    }
  }

  @Override
  public String getParentPath() {
    try {
      return getParentFromPath(get(Field.PATH));
    } catch (StorageException e) {
      throw new RuntimeException("Oops.... this should not happen... contact developer", e);
    }
  }

  @Override
  public String getPath() {
    try {
      return get(Field.PATH);
    } catch (StorageException e) {
      throw new RuntimeException("Oops.... this should not happen... contact developer", e);
    }
  }

  @Override
  public Visibility getVisibility() {
    try {
      return Visibility.valueOfStandard(get(Field.VISIBILITY));
    } catch (StorageException e) {
      throw new RuntimeException("Oops.... this should not happen... contact developer", e);
    }
  }

  @Override
  public Visibility setVisibility(Visibility newVisibility) {
    try {
      return Visibility.valueOfStandard(set(Field.VISIBILITY, newVisibility.toStringStandard()));
    } catch (StorageException e) {
      throw new RuntimeException("Oops.... this should not happen... contact developer", e);
    }
  }

  @Override
  public Map<String, NodeValue> getValues() {
    return new HashMap<>(values);
  }

  /**
   * <p>Gets an ordinal field of the node.</p>
   *
   * @param field the ordinal field to get
   * @return the currently set value
   * @throws StorageException if a field does not exist
   */
  private String get(Field field) throws StorageException {
    synchronized (skeleton) {
      if (field != Field.PATH && field != Field.NAME && field != Field.TOMBSTONE) {
        init();
      }
    }
    switch (field) {
      case OWNER:
      case PATH:
      case VISIBILITY:
      case LASTMODIFIED:
      case EXPIRY:
      case TOMBSTONE:
        return ordinals.get(field);
      case NAME:
        return getNameFromPath(ordinals.get(Field.PATH));
      default:
        throw new StorageException("unable to fetch field " + field);
    }
  }

  /**
   * <p>Sets an ordinal field of the node.</p>
   *
   * @param field the ordinal field to be set
   * @param value the new value
   * @return the previously set value
   * @throws StorageException if a field does not exist
   */
  private String set(Field field, String value) throws StorageException {
    // materialize node if required
    synchronized (skeleton) {
      if (field != Field.PATH) {
        init();
      }
    }

    // Update last modified if needed
    String current = ordinals.get(field);
    if (field != Field.LASTMODIFIED
      && ((current != null && !current.equals(value))
      || (current == null && value != null))) {
      touch();
    }

    // return appropriate value
    switch (field) {
      case OWNER:
      case PATH:
      case VISIBILITY:
      case LASTMODIFIED:
      case EXPIRY:
        return ordinals.put(field, value);
      case TOMBSTONE:
        return ordinals.put(field, "true".equals(value) ? "true" : "false");
      default:
        throw new StorageException("unable to set field " + field);
    }
  }

  /**
   * <p>Checks if the current node is marked as TOMBSTONE (old deleted node).</p>
   *
   * @return true if node is a tombstone
   */
  @Override
  public boolean isTombstone() {
    try {
      return "true".equals(get(Field.TOMBSTONE));
    } catch (StorageException e) {
      throw new RuntimeException("OOPS! Unexpected exception... please contact developer", e);
    }
  }

  @Override
  public void removeChild(String name) {
    childNodes.remove(name);
  }

  @Override
  public Map<String, Node> getChildren() throws StorageException {
    init();
    synchronized (childNodes) {
      Map<String, Node> ret = new HashMap<>();
      for (Map.Entry<String, Node> entry : childNodes.entrySet()) {
        ret.put(entry.getKey(), entry.getValue().deepClone());
      }
      return ret;
    }
  }

  @Override
  public Node getChild(String name) throws StorageException {
    init();
    return childNodes.get(name);
  }

  @Override
  public String getChildNodesCsv() throws StorageException {
    init();
    if (childNodes.size() == 0) {
      return "";
    }
    StringBuilder csv = new StringBuilder();
    for (String s : childNodes.keySet()) {
      csv.append(s);
      csv.append(",");
    }
    csv.deleteCharAt(csv.length() - 1);
    return csv.toString();
  }

  @Override
  public boolean isSkeleton() {
    return skeleton.get();
  }

  @Override
  public StorageController getController() {
    return controller;
  }

  @Override
  public StorageController setController(StorageController controller) {
    StorageController ret = this.controller;
    this.controller = controller;
    return ret;
  }

  @Override
  public boolean equals(Object o) {
    if (!(o instanceof DefaultNode)) {
      return false;
    }
    DefaultNode n2 = (DefaultNode) o;
    if (isSkeleton() != n2.isSkeleton()) {
      return false;
    }

    // check if one of the nodes is materialized
    if (!isSkeleton()) {
      // compare ordinals
      if (ordinals.size() != n2.ordinals.size()) {
        return false;
      }
      for (Map.Entry<Field, String> e : n2.ordinals.entrySet()) {
        try {
          if (!e.getValue().equals(get(e.getKey()))) {
            return false;
          }
        } catch (Exception ex) {
          throw new RuntimeException("Oops.... this should not happen... contact developer", ex);
        }
      }

      // compare values
      if (values.size() != n2.values.size()) {
        return false;
      }
      for (Map.Entry<String, NodeValue> e : values.entrySet()) {
        try {
          if (!e.getValue().equals(n2.getValue(e.getKey()))) {
            return false;
          }
        } catch (StorageException se) {
          //FIXME do logging here (should not happen)
          return false;
        }
      }

      //compare child nodes
      if (childNodes.size() != n2.childNodes.size()) {
        return false;
      }
      for (String n : childNodes.keySet()) {
        if (n2.childNodes.get(n) == null) {
          return false;
        }
      }
    } else {
      return getPath().equals(n2.getPath()) && controller == n2.getController();
    }
    return true;
  }

  @Override
  public void update(Node node) throws StorageException {
    update(node, true);
  }

  private void update(Node node, boolean deepClone) throws StorageException {
    DefaultNode n2 = (DefaultNode) node;
    controller = n2.getController();
    skeleton.set(n2.isSkeleton());

    // copy just the name
    this.ordinals.put(Field.PATH, n2.ordinals.get(Field.PATH));
    if (!n2.isSkeleton()) {
      // copy ordinals
      synchronized (ordinals) {
        ordinals.clear();
        ordinals.putAll(n2.ordinals);
      }

      // copy values
      synchronized (values) {
        values.clear();
        for (Map.Entry<String, NodeValue> e : n2.values.entrySet()) {
          values.put(e.getKey(), e.getValue().deepClone());
        }
      }

      // copy child nodes
      synchronized (childNodes) {
        childNodes.clear();
        for (Map.Entry<String, Node> e : n2.getChildren().entrySet()) {
          if (deepClone) {
            childNodes.put(e.getKey(), e.getValue().deepClone());
          } else {
            // FIXME no tombstone or expiry support
            childNodes.put(e.getKey(), new DefaultNode(e.getValue().getPath(), e.getValue().getOwner(), this.controller));
          }
        }
      }
    }
    // copy last modified date (just to make sure that they are not touched
    this.ordinals.put(Field.LASTMODIFIED, n2.ordinals.get(Field.LASTMODIFIED));
  }

  public void touch() {
    setLastModified(System.currentTimeMillis());
  }

  @Override
  public long getLastModified() {
    try {
      return Long.parseLong(get(Field.LASTMODIFIED));
    } catch (StorageException e) {
      throw new RuntimeException("Oops.... this should not happen... contact developer", e);
    }
  }

  @Override
  public void setLastModified(long lastModified) {
    try {
      set(Field.LASTMODIFIED, String.valueOf(lastModified));
    } catch (StorageException e) {
      throw new RuntimeException("Oops.... this should not happen... contact developer", e);
    }
  }

  @Override
  public String getExtendedLastModified() {
    // TODO: implement ExtendedTimestamp
    return String.format("%20s-cd429ffd-6823-4122-940d-18b0fbc4b4a3", getLastModified());
  }

  @Override
  public Node deepClone() throws StorageException {
    return new DefaultNode(this);
  }

  @Override
  public Node shallowClone() throws StorageException {
    DefaultNode ret = new DefaultNode(getPath(), getOwner());
    ret.update(this, false);
    return ret;
  }

  @Override
  public String toString() {
    return toString("", true, true, true);
  }

  public String toString(String prefix, boolean showTimestamp, boolean showOrdinals, boolean showChildren) {
    StringBuilder sb = new StringBuilder();
    sb.append(getPath());
    sb.append(prefix);
    if (showOrdinals || showTimestamp)
      sb.append("[");
    if (isSkeleton() && showOrdinals) {
      sb.append("<tombstone>,");
    }
    if (isSkeleton()) {
      //make sure that no accidental materialization is done
      sb.append("{<skeletonized>}");
    } else {
      sb.append("owner=").append(getOwner());
      sb.append(",visibility=").append(getVisibility());
      if (showOrdinals && showTimestamp) {
        sb.append(",");
      }
      if (showTimestamp) {
        sb.append("lastModified=");
        sb.append(getLastModified());
      }
    }
    if (showOrdinals || showTimestamp)
      sb.append("]");
    sb.append("{");
    int i = 0;
    if (isSkeleton()) {
      //make sure that no accidental materiaization is done
      sb.append("{<skeletonized>}");
    } else if (values.size() == 1) {
      sb.append(values.values().stream().findFirst().get());
    } else if (!values.isEmpty()) {
      sb.append(System.lineSeparator());
      for (Map.Entry<String, NodeValue> e : values.entrySet()) {
        if (i > 0) {
          sb.append(", ").append(System.lineSeparator());
        }
        sb.append(e.getValue().toString("  "));
        i++;
      }
      sb.append(System.lineSeparator());
      sb.append(prefix);
    }
    sb.append("}");
    if (!childNodes.isEmpty() && showChildren) {
      sb.append(" children{");
      int j = 0;
      for (Node element : childNodes.values()) {
        sb.append(element.getName());
        if (++j != childNodes.size()) {
          sb.append(", ");
        }
      }
      sb.append("}");
    }
    return sb.toString();
  }

  @Override
  public void toByteArrayStream(ByteArrayOutputStream out) throws IOException {
    SerializerHelper.writeMarker(out, serialVersionUID);
    SerializerHelper.writeInt(out, skeleton.get() ? 1 : 0);
    SerializerHelper.writeString(out, getPath());
    synchronized (ordinals) {
      SerializerHelper.writeInt(out, ordinals.size() - 1);
      for (Map.Entry<Field, String> e : ordinals.entrySet()) {
        if (e.getKey() != Field.PATH) {
          SerializerHelper.writeString(out, e.getKey().toStringStandard());
          SerializerHelper.writeString(out, e.getValue());
        }
      }
    }

    if (!isSkeleton()) {
      SerializerHelper.writeInt(out, values.size());
      synchronized (values) {
        for (Map.Entry<String, NodeValue> e : values.entrySet()) {
          SerializerHelper.writeString(out, e.getKey());
          e.getValue().toByteArrayStream(out);
        }
      }

      // childNodes
      SerializerHelper.writeInt(out, childNodes.size());
      synchronized (childNodes) {
        for (Map.Entry<String, Node> e : childNodes.entrySet()) {
          SerializerHelper.writeString(out, e.getKey());
          e.getValue().toByteArrayStream(out);
        }
      }
    }

    // write object identifier as end tag
    SerializerHelper.writeMarker(out, serialVersionUID);
  }

  /**
   * <p>Deserializes a NodeValue from a byteStream.</p>
   *
   * @param in the stream to be read
   * @return the deserialized NodeValue
   * @throws IOException if an exception happens deserializing the stream
   */
  public static DefaultNode fromByteArrayStream(ByteArrayInputStream in, StorageController controller) throws IOException {
    SerializerHelper.testMarker(in, serialVersionUID);
    boolean skel = SerializerHelper.readInt(in) == 1;
    DefaultNode n = new DefaultNode(SerializerHelper.readString(in), "NONE");
    n.skeleton.set(skel);
    if (skel) {
      n.controller = controller;
    }
    int counter = SerializerHelper.readInt(in);
    for (int i = 0; i < counter; i++) {
      n.ordinals.put(Field.valueOfStandard(SerializerHelper.readString(in)),
        SerializerHelper.readString(in));
    }

    if (!skel) {
      // read values
      counter = SerializerHelper.readInt(in);
      for (int i = 0; i < counter; i++) {
        n.values.put(SerializerHelper.readString(in), DefaultNodeValue.fromByteArrayStream(in));
      }

      // read childNodes
      counter = SerializerHelper.readInt(in);
      for (int i = 0; i < counter; i++) {
        n.childNodes.put(SerializerHelper.readString(in), DefaultNode.fromByteArrayStream(in, controller));
      }
    }
    SerializerHelper.testMarker(in, serialVersionUID);
    return n;
  }
}
