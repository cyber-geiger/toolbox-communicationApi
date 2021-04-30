package eu.cybergeiger.communication;

import ch.fhnw.geiger.localstorage.SearchCriteria;
import ch.fhnw.geiger.localstorage.StorageController;
import ch.fhnw.geiger.localstorage.StorageException;
import ch.fhnw.geiger.localstorage.db.data.Node;
import ch.fhnw.geiger.localstorage.db.data.NodeImpl;
import ch.fhnw.geiger.localstorage.db.data.NodeValue;
import ch.fhnw.geiger.localstorage.db.data.NodeValueImpl;
import ch.fhnw.geiger.totalcross.ByteArrayInputStream;
import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

/**
 * Used for handling storage events in Plugins
 * LocalApi returns PasstroughController as StorageController
 * Plugin uses PasstroughController for all Storage related events
 * PasstroughController converts events into Messages and sends them via localApi
 */
public class PasstroughController implements StorageController, PluginListener {

  private final LocalApi localApi;
  private final String id;

  private Map<String, Object> storageEventObjects = new HashMap<>();
  //private StorageEventHandler storageEventHandler = new StorageEventHandler();

  public PasstroughController(LocalApi api, String id) {
    this.localApi = api;
    this.id = id;
    localApi.registerListener(new MessageType[]{MessageType.STORAGE_EVENT}, this);
  }

  private Message waitForResult(String command, String identifier) {
    while(storageEventObjects.get(identifier) == null) {
      // TODO how to appropriatly wait for this?
      // wait
      try {
        Thread.sleep(10);
      } catch (InterruptedException e) {
        e.printStackTrace();
      }
    }
    // TODO how and when to handle exceptions thrown in storage?
    // should it be checked in each method individually?
    return (Message)storageEventObjects.get(identifier);
  }

  @Override
  public Node get(String path) throws StorageException {
    String command = "getNode";
    String identifier = String.valueOf(new Random().nextInt());
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" +identifier + "/" + path));
    localApi.sendMessage(LocalApi.MASTER, m);

    // get response
    Message response = waitForResult(command, identifier);
    Node node = null;
    try {
      node = NodeImpl.fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
    } catch (IOException e) {
      // TODO error handling
      e.printStackTrace();
    }
    return node;
  }

  @Override
  public void add(Node node) throws StorageException {
    try {
      ByteArrayOutputStream bos = new ByteArrayOutputStream();
      node.toByteArrayStream(bos);
      byte[] payload = bos.toByteArray();
      Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          new GeigerUrl(id, "addNode"), payload);
      localApi.sendMessage(LocalApi.MASTER, m);
    } catch (IOException e) {
      throw new StorageException("Could not add Node", e);
    }
  }

  @Override
  public void update(Node node) throws StorageException {
    try {
      ByteArrayOutputStream bos = new ByteArrayOutputStream();
      node.toByteArrayStream(bos);
      byte[] payload = bos.toByteArray();
      Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          new GeigerUrl(id, "updateNode"));
      // TODO add Node as payload
      localApi.sendMessage(LocalApi.MASTER, m);
    } catch (IOException e) {
      throw new StorageException("Could not update Node", e);
    }
  }

  @Override
  public Node delete(String path) throws StorageException {
    String command = "deleteNode";
    String identifier = String.valueOf(new Random().nextInt());
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier + "/" + path));
    localApi.sendMessage(LocalApi.MASTER, m);

    // get response
    Message response = waitForResult(command, identifier);
    Node node = null;
    try {
      node = NodeImpl.fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
    } catch (IOException e) {
      // TODO error handling
      e.printStackTrace();
    }
    return node;
  }

  @Override
  public NodeValue getValue(String path, String key) {
    String command = "getValue";
    String identifier = String.valueOf(new Random().nextInt());
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier + "/" + path + "/" + key));
    localApi.sendMessage(LocalApi.MASTER, m);

    // get response
    Message response = waitForResult(command, identifier);
    NodeValue nodeValue = null;
    try {
      nodeValue = NodeValueImpl.fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
    } catch (IOException e) {
      // TODO error handling
      e.printStackTrace();
    }
    return nodeValue;
  }

  @Override
  public void addValue(String path, NodeValue value) throws StorageException {
    try {
      ByteArrayOutputStream bos = new ByteArrayOutputStream();
      value.toByteArrayStream(bos);
      byte[] payload = bos.toByteArray();
      String identifier = String.valueOf(new Random().nextInt());
      Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          new GeigerUrl(id, "addValue/" + identifier + "/" + path), payload);
      localApi.sendMessage(LocalApi.MASTER, m);
    } catch (IOException e) {
      throw new StorageException("Could not add NodeValue", e);
    }
  }

  @Override
  public void updateValue(String nodeName, NodeValue value) throws StorageException {
    try {
      ByteArrayOutputStream bos = new ByteArrayOutputStream();
      value.toByteArrayStream(bos);
      byte[] payload = bos.toByteArray();
      String identifier = String.valueOf(new Random().nextInt());
      Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          new GeigerUrl(id, "updateValue/" + identifier + "/" + nodeName), payload);
      localApi.sendMessage(LocalApi.MASTER, m);
    } catch (IOException e) {
      throw new StorageException("Could not update NodeValue", e);
    }
  }

  @Override
  public NodeValue removeValue(String path, String key) throws StorageException {
    String command = "deleteValue";
    String identifier = String.valueOf(new Random().nextInt());
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier + "/" + path + "/" + key));
    localApi.sendMessage(LocalApi.MASTER, m);

    // get response
    Message response = waitForResult(command, identifier);
    NodeValue nodeValue = null;
    try {
      nodeValue = NodeValueImpl.fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
    } catch (IOException e) {
      // TODO error handling
      e.printStackTrace();
    }
    return nodeValue;
  }

  @Override
  public void rename(String oldPath, String newPathOrName) throws StorageException {
    String identifier = String.valueOf(new Random().nextInt());
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, "rename/" + identifier + "/" + oldPath + "/" + newPathOrName));
    localApi.sendMessage(LocalApi.MASTER, m);
  }

  @Override
  public List<Node> search(SearchCriteria criteria) throws StorageException {
    String command = "search";
    String identifier = String.valueOf(new Random().nextInt());
    //try {
      ByteArrayOutputStream bos = new ByteArrayOutputStream();
      // TODO searchCriteria serializable
      //criteria.toByteArrayStream(bos);
      byte[] payload = bos.toByteArray();

      Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          new GeigerUrl(id, command + "/" + identifier));
      // TODO add searchCriteria as payload
      localApi.sendMessage(LocalApi.MASTER, m);
    //} catch (IOException e) {
    //  throw new StorageException("Could not start Search", e);
    //}

    // get response
    Message response = waitForResult(command, identifier);
    List<Node> nodes = null;
    try {
      // TODO read multiple nodes (does frombyteArrayStream work in a for loop?)
      // loop until exception?
      Node node = NodeImpl.fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      nodes.add(node);
    } catch (IOException e) {
      // TODO error handling
      e.printStackTrace();
    }
    return nodes;
  }

  @Override
  public void close() {
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, "close"));
    localApi.sendMessage(LocalApi.MASTER, m);
  }

  @Override
  public void flush() {
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, "flush"));
    localApi.sendMessage(LocalApi.MASTER, m);
  }

  @Override
  public void zap() {
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, "zap"));
    localApi.sendMessage(LocalApi.MASTER, m);
  }

  @Override
  public void pluginEvent(GeigerUrl url, Message msg) {
    // create the needed objects
    // TODO when event is received, then it must be a callback
    // maybe this needs to be connected to the waitForResult
  }
}
