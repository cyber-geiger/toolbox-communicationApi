package eu.cybergeiger.api.storage;

import eu.cybergeiger.api.GeigerApi;
import eu.cybergeiger.api.PluginApi;
import eu.cybergeiger.api.communication.CommunicationHelper;
import eu.cybergeiger.api.message.GeigerUrl;
import eu.cybergeiger.api.message.Message;
import eu.cybergeiger.api.message.MessageType;
import eu.cybergeiger.api.plugin.PluginListener;
import eu.cybergeiger.serialization.SerializerHelper;
import eu.cybergeiger.storage.*;
import eu.cybergeiger.storage.node.DefaultNode;
import eu.cybergeiger.storage.node.Node;
import eu.cybergeiger.storage.node.value.DefaultNodeValue;
import eu.cybergeiger.storage.node.value.NodeValue;

import java.io.*;
import java.util.*;
import java.util.concurrent.TimeoutException;
import java.util.logging.Level;
import java.util.stream.Collectors;

/**
 * <p>Class for handling storage events in Plugins.</p>
 */
public class PassthroughController implements StorageController, PluginListener, ChangeRegistrar {
  private interface PayloadSerializer {
    void serialize(ByteArrayOutputStream out) throws IOException;
  }

  private final PluginApi api;

  private final Map<String, StorageListener> idToListener = new HashMap<>();
  private final Map<SearchCriteria, String> listenerCriteriaToId = new HashMap<>();
  private final Map<String, SearchCriteria> idToListenerCriteria = new HashMap<>();

  /**
   * <p>Constructor for PasstroughController.</p>
   *
   * @param api the LocalApi it belongs to
   */
  public PassthroughController(PluginApi api) {
    this.api = api;
  }

  @Override
  public void pluginEvent(Message msg) {
    if (msg.getAction() == null || !msg.getAction().getPath().endsWith("changeEvent"))
      return;
    try {
      processChangeEvent(msg);
    } catch (IOException e) {
      GeigerApi.logger.log(Level.SEVERE, "Got error while processing change event.", e);
    }
  }

  private void processChangeEvent(Message message) throws IOException {
    InputStream in = new ByteArrayInputStream(message.getPayload());
    String id = Objects.requireNonNull(SerializerHelper.readString(in));
    StorageListener listener = idToListener.get(id);
    if (listener == null)
      throw new StorageException("Listener \"" + id + "\" for change event not found.");

    String typeString = Objects.requireNonNull(SerializerHelper.readString(in));
    ChangeType type = ChangeType.valueOfStandard(typeString);

    int nodeAvailability = SerializerHelper.readInt(in);
    Node oldNode = (nodeAvailability & 1) == 0 ? null : DefaultNode.fromByteArrayStream(in, this);
    Node newNode = (nodeAvailability & 2) == 0 ? null : DefaultNode.fromByteArrayStream(in, this);

    try {
      listener.gotStorageChange(type, oldNode, newNode);
    } catch (StorageException e) {
      GeigerApi.logger.log(Level.SEVERE, "Change listener threw exception.", e);
    }
  }

  private ByteArrayInputStream callRemote(String name) throws StorageException {
    return callRemote(name, null);
  }

  private ByteArrayInputStream callRemote(String name, PayloadSerializer serializer) throws StorageException {
    ByteArrayOutputStream out = new ByteArrayOutputStream();
    if (serializer != null) {
      try {
        serializer.serialize(out);
      } catch (IOException e) {
        throw new StorageException("Serialization failed.", e);
      }
    }
    Message response;
    try {
      response = CommunicationHelper.sendAndWait(
        api,
        new Message(
          api.getId(), GeigerApi.MASTER_ID,
          MessageType.STORAGE_EVENT,
          new GeigerUrl(GeigerApi.MASTER_ID, name),
          out.toByteArray()
        ),
        new MessageType[]{
          MessageType.STORAGE_SUCCESS,
          MessageType.STORAGE_ERROR
        }
      );
    } catch (InterruptedException | TimeoutException | IOException e) {
      throw new StorageException("Remote call failed.", e);
    }
    ByteArrayInputStream in = new ByteArrayInputStream(response.getPayload());
    if (response.getType() == MessageType.STORAGE_ERROR) {
      StorageException exception;
      try {
        exception = StorageException.fromByteArrayStream(in);
      } catch (IOException e) {
        throw new StorageException("Failed to deserialize error.", e);
      }
      throw new StorageException("Received exception from master.", exception);
    }
    return in;
  }

  private Node callRemoteReturnNode(String name, String path) throws StorageException {
    InputStream in = callRemote(name, out -> SerializerHelper.writeString(out, path));
    try {
      return DefaultNode.fromByteArrayStream(in, this);
    } catch (IOException e) {
      throw new StorageException("Failed to deserialize Node.", e);
    }
  }

  @Override
  public Node get(String path) throws StorageException {
    return callRemoteReturnNode("getNode", path);
  }

  @Override
  public Node getNodeOrTombstone(String path) throws StorageException {
    return callRemoteReturnNode("getNodeOrTombstone", path);
  }

  @Override
  public void add(Node node) throws StorageException {
    callRemote("addNode", node::toByteArrayStream);
  }

  @Override
  public void update(Node node) throws StorageException {
    callRemote("updateNode", node::toByteArrayStream);
  }

