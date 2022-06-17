package eu.cybergeiger.api.storage;

import eu.cybergeiger.api.GeigerApi;
import eu.cybergeiger.api.PluginApi;
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

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.*;

/**
 * <p>Class for handling storage events in Plugins.</p>
 */
public class PassthroughController implements StorageController, PluginListener, ChangeRegistrar {

  private final PluginApi pluginApi;
  private final String id;
  private final Object comm = new Object();

  private final Map<String, Message> receivedMessages = new HashMap<>();

  /**
   * <p>Constructor for PasstroughController.</p>
   *
   * @param api the LocalApi it belongs to
   * @param id  the PluginId it belongs to
   */
  public PassthroughController(PluginApi api, String id) {
    this.pluginApi = api;
    this.id = id;
    pluginApi.registerListener(new MessageType[]{MessageType.STORAGE_EVENT,
      MessageType.STORAGE_SUCCESS, MessageType.STORAGE_ERROR}, this);
  }

  private Message waitForResult(String command, String identifier) {
    String token = command + "/" + identifier;
    long start = System.currentTimeMillis();
    while (receivedMessages.get(token) == null) {
      // wait for the appropriate message
      try {
        synchronized (comm) {
          comm.wait(1000);
        }
      } catch (InterruptedException e) {
        e.printStackTrace();
      }
      if (System.currentTimeMillis() - start > 5000) {
        throw new RuntimeException("Lost communication while waiting for " + token);
      }
    }
    return receivedMessages.get(token);
  }

