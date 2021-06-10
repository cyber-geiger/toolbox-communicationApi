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
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * StorageEventHandler processes StorageEvents accordingly.
 * the GeigerUrl of a response has the form protocol://targetId/command/identifier/result
 * where result is either success or error in all cases
 */
public class StorageEventHandler implements PluginListener {

  private final LocalApi localApi;
  private final StorageController storageController;
  boolean isMaster = false;

  public StorageEventHandler(LocalApi api, StorageController sc) {
    this.localApi = api;
    this.storageController = sc;
  }

  /**
   * <p>Decides which storage method has been called.</p>
   *
   * @param msg the received message to process
   */
  public void storageEventParser(Message msg) {
    if (LocalApi.MASTER.equals(msg.getTargetId())) {
      isMaster = true;
    }
    // parse GeigerUrl
    String[] urlParts = msg.getAction().getPath().split("/");
    String action = urlParts[0];
    String identifier = urlParts[1];
    String[] optionalArgs = Arrays.copyOfRange(urlParts, 2, urlParts.length);
    // TODO how to handle path + additional, arguments inside urls?
    // for example in getValue path, key if both are encoded in the Url
    // it might be hard to know when path ends and key starts

    switch (action) {
      case "getNode":
        getNode(msg, identifier, optionalArgs);
        break;
      case "addNode":
        addNode(msg, identifier, optionalArgs);
        break;
      case "updateNode":
        updateNode(msg, identifier, optionalArgs);
        break;
      case "removeNode":
        deleteNode(msg, identifier, optionalArgs);
        break;
      case "getValue":
        getValue(msg, identifier, optionalArgs);
        break;
      case "addValue":
        addValue(msg, identifier, optionalArgs);
        break;
      case "updateValue":
        updateValue(msg, identifier, optionalArgs);
        break;
      case "removeValue":
        deleteValue(msg, identifier, optionalArgs);
        break;
      case "rename":
        rename(msg, identifier, optionalArgs);
        break;
      case "search":
        search(msg, identifier, optionalArgs);
        break;
      case "close":
        close(msg, identifier, optionalArgs);
        break;
      case "flush":
        flush(msg, identifier, optionalArgs);
        break;
      case "zap":
        zap(msg, identifier, optionalArgs);
        break;
      default:
        // TODO no valid action, throw Storage Exception?
        break;
    }
  }

  private static String join(String delimiter,String[] args) {
    StringBuilder ret=new StringBuilder();
    for (String arg:args) {
      if(ret.length()>0) {
        ret.append(delimiter);
      }
      ret.append(arg);
    }
    return ret.toString();
  }

