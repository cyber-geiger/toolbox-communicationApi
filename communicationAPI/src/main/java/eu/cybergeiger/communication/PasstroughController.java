package eu.cybergeiger.communication;

import ch.fhnw.geiger.localstorage.SearchCriteria;
import ch.fhnw.geiger.localstorage.StorageController;
import ch.fhnw.geiger.localstorage.StorageException;
import ch.fhnw.geiger.localstorage.db.StorageMapper;
import ch.fhnw.geiger.localstorage.db.data.Node;
import ch.fhnw.geiger.localstorage.db.data.NodeImpl;
import ch.fhnw.geiger.localstorage.db.data.NodeValue;

import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.List;

/**
 * Used for handling storage events in Plugins
 * LocalApi returns PasstroughController as StorageController
 * Plugin uses PasstroughController for all Storage related events
 * PasstroughController converts events into Messages and sends them via localApi
 */
public class PasstroughController implements StorageController {

  private final LocalApi localApi;
  private final String id;

  public PasstroughController(LocalApi api, String id) {
    this.localApi = api;
    this.id = id;
  }

  @Override
  public Node get(String path) throws StorageException {
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, "getNode"), path.getBytes(StandardCharsets.UTF_8));
    localApi.sendMessage(id, m);
    // TODO get answer
    return null;
  }

  @Override
  public void add(Node node) throws StorageException {
    //node.toByteArrayStream();
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, "addNode"));
    // TODO add Node as payload

    localApi.sendMessage(id, m);
  }

  @Override
  public void update(Node node) throws StorageException {
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, "updateNode"));
    // TODO add Node as payload
    localApi.sendMessage(id, m);
  }

  @Override
  public Node delete(String path) throws StorageException {
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, "removeNode"), path.getBytes(StandardCharsets.UTF_8));
    localApi.sendMessage(id, m);
    // TODO get answer
    return null;
  }

  @Override
  public NodeValue getValue(String path, String key) {
    String payload = path + " " + key;
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, "getValue"), payload.getBytes(StandardCharsets.UTF_8));
    localApi.sendMessage(id, m);
    // TODO get answer
    return null;
  }

  @Override
  public void addValue(String path, NodeValue value) throws StorageException {
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, "addValue"));
    // TODO create payload from path and NodeValue
    localApi.sendMessage(id, m);
  }

  @Override
  public void updateValue(String nodeName, NodeValue value) throws StorageException {
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, "updateValue"));
    // TODO create payload from nodeName and NodeValue
    localApi.sendMessage(id, m);
  }

  @Override
  public NodeValue removeValue(String path, String key) throws StorageException {
    String payload = path + " " + key;
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, "removeValue"), payload.getBytes(StandardCharsets.UTF_8));
    localApi.sendMessage(id, m);
    // TODO get answer
    return null;
  }

  @Override
  public void rename(String oldPath, String newPathOrName) throws StorageException {
    String payload = oldPath + " " + newPathOrName;
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, "rename"), payload.getBytes(StandardCharsets.UTF_8));
    localApi.sendMessage(id, m);
  }

  @Override
  public List<Node> search(SearchCriteria criteria) throws StorageException {
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, "search"));
    // TODO add searchCriteria as payload
    localApi.sendMessage(id, m);
    // TODO get answer
    return null;
  }

  @Override
  public void close() {
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, "close"));
    localApi.sendMessage(id, m);
  }

  @Override
  public void flush() {
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, "flush"));
    localApi.sendMessage(id, m);
  }

  @Override
  public void zap() {
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, "zap"));
    localApi.sendMessage(id, m);
  }
}