  @Override
  public Node get(String path) throws StorageException {
    try {
      String command = "getNode";
      String identifier = String.valueOf(new Random().nextInt());
      pluginApi.sendMessage(new Message(id, GeigerApi.MASTER_ID,
        MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier + "/" + path)));

      // get response
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException
          .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      } else {
        // it was a success
        return DefaultNode.fromByteArrayStream(new ByteArrayInputStream(response.getPayload()), this);
      }
    } catch (IOException e) {
      throw new StorageException("Could not get Node", e);
    }
  }

  @Override
  public Node getNodeOrTombstone(String path) throws StorageException {
    String command = "getNodeOrTombstone";
    String identifier = String.valueOf(new Random().nextInt());
    try {
      pluginApi.sendMessage(new Message(id, GeigerApi.MASTER_ID,
        MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier + "/" + path)));
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException
          .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      } else {
        // it was a success
        return DefaultNode.fromByteArrayStream(new ByteArrayInputStream(response.getPayload()), this);
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
      Message m = new Message(id, GeigerApi.MASTER_ID, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier), payload);
      pluginApi.sendMessage(m);

      // get response
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
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
      Message m = new Message(id, GeigerApi.MASTER_ID, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier), payload);
      pluginApi.sendMessage(m);

      // get response
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException
          .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      }
      // if no error received, nothing more to do
    } catch (IOException e) {
      throw new StorageException("Could not update Node", e);
    }
  }

  @Override
  public boolean addOrUpdate(Node node) throws StorageException {
    String command = "addOrUpdateNode";
    String identifier = String.valueOf(new Random().nextInt());
    try {
      ByteArrayOutputStream bos = new ByteArrayOutputStream();
      node.toByteArrayStream(bos);
      byte[] payload = bos.toByteArray();
      Message m = new Message(id, GeigerApi.MASTER_ID, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier), payload);
      pluginApi.sendMessage(m);

      // get response
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException
          .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      }
      // if no error received, nothing more to do
      return true;
    } catch (IOException e) {
      throw new StorageException("Could not add or update Node", e);
    }

  }

  @Override
  public Node delete(String path) throws StorageException {
    try {
      String command = "deleteNode";
      String identifier = String.valueOf(new Random().nextInt());
      pluginApi.sendMessage(new Message(id, GeigerApi.MASTER_ID,
        MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier + "/" + path)));
      // get response
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException
          .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      } else {
        // it was a success
        return DefaultNode.fromByteArrayStream(new ByteArrayInputStream(response.getPayload()), this);
      }
    } catch (IOException e) {
      throw new StorageException("Could not delete Node", e);
    }
  }

  @Override
  public NodeValue getValue(String path, String key) throws StorageException {
    try {
      String command = "getValue";
      String identifier = String.valueOf(new Random().nextInt());
      pluginApi.sendMessage(new Message(id, GeigerApi.MASTER_ID,
        MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier + "/" + path + "/" + key)));

      // get response
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException
          .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      } else {
        // it was a success
        return DefaultNodeValue.fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
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

      Message m = new Message(id, GeigerApi.MASTER_ID, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier + "/" + path), payload);
      pluginApi.sendMessage(m);

      // get response
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
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

      Message m = new Message(id, GeigerApi.MASTER_ID, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier + "/" + nodeName), payload);
      pluginApi.sendMessage(m);

      // get response
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
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
    try {
      String command = "deleteValue";
      String identifier = String.valueOf(new Random().nextInt());
      pluginApi.sendMessage(new Message(id, GeigerApi.MASTER_ID,
        MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier + "/" + path + "/" + key)));
      // get response
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException
          .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      } else {
        // it was a success
        return DefaultNodeValue.fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      }
    } catch (IOException e) {
      throw new StorageException("Could not delete Value", e);
    }
  }

  @Override
  public void rename(String oldPath, String newPathOrName) throws StorageException {
    String command = "deleteValue";
    String identifier = String.valueOf(new Random().nextInt());
    // this will not work if either the old or the new path contains any "/"
    try {
      pluginApi.sendMessage(
        new Message(id, GeigerApi.MASTER_ID, MessageType.STORAGE_EVENT,
          new GeigerUrl(id, command + "/" + identifier + "/"
            + oldPath + "/" + newPathOrName)));
    } catch (IOException e) {
      throw new StorageException("Could not rename Node", e);
    }
    // get response
    Message response = waitForResult(command, identifier);
    if (response.getType() == MessageType.STORAGE_ERROR) {
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

      Message m = new Message(id, GeigerApi.MASTER_ID, MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier), payload);
      pluginApi.sendMessage(m);

      // get response
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException
          .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      } else {
        // it was a success
        byte[] receivedPayload = response.getPayload();
        // get number of nodes
        int numNodes = SerializerHelper
          .byteArrayToInt(Arrays.copyOfRange(receivedPayload, 0, 4));
        // create bytearray containing only the sent nodes
        byte[] receivedNodes = Arrays.copyOfRange(receivedPayload, 5, receivedPayload.length);
        // retrieve nodes and add to list
        List<Node> nodes = new ArrayList<>();
        for (int i = 0; i < numNodes; ++i) {
          // does this advance the stream? after every read the next one needs to start at
          // the ned of the last read + 1
          nodes.add(DefaultNode.fromByteArrayStream(new ByteArrayInputStream(receivedNodes), this));
        }
        return nodes;
      }
    } catch (IOException e) {
      throw new StorageException("Could not start Search", e);
    }
  }

  @Override
  public void close() throws StorageException {
    String command = "close";
    String identifier = String.valueOf(new Random().nextInt());
    try {
      pluginApi.sendMessage(new Message(id, GeigerApi.MASTER_ID,
        MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier)));
    } catch (IOException e) {
      throw new StorageException("Could not close", e);
    }
    // get response
    Message response = waitForResult(command, identifier);
    if (response.getType() == MessageType.STORAGE_ERROR) {
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
  public void flush() throws StorageException {
    String command = "flush";
    String identifier = String.valueOf(new Random().nextInt());
    try {
      pluginApi.sendMessage(new Message(id, GeigerApi.MASTER_ID,
        MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier)));
    } catch (IOException e) {
      throw new StorageException("Could not flush", e);
    }
    // get response
    Message response = waitForResult(command, identifier);
    if (response.getType() == MessageType.STORAGE_ERROR) {
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
  public void zap() throws StorageException {
    String command = "zap";
    String identifier = String.valueOf(new Random().nextInt());
    try {
      pluginApi.sendMessage(new Message(id, GeigerApi.MASTER_ID,
        MessageType.STORAGE_EVENT,
        new GeigerUrl(id, command + "/" + identifier)));
    } catch (IOException e) {
      throw new StorageException("Could not flush", e);
    }
    // get response
    Message response = waitForResult(command, identifier);
    if (response.getType() == MessageType.STORAGE_ERROR) {
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
  public void pluginEvent(Message msg) {
    synchronized (receivedMessages) {
      receivedMessages.put(msg.getAction().getPath(), msg);
    }
    synchronized (comm) {
      comm.notifyAll();
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
    String command = "registerChangeListener";
    String identifier = String.valueOf(new Random().nextInt());

    ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
    // Storagelistener Serialization,
    //byteArrayOutputStream.write(listener)
    try {
      byteArrayOutputStream.write(criteria.toByteArray());
      pluginApi.sendMessage(new Message(id, GeigerApi.MASTER_ID,
        MessageType.STORAGE_EVENT,
        new GeigerUrl(GeigerApi.MASTER_ID, command + "/" + identifier),
        byteArrayOutputStream.toByteArray()));
    } catch (IOException e) {
      // TODO proper Error handling
      // this should never occur
    }

    // get response
    Message response = waitForResult(command, identifier);
    if (response.getType() == MessageType.STORAGE_ERROR) {
      try {
        throw StorageException
          .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      } catch (IOException e) {
        throw new StorageException("Could not rename Node", e);
      }
    }
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
    String command = "deregisterChangeListener";
    String identifier = String.valueOf(new Random().nextInt());

    ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
    // Storagelistener Serialization,
    //byteArrayOutputStream.write(listener)
    try {
      pluginApi.sendMessage(new Message(id, GeigerApi.MASTER_ID,
        MessageType.STORAGE_EVENT,
        new GeigerUrl(GeigerApi.MASTER_ID, command + "/" + identifier),
        byteArrayOutputStream.toByteArray()));
    } catch (IOException e) {
      throw new StorageException("Could not rename Node", e);
    }
    // get response
    Message response = waitForResult(command, identifier);
    if (response.getType() == MessageType.STORAGE_ERROR) {
      try {
        throw StorageException
          .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      } catch (IOException e) {
        throw new StorageException("Could not rename Node", e);
      }
    } else {
      SearchCriteria.fromByteArray(response.getPayload());
      // TODO return directly if no array is needed
      return new SearchCriteria[0];
    }
  }
}
