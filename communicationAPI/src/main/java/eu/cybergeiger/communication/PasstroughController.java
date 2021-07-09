package eu.cybergeiger.communication;

import ch.fhnw.geiger.localstorage.ChangeRegistrar;
import ch.fhnw.geiger.localstorage.SearchCriteria;
import ch.fhnw.geiger.localstorage.StorageController;
import ch.fhnw.geiger.localstorage.StorageException;
import ch.fhnw.geiger.localstorage.StorageListener;
import ch.fhnw.geiger.localstorage.db.data.Node;
import ch.fhnw.geiger.localstorage.db.data.NodeImpl;
import ch.fhnw.geiger.localstorage.db.data.NodeValue;
import ch.fhnw.geiger.localstorage.db.data.NodeValueImpl;
import ch.fhnw.geiger.totalcross.ByteArrayInputStream;
import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;
import ch.fhnw.geiger.totalcross.System;
import eu.cybergeiger.totalcross.MalformedUrlException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;

/**
 * <p>Class for handling storage events in Plugins.</p>
 */
public class PasstroughController implements StorageController, PluginListener, ChangeRegistrar {

  private final LocalApi localApi;
  private final String id;
  private final Object comm = new Object();

  private final Map<String, Message> receivedMessages = new HashMap<>();

  /**
   * <p>Constructor for PasstroughController.</p>
   *
   * @param api the LocalApi it belongs to
   * @param id  the PluginId it belongs to
   */
  public PasstroughController(LocalApi api, String id) {
    this.localApi = api;
    this.id = id;
    localApi.registerListener(new MessageType[]{MessageType.STORAGE_EVENT,
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
    String command = "getNode";
    String identifier = String.valueOf(new Random().nextInt());
    try {
      localApi.sendMessage(LocalApi.MASTER, new Message(id, LocalApi.MASTER,
          MessageType.STORAGE_EVENT,
          new GeigerUrl(id, command + "/" + identifier + "/" + path)));
    } catch (MalformedUrlException e) {
      // TODO proper Error handling
      // this should never occur
    }

    // get response
    Message response = waitForResult(command, identifier);
    try {
      if (response.getType() == MessageType.STORAGE_ERROR) {
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
  public Node getNodeOrTombstone(String path) throws StorageException {
    String command = "getNodeOrTombstone";
    String identifier = String.valueOf(new Random().nextInt());
    try {
      localApi.sendMessage(LocalApi.MASTER, new Message(id, LocalApi.MASTER,
          MessageType.STORAGE_EVENT,
          new GeigerUrl(id, command + "/" + identifier + "/" + path)));
    } catch (MalformedUrlException e) {
      // TODO proper Error handling
      // this should never occur
    }

    // get response
    Message response = waitForResult(command, identifier);
    try {
      if (response.getType() == MessageType.STORAGE_ERROR) {
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
      Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          new GeigerUrl(id, command + "/" + identifier), payload);
      localApi.sendMessage(LocalApi.MASTER, m);

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
      Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          new GeigerUrl(id, command + "/" + identifier), payload);
      localApi.sendMessage(LocalApi.MASTER, m);

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
    String command = "deleteNode";
    String identifier = String.valueOf(new Random().nextInt());
    try {
      localApi.sendMessage(LocalApi.MASTER, new Message(id, LocalApi.MASTER,
          MessageType.STORAGE_EVENT,
          new GeigerUrl(id, command + "/" + identifier + "/" + path)));
    } catch (MalformedUrlException e) {
      // TODO proper Error handling
      // this should never occur
    }
    // get response
    Message response = waitForResult(command, identifier);
    try {
      if (response.getType() == MessageType.STORAGE_ERROR) {
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
  public NodeValue getValue(String path, String key) throws StorageException {
    String command = "getValue";
    String identifier = String.valueOf(new Random().nextInt());
    try {
      localApi.sendMessage(LocalApi.MASTER, new Message(id, LocalApi.MASTER,
          MessageType.STORAGE_EVENT,
          new GeigerUrl(id, command + "/" + identifier + "/" + path + "/" + key)));
    } catch (MalformedUrlException e) {
      // TODO proper Error handling
      // this should never occur
    }

    // get response
    Message response = waitForResult(command, identifier);
    try {
      if (response.getType() == MessageType.STORAGE_ERROR) {
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

      Message m = new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          new GeigerUrl(id, command + "/" + identifier + "/" + nodeName), payload);
      localApi.sendMessage(LocalApi.MASTER, m);

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
    String command = "deleteValue";
    String identifier = String.valueOf(new Random().nextInt());
    try {
      localApi.sendMessage(LocalApi.MASTER, new Message(id, LocalApi.MASTER,
          MessageType.STORAGE_EVENT,
          new GeigerUrl(id, command + "/" + identifier + "/" + path + "/" + key)));
    } catch (MalformedUrlException e) {
      // TODO proper Error handling
      // this should never occur
    }
    // get response
    Message response = waitForResult(command, identifier);
    try {
      if (response.getType() == MessageType.STORAGE_ERROR) {
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
    try {
      localApi.sendMessage(LocalApi.MASTER,
          new Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
              new GeigerUrl(id, command + "/" + identifier + "/"
                  + oldPath + "/" + newPathOrName)));
    } catch (MalformedUrlException e) {
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
          new GeigerUrl(id, command + "/" + identifier), payload);
      localApi.sendMessage(LocalApi.MASTER, m);

      // get response
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException
            .fromByteArrayStream(new ByteArrayInputStream(response.getPayload()));
      } else {
        // it was a success
        byte[] receivedPayload = response.getPayload();
        // get number of nodes
        int numNodes = GeigerCommunicator
            .byteArrayToInt(Arrays.copyOfRange(receivedPayload, 0, 4));
        // create bytearray containing only the sent nodes
        byte[] receivedNodes = Arrays.copyOfRange(receivedPayload, 5, receivedPayload.length);
        // retrieve nodes and add to list
        List<Node> nodes = new ArrayList<>();
        for (int i = 0; i < numNodes; ++i) {
          nodes.add(NodeImpl.fromByteArrayStream(new ByteArrayInputStream(receivedNodes)));
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
      localApi.sendMessage(LocalApi.MASTER, new Message(id, LocalApi.MASTER,
          MessageType.STORAGE_EVENT,
          new GeigerUrl(id, command + "/" + identifier)));
    } catch (MalformedUrlException e) {
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
      localApi.sendMessage(LocalApi.MASTER, new Message(id, LocalApi.MASTER,
          MessageType.STORAGE_EVENT,
          new GeigerUrl(id, command + "/" + identifier)));
    } catch (MalformedUrlException e) {
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
      localApi.sendMessage(LocalApi.MASTER, new Message(id, LocalApi.MASTER,
          MessageType.STORAGE_EVENT,
          new GeigerUrl(id, command + "/" + identifier)));
    } catch (MalformedUrlException e) {
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
        throw new StorageException("Could not zap", e);
      }
    }
    // if no error received, nothing more to do
  }

  @Override
  public void pluginEvent(GeigerUrl url, Message msg) {
    // create the needed objects
    synchronized (receivedMessages) {
      receivedMessages.put(url.getPath(), msg);
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
    byteArrayOutputStream.write(criteria.toByteArray());
    try {
      localApi.sendMessage(LocalApi.MASTER, new Message(id, LocalApi.MASTER,
          MessageType.STORAGE_EVENT,
          new GeigerUrl(LocalApi.MASTER, command + "/" + identifier),
          byteArrayOutputStream.toByteArray()));
    } catch (MalformedUrlException e) {
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
      localApi.sendMessage(LocalApi.MASTER, new Message(id, LocalApi.MASTER,
          MessageType.STORAGE_EVENT,
          new GeigerUrl(LocalApi.MASTER, command + "/" + identifier),
          byteArrayOutputStream.toByteArray()));
    } catch (MalformedUrlException e) {
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
    } else {
      SearchCriteria.fromByteArray(response.getPayload());
      // TODO return directly if no array is needed
      return new SearchCriteria[0];
    }
  }
}