  /**
   * Calls getNode on the GenericController and sends the Node back to the caller.
   *
   * @param msg          received message to process
   * @param identifier   used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void getNode(Message msg, String identifier, String[] optionalArgs) {
    // This uses an own joiner for compatibility with TotalCross
    String path = join("/",optionalArgs);
    // msg is a request -> create response
    try {
      Node node = storageController.get(path);
      ByteArrayOutputStream bos = new ByteArrayOutputStream();
      node.toByteArrayStream(bos);
      byte[] payload = bos.toByteArray();
      localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
          MessageType.STORAGE_SUCCESS,
          new GeigerUrl(msg.getSourceId(), "getNode/" + identifier + "/" + path), payload));
    } catch (IOException e) {
      try {
        // TODO error handling
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        new StorageException("Could not get Node" + path, e).toByteArrayStream(bos);
        byte[] payload = bos.toByteArray();
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_ERROR,
            new GeigerUrl(msg.getSourceId(), "getNode/" + identifier), payload));
      } catch (IOException ioe) {
        // TODO what to do if an error occurs durin serialization of the exception?
      }
    }
  }

  /**
   * Calls addNode on the GenericController or throws StorageException.
   *
   * @param msg          received message to process
   * @param identifier   used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void addNode(Message msg, String identifier, String[] optionalArgs) {
    // msg is a request -> create response
    Node node = null;
    try {
      node = NodeImpl.fromByteArrayStream(new ByteArrayInputStream(msg.getPayload()));
      storageController.add(node);
    } catch (Exception e) {
      try {
        // TODO error handling
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        new StorageException("Could not add Node", e).toByteArrayStream(bos);
        byte[] payload = bos.toByteArray();
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_ERROR,
            new GeigerUrl(msg.getSourceId(), "addNode/" + identifier), payload));
      } catch (IOException ioe) {
        // TODO what to do if an error occurs during serialization of the exception?
      }
    }
  }

  /**
   * Calls updateNode on the GenericController or throws StorageException.
   *
   * @param msg          received message to process
   * @param identifier   used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void updateNode(Message msg, String identifier, String[] optionalArgs) {
    // msg is a request without response
    Node node = null;
    try {
      node = NodeImpl.fromByteArrayStream(new ByteArrayInputStream(msg.getPayload()));
      storageController.update(node);
    } catch (Exception e) {
      try {
        // TODO error handling
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        new StorageException("Could not update Node", e).toByteArrayStream(bos);
        byte[] payload = bos.toByteArray();
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_ERROR,
            new GeigerUrl(msg.getSourceId(), "updateNode/" + identifier), payload));
      } catch (IOException ioe) {
        // TODO what to do if an error occurs durin serialization of the exception?
      }
    }
  }

  /**
   * Calls removeNode on the GenericController and sends the Node back to the caller.
   *
   * @param msg          received message to process
   * @param identifier   used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void deleteNode(Message msg, String identifier, String[] optionalArgs) {
    // TODO has path argument, returns Node
    // msg is a request -> create response
    try {
      // TODO sanity checks for Nodepath? see storageEventParser, handling of path arguments
      Node node = storageController.delete(optionalArgs[0]);
      // node may be null
      if (node != null) {
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        node.toByteArrayStream(bos);
        byte[] payload = bos.toByteArray();
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_SUCCESS, new GeigerUrl(msg.getTargetId(),
            "deleteNode/" + identifier), payload));
      } else {
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_SUCCESS, new GeigerUrl(msg.getTargetId(),
            "deleteNode/" + identifier)));
      }
    } catch (Exception e) {
      try {
        // TODO error handling
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        new StorageException("Could not delete Node", e).toByteArrayStream(bos);
        byte[] payload = bos.toByteArray();
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_ERROR,
            new GeigerUrl(msg.getSourceId(), "deleteNode/" + identifier), payload));
      } catch (IOException ioe) {
        // TODO what to do if an error occurs durin serialization of the exception?
      }
    }
  }

  /**
   * Calls getValue on the GenericController and sends the NodeValue back to the caller.
   *
   * @param msg          received message to process
   * @param identifier   used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void getValue(Message msg, String identifier, String[] optionalArgs) {
    // msg is a request -> create response
    try {
      // TODO sanity checks for path? see storageEventParser, handling of path arguments
      NodeValue nodeValue = storageController.getValue(optionalArgs[0], optionalArgs[1]);
      // nodeValue may be null
      if (nodeValue != null) {
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        nodeValue.toByteArrayStream(bos);
        byte[] payload = bos.toByteArray();
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_SUCCESS, new GeigerUrl(msg.getTargetId(),
            "getValue/" + identifier), payload));
      } else {
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_SUCCESS, new GeigerUrl(msg.getTargetId(),
            "getValue/" + identifier)));
      }
    } catch (Exception e) {
      try {
        // TODO error handling
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        new StorageException("Could not get NodeValue", e).toByteArrayStream(bos);
        byte[] payload = bos.toByteArray();
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_ERROR,
            new GeigerUrl(msg.getSourceId(), "getValue/" + identifier), payload));
      } catch (IOException ioe) {
        // TODO what to do if an error occurs durin serialization of the exception?
      }
    }
  }

  /**
   * Calls addValue on the GenericController or throws StorageException.
   *
   * @param msg          received message to process
   * @param identifier   used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void addValue(Message msg, String identifier, String[] optionalArgs) {
    // msg is a request without response
    NodeValue nodeValue = null;
    try {
      nodeValue = NodeValueImpl.fromByteArrayStream(new ByteArrayInputStream(msg.getPayload()));
      storageController.addValue(optionalArgs[0], nodeValue);
    } catch (Exception e) {
      try {
        // TODO error handling
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        new StorageException("Could not add NodeValue", e).toByteArrayStream(bos);
        byte[] payload = bos.toByteArray();
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_ERROR,
            new GeigerUrl(msg.getSourceId(), "addValue/" + identifier), payload));
      } catch (IOException ioe) {
        // TODO what to do if an error occurs durin serialization of the exception?
      }
    }
  }

  /**
   * UpdateValue on the GenericController or throws StorageException.
   *
   * @param msg          received message to process
   * @param identifier   used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void updateValue(Message msg, String identifier, String[] optionalArgs) {
    // msg is a request without response
    NodeValue nodeValue = null;
    try {
      nodeValue = NodeValueImpl.fromByteArrayStream(new ByteArrayInputStream(msg.getPayload()));
      storageController.updateValue(optionalArgs[0], nodeValue);
    } catch (Exception e) {
      try {
        // TODO error handling
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        new StorageException("Could not update NodeValue", e).toByteArrayStream(bos);
        byte[] payload = bos.toByteArray();
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_ERROR,
            new GeigerUrl(msg.getSourceId(), "updateValue/" + identifier), payload));
      } catch (IOException ioe) {
        // TODO what to do if an error occurs durin serialization of the exception?
      }
    }
  }

  /**
   * Either calls removeValue on the GenericController and sends the NodeValue back to the caller,
   * or stores the received NodeValue in the storageEventObject map.
   *
   * @param msg          received message to process
   * @param identifier   used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void deleteValue(Message msg, String identifier, String[] optionalArgs) {
    // msg is a request -> create response
    try {
      // TODO sanity checks for path? see storageEventParser, handling of path arguments
      // TODO change to deleteValue after storagecontroller interface changed
      NodeValue nodeValue = storageController.deleteValue(optionalArgs[0], optionalArgs[1]);
      ByteArrayOutputStream bos = new ByteArrayOutputStream();
      nodeValue.toByteArrayStream(bos);
      byte[] payload = bos.toByteArray();
      localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
          MessageType.STORAGE_SUCCESS, new GeigerUrl(msg.getTargetId(),
          "deleteNodeValue/" + identifier), payload));
    } catch (Exception e) {
      try {
        // TODO error handling
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        new StorageException("Could not delete NodeValue", e).toByteArrayStream(bos);
        byte[] payload = bos.toByteArray();
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_ERROR,
            new GeigerUrl(msg.getSourceId(), "deleteValue/" + identifier), payload));
      } catch (IOException ioe) {
        // TODO what to do if an error occurs durin serialization of the exception?
      }
    }
  }

  /**
   * Calls rename on the GenericController or throws StorageException.
   *
   * @param msg          received message to process
   * @param identifier   used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void rename(Message msg, String identifier, String[] optionalArgs) {
    // msg is a request without response
    try {
      storageController.rename(optionalArgs[0], optionalArgs[1]);
    } catch (StorageException e) {
      try {
        // TODO error handling
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        new StorageException("Could not rename Node", e).toByteArrayStream(bos);
        byte[] payload = bos.toByteArray();
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_ERROR,
            new GeigerUrl(msg.getSourceId(), "rename/" + identifier), payload));
      } catch (IOException ioe) {
        // TODO what to do if an error occurs durin serialization of the exception?
      }
    }
  }

  /**
   * Either calls search on the GenericController and sends the List of Nodes back to the caller,
   * or stores the received List of Nodes in the storageEventObject map.
   *
   * @param msg          received message to process
   * @param identifier   used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void search(Message msg, String identifier, String[] optionalArgs) {
    // msg is a request -> create response
    try {
      // TODO searchCriteria serialization
      // deserialize searchCriteria
      SearchCriteria searchCriteria = new SearchCriteria();
      List<Node> nodes = storageController.search(searchCriteria);
      if (nodes.size() > 0) {
        // TODO cleaner list serialization?
        byte[] payload;
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        for (Node n : nodes) {
          n.toByteArrayStream(bos);
        }
        payload = bos.toByteArray();
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_SUCCESS, new GeigerUrl(msg.getTargetId(),
            "search/" + identifier), payload));
      } else {
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_SUCCESS, new GeigerUrl(msg.getTargetId(),
            "search/" + identifier)));
      }
    } catch (Exception e) {
      try {
        // TODO error handling
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        new StorageException("Could not search Node", e).toByteArrayStream(bos);
        byte[] payload = bos.toByteArray();
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_ERROR,
            new GeigerUrl(msg.getSourceId(), "search/" + identifier), payload));
      } catch (IOException ioe) {
        // TODO what to do if an error occurs durin serialization of the exception?
      }
    }
  }

  /**
   * Calls close on the GenericController or throws StorageException.
   *
   * @param msg          received message to process
   * @param identifier   used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void close(Message msg, String identifier, String[] optionalArgs) {
    // msg is a request without response
    try {
      storageController.close();
    } catch (StorageException e) {
      try {
        // TODO error handling
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        new StorageException("Could not close", e).toByteArrayStream(bos);
        byte[] payload = bos.toByteArray();
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_ERROR,
            new GeigerUrl(msg.getSourceId(), "close/" + identifier), payload));
      } catch (IOException ioe) {
        // TODO what to do if an error occurs durin serialization of the exception?
      }
    }
  }

  /**
   * Calls flush on the GenericController or throws StorageException.
   *
   * @param msg          received message to process
   * @param identifier   used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void flush(Message msg, String identifier, String[] optionalArgs) {
    // msg is a request without response
    try {
      storageController.flush();
    } catch (StorageException e) {
      try {
        // TODO error handling
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        new StorageException("Could not flush", e).toByteArrayStream(bos);
        byte[] payload = bos.toByteArray();
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_ERROR,
            new GeigerUrl(msg.getSourceId(), "flush/" + identifier), payload));
      } catch (IOException ioe) {
        // TODO what to do if an error occurs durin serialization of the exception?
      }
    }
  }

  /**
   * Calls zap on the GenericController or throws StorageException.
   *
   * @param msg          received message to process
   * @param identifier   used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void zap(Message msg, String identifier, String[] optionalArgs) {
    // msg is a request without response
    try {
      storageController.zap();
    } catch (StorageException e) {
      try {
        // TODO error handling
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        new StorageException("Could not zap", e).toByteArrayStream(bos);
        byte[] payload = bos.toByteArray();
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_ERROR,
            new GeigerUrl(msg.getSourceId(), "zap/" + identifier), payload));
      } catch (IOException ioe) {
        // TODO what to do if an error occurs durin serialization of the exception?
      }
    }
  }

  @Override
  public void pluginEvent(GeigerUrl url, Message msg) {
    storageEventParser(msg);
  }
}
