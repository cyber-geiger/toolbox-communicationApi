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
 * <p>Class for handling storage events in Plugins.</p>
 */
public class PasstroughController implements StorageController, PluginListener {

  private final LocalApi localApi;
  private final String id;

  private Map<String, Object> storageEventObjects = new HashMap<>();
  //private StorageEventHandler storageEventHandler = new StorageEventHandler();

  /**
   * <p>Constructor for passtrouhgcontroller.</p>
   *
   * @param api the LocalApi it belongs to
   * @param id the PluginId it belongs to
   */
  public PasstroughController(LocalApi api, String id) {
    this.localApi = api;
    this.id = id;
    localApi.registerListener(new MessageType[]{MessageType.STORAGE_EVENT}, this);
  }

  private Message waitForResult(String command, String identifier) {
    while (storageEventObjects.get(identifier) == null) {
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
    return (Message) storageEventObjects.get(identifier);
  }

  @Override
  public Node get(String path) throws StorageException {
    String command = "getNode";
    String identifier = String.valueOf(new Random().nextInt());
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier + "/" + path));
    localApi.sendMessage(LocalApi.MASTER, m);

    // get response
    Message response = waitForResult(command, identifier);
    String url = response.getAction().getPath();
    String result = url.substring(url.lastIndexOf("/") + 1);