  @Override
  public boolean addOrUpdate(Node node) throws StorageException {
    ByteArrayInputStream in = callRemote("addOrUpdateNode", node::toByteArrayStream);
    try {
      return SerializerHelper.readInt(in) == 1;
    } catch (IOException e) {
      throw new StorageException("Failed to deserialize result.", e);
    }
  }

  @Override
  public Node delete(String path) throws StorageException {
    return callRemoteReturnNode("deleteNode", path);
  }

  @Override
  public NodeValue getValue(String path, String key) throws StorageException {
    ByteArrayInputStream in = callRemote("getValue", out -> {
      SerializerHelper.writeString(out, path);
      SerializerHelper.writeString(out, key);
    });
    if (in.available() == 0) return null;
    try {
      return DefaultNodeValue.fromByteArrayStream(in);
    } catch (IOException e) {
      throw new StorageException("Failed to deserialize NodeValue.", e);
    }
  }

  @Override
  public void addValue(String path, NodeValue value) throws StorageException {
    callRemote("addValue", out -> {
      SerializerHelper.writeString(out, path);
      value.toByteArrayStream(out);
    });
  }

  @Override
  public void updateValue(String path, NodeValue value) throws StorageException {
    callRemote("updateValue", out -> {
      SerializerHelper.writeString(out, path);
      value.toByteArrayStream(out);
    });
  }

  @Override
  public boolean addOrUpdateValue(String path, NodeValue value) throws StorageException {
    ByteArrayInputStream in = callRemote("addOrUpdateValue", out -> {
      SerializerHelper.writeString(out, path);
      value.toByteArrayStream(out);
    });
    try {
      return SerializerHelper.readInt(in) == 1;
    } catch (IOException e) {
      throw new StorageException("Failed to deserialize result.", e);
    }
  }

  @Override
  public NodeValue deleteValue(String path, String key) throws StorageException {
    ByteArrayInputStream in = callRemote("deleteValue", out -> {
      SerializerHelper.writeString(out, path);
      SerializerHelper.writeString(out, key);
    });
    try {
      return DefaultNodeValue.fromByteArrayStream(in);
    } catch (IOException e) {
      throw new StorageException("Failed to deserialize NodeValue.", e);
    }
  }

  @Override
  public void rename(String oldPath, String newPathOrName) throws StorageException {
    callRemote("renameNode", out -> {
      SerializerHelper.writeString(out, oldPath);
      SerializerHelper.writeString(out, newPathOrName);
    });
  }

  @Override
  public List<Node> search(SearchCriteria criteria) throws StorageException {
    ByteArrayInputStream in = callRemote("searchNodes", criteria::toByteArrayStream);
    try {
      Node[] nodes = new Node[SerializerHelper.readInt(in)];
      for (int i = 0; i < nodes.length; i++) {
        nodes[i] = DefaultNode.fromByteArrayStream(in, this);
      }
      return new ArrayList<>(Arrays.asList(nodes));
    } catch (IOException e) {
      throw new StorageException("Failed to deserialize search result.", e);
    }
  }

  @Override
  public void close() throws StorageException {
    callRemote("close");
  }

  @Override
  public void flush() throws StorageException {
    callRemote("flush");
  }

  @Override
  public void zap() throws StorageException {
    callRemote("zap");
  }

  @Override
  public String dump(String rootNode, String prefix) throws StorageException {
    ByteArrayInputStream in = callRemote("dump", out -> {
      SerializerHelper.writeString(out, rootNode);
      SerializerHelper.writeString(out, prefix);
    });
    try {
      return SerializerHelper.readString(in);
    } catch (IOException e) {
      throw new StorageException("Failed to deserialize dump.", e);
    }
  }

  /**
   * Register a StorageListener for a Node defined by SearchCriteria.
   *
   * @param listener StorageListener to be registered
   * @param criteria SearchCriteria to search for the Node
   * @throws StorageException if the listener could not be registered
   */
  public void registerChangeListener(StorageListener listener, SearchCriteria criteria)
    throws StorageException {
    String id = listenerCriteriaToId.get(criteria);
    if (id == null) {
      ByteArrayInputStream in = callRemote(
        "registerChangeListener",
        criteria::toByteArrayStream
      );
      try {
        id = SerializerHelper.readString(in);
      } catch (IOException e) {
        throw new StorageException("Failed to deserialize criteria id.", e);
      }
      listenerCriteriaToId.put(criteria, id);
      idToListenerCriteria.put(id, criteria);
    }
    idToListener.put(id, listener);
  }

  /**
   * Deregister a StorageListener from the Storage.
   *
   * @param listener the listener to Deregister
   * @return the SearchCriteria that were deregistered
   * @throws StorageException if listener could not be deregistered
   */
  public SearchCriteria[] deregisterChangeListener(StorageListener listener)
    throws StorageException {
    List<String> ids = idToListener.entrySet()
      .stream()
      .filter(entry -> entry.getValue() == listener)
      .map(Map.Entry::getKey)
      .collect(Collectors.toList());
    if (ids.size() == 0)
      throw new StorageException("Cannot unregistered not registered StorageListener.");

    callRemote("deregisterChangeListeners", in -> {
      SerializerHelper.writeInt(in, ids.size());
      for (String id : ids) SerializerHelper.writeString(in, id);
    });

    ids.forEach(idToListener::remove);
    return ids.stream()
      .map(idToListenerCriteria::remove)
      .peek(listenerCriteriaToId::remove)
      .toArray(SearchCriteria[]::new);
  }
}