    try {
      if ("error".equals(result)) {
        throw StorageException
            .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      } else {
        // it was a success
        return NodeImpl.fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      }
    } catch (IOException e) {
      throw new StorageException("Could not get Node", e);
    }
  }

  @Override
  public void add(Node node) throws StorageException {
    String command = "addNode";
    String identifier = String.valueOf(new Random().nextInt());
    try {
      ByteArrayOutputStream bos = new ByteArrayOutputStream();
      node.toByteArrayStream(bos);
      byte[] payload = bos.toByteArray();
      Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          new GeigerUrl(id, command + "/" + identifier), payload);
      localApi.sendMessage(LocalApi.MASTER, m);

      // get response
      Message response = waitForResult(command, identifier);
      String url = response.getAction().getPath();
      String result = url.substring(url.lastIndexOf("/") + 1);
      if ("error".equals(result)) {
        throw StorageException
            .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      }
      // if no error received, nothing more to do
    } catch (IOException e) {
      throw new StorageException("Could not add Node", e);
    }
  }

  @Override
  public void update(Node node) throws StorageException {
    String command = "updateNode";
    String identifier = String.valueOf(new Random().nextInt());
    try {
      ByteArrayOutputStream bos = new ByteArrayOutputStream();
      node.toByteArrayStream(bos);
      byte[] payload = bos.toByteArray();
      Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          new GeigerUrl(id, command + "/" + identifier), payload);
      localApi.sendMessage(LocalApi.MASTER, m);

      // get response
      Message response = waitForResult(command, identifier);
      String url = response.getAction().getPath();
      String result = url.substring(url.lastIndexOf("/") + 1);
      if ("error".equals(result)) {
        throw StorageException
            .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      }
      // if no error received, nothing more to do
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
    String url = response.getAction().getPath();
    String result = url.substring(url.lastIndexOf("/") + 1);
    try {
      if ("error".equals(result)) {
        throw StorageException
            .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      } else {
        // it was a success
        return NodeImpl.fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      }
    } catch (IOException e) {
      throw new StorageException("Could not delete Node", e);
    }
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
    String url = response.getAction().getPath();
    String result = url.substring(url.lastIndexOf("/") + 1);
    try {
      if ("error".equals(result)) {
        throw StorageException
            .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      } else {
        // it was a success
        return NodeValueImpl.fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      }
    } catch (IOException e) {
      throw new StorageException("Could not get Value", e);
    }
  }

  @Override
  public void addValue(String path, NodeValue value) throws StorageException {
    String command = "addValue";
    String identifier = String.valueOf(new Random().nextInt());
    try {
      ByteArrayOutputStream bos = new ByteArrayOutputStream();
      value.toByteArrayStream(bos);
      byte[] payload = bos.toByteArray();

      Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          new GeigerUrl(id, command + "/" + identifier + "/" + path), payload);
      localApi.sendMessage(LocalApi.MASTER, m);

      // get response
      Message response = waitForResult(command, identifier);
      String url = response.getAction().getPath();
      String result = url.substring(url.lastIndexOf("/") + 1);
      if ("error".equals(result)) {
        throw StorageException
            .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      }
      // if no error received, nothing more to do
    } catch (IOException e) {
      throw new StorageException("Could not add NodeValue", e);
    }
  }

  @Override
  public void updateValue(String nodeName, NodeValue value) throws StorageException {
    String command = "updateValue";
    String identifier = String.valueOf(new Random().nextInt());
    try {
      ByteArrayOutputStream bos = new ByteArrayOutputStream();
      value.toByteArrayStream(bos);
      byte[] payload = bos.toByteArray();

      Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          new GeigerUrl(id, command + "/" + identifier + "/" + nodeName), payload);
      localApi.sendMessage(LocalApi.MASTER, m);

      // get response
      Message response = waitForResult(command, identifier);
      String url = response.getAction().getPath();
      String result = url.substring(url.lastIndexOf("/") + 1);
      if ("error".equals(result)) {
        throw StorageException
            .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      }
      // if no error received, nothing more to do
    } catch (IOException e) {
      throw new StorageException("Could not update NodeValue", e);
    }
  }

  @Override
  public NodeValue deleteValue(String path, String key) throws StorageException {
    String command = "deleteValue";
    String identifier = String.valueOf(new Random().nextInt());
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier + "/" + path + "/" + key));
    localApi.sendMessage(LocalApi.MASTER, m);

    // get response
    Message response = waitForResult(command, identifier);
    String url = response.getAction().getPath();
    String result = url.substring(url.lastIndexOf("/") + 1);
    try {
      if ("error".equals(result)) {
        throw StorageException
            .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      } else {
        // it was a success
        return NodeValueImpl.fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      }
    } catch (IOException e) {
      throw new StorageException("Could not delete Value", e);
    }
  }

  @Override
  public void rename(String oldPath, String newPathOrName) throws StorageException {
    String command = "deleteValue";
    String identifier = String.valueOf(new Random().nextInt());

    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier + "/" + oldPath + "/" + newPathOrName));
    localApi.sendMessage(LocalApi.MASTER, m);

    // get response
    Message response = waitForResult(command, identifier);
    String url = response.getAction().getPath();
    String result = url.substring(url.lastIndexOf("/") + 1);

    if ("error".equals(result)) {
      try {
        throw StorageException
            .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      } catch (IOException e) {
        throw new StorageException("Could not rename Node", e);
      }
    }
    // if no error received, nothing more to do
  }

  @Override
  public List<Node> search(SearchCriteria criteria) throws StorageException {
    String command = "search";
    String identifier = String.valueOf(new Random().nextInt());
    try {
      ByteArrayOutputStream bos = new ByteArrayOutputStream();
      criteria.toByteArrayStream(bos);
      byte[] payload = bos.toByteArray();

      Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          new GeigerUrl(id, command + "/" + identifier));
      // TODO add searchCriteria as payload
      localApi.sendMessage(LocalApi.MASTER, m);

      // get response
      Message response = waitForResult(command, identifier);
      String url = response.getAction().getPath();
      String result = url.substring(url.lastIndexOf("/") + 1);
      if ("error".equals(result)) {
        throw StorageException
            .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      } else {
        // it was a success
        List<Node> nodes = null;
        // TODO read multiple nodes (does frombyteArrayStream work in a for loop?)
        // loop until exception?
        Node node = NodeImpl.fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
        nodes.add(node);
        return nodes;
      }
    } catch (IOException e) {
      throw new StorageException("Could not start Search", e);
    }
  }

  @Override
  public void close() {
    String command = "close";
    String identifier = String.valueOf(new Random().nextInt());
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier));
    localApi.sendMessage(LocalApi.MASTER, m);
    // get response
    Message response = waitForResult(command, identifier);
    String url = response.getAction().getPath();
    String result = url.substring(url.lastIndexOf("/") + 1);

    if ("error".equals(result)) {
      try {
        throw StorageException
            .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      } catch (IOException e) {
        throw new StorageException("Could not close", e);
      }
    }
    // if no error received, nothing more to do
  }

  @Override
  public void flush() {
    String command = "flush";
    String identifier = String.valueOf(new Random().nextInt());
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier));
    localApi.sendMessage(LocalApi.MASTER, m);
    // get response
    Message response = waitForResult(command, identifier);
    String url = response.getAction().getPath();
    String result = url.substring(url.lastIndexOf("/") + 1);
    if ("error".equals(result)) {
      try {
        throw StorageException
            .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      } catch (IOException e) {
        throw new StorageException("Could not flush", e);
      }
    }
    // if no error received, nothing more to do
  }

  @Override
  public void zap() {
    String command = "zap";
    String identifier = String.valueOf(new Random().nextInt());
    Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier));
    localApi.sendMessage(LocalApi.MASTER, m);
    // get response
    Message response = waitForResult(command, identifier);
    String url = response.getAction().getPath();
    String result = url.substring(url.lastIndexOf("/") + 1);
    if ("error".equals(result)) {
      try {
        throw StorageException
            .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      } catch (IOException e) {
        throw new StorageException("Could not zap", e);
      }
    }
    // if no error received, nothing more to do
  }

  @Override
  public void pluginEvent(GeigerUrl url, Message msg) {
    // create the needed objects
    // TODO when event is received, then it must be a callback
    // maybe this needs to be connected to the waitForResult
  }
}