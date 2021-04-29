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
import java.util.Map;
import java.util.stream.Collectors;

/**
 * StorageEventHandler processes StorageEvents accordingly.
 */
public class StorageEventHandler {

  private LocalApi localApi;
  private StorageController storageController;
  private Map<String, Object> storedObjects;
  private Message msg;
  boolean isMaster = false;

  public StorageEventHandler(LocalApi api, StorageController sc, Map<String, Object> so) {
    this.localApi = api;
    this.storageController = sc;
    this.storedObjects = so;
  }

  /**
   * <p>Decides which storage method has been called.</p>
   *
   * @param msg the received message to process
   */
  public void storageEventParser(Message msg) {
    if(LocalApi.MASTER.equals(msg.getTargetId())) {
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
      case "storageException":
        storageException(msg, identifier, optionalArgs);
        break;
      default:
        // TODO no valid action, throw Storage Exception?
        break;
    }
  }

  /**
   * Either calls getNode on the GenericController and sends the Node back to the caller,
   * or stores the received Node in the storageEventObject map.
   *
   * @param msg received message to process
   * @param identifier used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void getNode(Message msg, String identifier, String[] optionalArgs) {
    // This uses Arrays stream, because string.join does not exists in TotalCross
    String path = Arrays.stream(optionalArgs).collect(Collectors.joining("/"));
    // msg is a request -> create response
    try {
      Node node = storageController.get(path);
      ByteArrayOutputStream bos = new ByteArrayOutputStream();
      node.toByteArrayStream(bos);
      byte[] payload = bos.toByteArray();
      localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
          MessageType.STORAGE_EVENT,
          new GeigerUrl(msg.getTargetId(), "getNode/" + identifier + "/" + path), payload));
    } catch (IOException e) {
      // TODO error handling
      e.printStackTrace();
    }
  }

  /**
   * Either calls addNode on the GenericController or throws StorageException,
   * because addNode is never appropriate within a Plugin
   *
   * @param msg received message to process
   * @param identifier used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void addNode(Message msg, String identifier, String[] optionalArgs) {
    // msg is a request -> create response
    Node node = null;
    try {
      node = NodeImpl.fromByteArrayStream(new ByteArrayInputStream(msg.getPayload()));
      storageController.add(node);
    } catch (IOException e) {
      // TODO error handling
      e.printStackTrace();
    } catch (StorageException se) {
      // TODO relay storageexception back to plugin
      // TODO how to throw Storageexception if other side is not waiting on response?
      String nodePath = (node == null) ? "null" : node.getPath();
      localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
          MessageType.STORAGE_EVENT, new GeigerUrl(msg.getTargetId(),
          "storageException/" + nodePath + "/faileToAddNode")));
    }
  }

  /**
   * Either calls updateNode on the GenericController or throws StorageException,
   * because updateNode is never appropriate within a Plugin
   *
   * @param msg received message to process
   * @param identifier used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void updateNode(Message msg, String identifier, String[] optionalArgs) {
      // msg is a request without response
      Node node = null;
      try {
        node = NodeImpl.fromByteArrayStream(new ByteArrayInputStream(msg.getPayload()));
        storageController.update(node);
      } catch (IOException e) {
        // TODO error handling
        e.printStackTrace();
      } catch (StorageException se) {
        // TODO relay storageexception back to plugin
        // TODO how to throw Storageexception if other side is not waiting on response?
        String nodePath = (node == null) ? "null" : node.getPath();
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_EVENT, new GeigerUrl(msg.getTargetId(),
            "storageException/" + nodePath + "/failedToUpdateNode")));
      }
  }

  /**
   * Either calls removeNode on the GenericController and sends the Node back to the caller,
   * or stores the received Node in the storageEventObject map.
   *
   * @param msg received message to process
   * @param identifier used to identify return objects inside the caller
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
            MessageType.STORAGE_EVENT, new GeigerUrl(msg.getTargetId(),
            "deleteNode/" + identifier), payload));
      } else {
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_EVENT, new GeigerUrl(msg.getTargetId(),
            "deleteNode/" + identifier)));
      }
    } catch (IOException e) {
      // TODO error handling
      e.printStackTrace();
    } catch (StorageException se) {
      // TODO relay storageexception back to plugin
      // TODO how to throw Storageexception if other side is not waiting on response?
      localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
          MessageType.STORAGE_EVENT, new GeigerUrl(msg.getTargetId(),
          "storageException/" + optionalArgs[0] + "/failedToRemoveNode")));
    }
  }

  /**
   * Either calls getValue on the GenericController and sends the NodeValue back to the caller,
   * or stores the received NodeValue in the storageEventObject map.
   *
   * @param msg received message to process
   * @param identifier used to identify return objects inside the caller
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
            MessageType.STORAGE_EVENT, new GeigerUrl(msg.getTargetId(),
            "getValue/" + identifier), payload));
      } else {
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_EVENT, new GeigerUrl(msg.getTargetId(),
            "getValue/" + identifier)));
      }
    } catch (IOException e) {
      // TODO error handling
      e.printStackTrace();
    } catch (StorageException se) {
      // TODO relay storageexception back to plugin
      // TODO how to throw Storageexception if other side is not waiting on response?
      localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
          MessageType.STORAGE_EVENT, new GeigerUrl(msg.getTargetId(),
          "storageException/" + optionalArgs[0] + "/failedToGetNodeValue")));
    }
  }

  /**
   * Either calls addValue on the GenericController or throws StorageException,
   * because addValue is never appropriate within a Plugin
   *
   * @param msg received message to process
   * @param identifier used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void addValue(Message msg, String identifier, String[] optionalArgs) {
    // msg is a request without response
    NodeValue nodeValue = null;
    try {
      nodeValue = NodeValueImpl.fromByteArrayStream(new ByteArrayInputStream(msg.getPayload()));
      storageController.addValue(optionalArgs[0], nodeValue);
    } catch (IOException e) {
      // TODO error handling
      e.printStackTrace();
    } catch (StorageException se) {
      // TODO relay storageexception back to plugin
      // TODO how to throw Storageexception if other side is not waiting on response?
      localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
          MessageType.STORAGE_EVENT, new GeigerUrl(msg.getTargetId(),
          "storageException/" + optionalArgs[0] + "/failedToAddNodeValue")));
    }
  }

  /**
   * Either calls updateValue on the GenericController or throws StorageException,
   * because updateValue is never appropriate within a Plugin
   *
   * @param msg received message to process
   * @param identifier used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void updateValue(Message msg, String identifier, String[] optionalArgs) {
    // msg is a request without response
    NodeValue nodeValue = null;
    try {
      nodeValue = NodeValueImpl.fromByteArrayStream(new ByteArrayInputStream(msg.getPayload()));
      storageController.updateValue(optionalArgs[0], nodeValue);
    } catch (IOException e) {
      // TODO error handling
      e.printStackTrace();
    } catch (StorageException se) {
      // TODO relay storageexception back to plugin
      // TODO how to throw Storageexception if other side is not waiting on response?
      localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
          MessageType.STORAGE_EVENT, new GeigerUrl(msg.getTargetId(),
          "storageException/" + optionalArgs[0] + "/failedToUpdateNodeValue")));
    }
  }

  /**
   * Either calls removeValue on the GenericController and sends the NodeValue back to the caller,
   * or stores the received NodeValue in the storageEventObject map.
   *
   * @param msg received message to process
   * @param identifier used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void deleteValue(Message msg, String identifier, String[] optionalArgs) {
    // msg is a request -> create response
    try {
      // TODO sanity checks for path? see storageEventParser, handling of path arguments
      // TODO change to deleteValue after storagecontroller interface changed
      NodeValue nodeValue = storageController.removeValue(optionalArgs[0], optionalArgs[1]);
      ByteArrayOutputStream bos = new ByteArrayOutputStream();
      nodeValue.toByteArrayStream(bos);
      byte[] payload = bos.toByteArray();
      localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
          MessageType.STORAGE_EVENT, new GeigerUrl(msg.getTargetId(),
          "deleteNodeValue/" + identifier), payload));
    } catch (IOException e) {
      // TODO error handling
      e.printStackTrace();
    } catch (StorageException se) {
      // TODO relay storageexception back to plugin
      // TODO how to throw Storageexception if other side is not waiting on response?
      localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
          MessageType.STORAGE_EVENT, new GeigerUrl(msg.getTargetId(),
          "storageException/" + optionalArgs[0] + "/" +
              optionalArgs[1] + "/failedToRemoveNodeValue")));
    }
  }

  /**
   * Either calls rename on the GenericController or throws StorageException,
   * because rename is never appropriate within a Plugin
   *
   * @param msg received message to process
   * @param identifier used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void rename(Message msg, String identifier, String[] optionalArgs) {
    // msg is a request without response
    try {
      storageController.rename(optionalArgs[0], optionalArgs[1]);
    } catch (StorageException se) {
      // TODO relay storageexception back to plugin
      // TODO how to throw Storageexception if other side is not waiting on response?
      localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
          MessageType.STORAGE_EVENT, new GeigerUrl(msg.getTargetId(),
          "storageException/" + optionalArgs[0] + "/failedToRenameNode")));
    }
  }

  /**
   * Either calls search on the GenericController and sends the List of Nodes back to the caller,
   * or stores the received List of Nodes in the storageEventObject map.
   *
   * @param msg received message to process
   * @param identifier used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void search(Message msg, String identifier, String[] optionalArgs) {
    // msg is a request -> create response
    try {
      // TODO searchCriteria serialization
      // deserialize searchCriteria
      SearchCriteria searchCriteria = new SearchCriteria();
      List<Node> nodes = storageController.search(searchCriteria);
      if(nodes.size() > 0) {
        // TODO cleaner list serialization?
        byte[] payload;
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        for (Node n : nodes) {
          n.toByteArrayStream(bos);
        }
        payload = bos.toByteArray();
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_EVENT, new GeigerUrl(msg.getTargetId(),
            "search/" + identifier), payload));
      } else {
        localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.STORAGE_EVENT, new GeigerUrl(msg.getTargetId(),
            "search/" + identifier)));
      }
    } catch (IOException e) {
      // TODO error handling
      e.printStackTrace();
    } catch (StorageException se) {
      // TODO relay storageexception back to plugin
      // TODO how to throw Storageexception if other side is not waiting on response?
      localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
          MessageType.STORAGE_EVENT, new GeigerUrl(msg.getTargetId(),
          "storageException/" + "failedToSearchNodes")));
    }
  }

  /**
   * Either calls close on the GenericController or throws StorageException,
   * because close is never appropriate within a Plugin
   *
   * @param msg received message to process
   * @param identifier used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void close(Message msg, String identifier, String[] optionalArgs) {
    // msg is a request without response
    try {
      storageController.close();
    } catch (StorageException se) {
      // TODO relay storageexception back to plugin
      // TODO how to throw Storageexception if other side is not waiting on response?
      localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
          MessageType.STORAGE_EVENT, new GeigerUrl(msg.getTargetId(),
          "storageException/" + "/failedToCloseDatabaseConnections")));
    }
  }

  /**
   * Either calls flush on the GenericController or throws StorageException,
   * because flush is never appropriate within a Plugin
   *
   * @param msg received message to process
   * @param identifier used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void flush(Message msg, String identifier, String[] optionalArgs) {
    // msg is a request without response
    try {
      storageController.flush();
    } catch (StorageException se) {
      // TODO relay storageexception back to plugin
      // TODO how to throw Storageexception if other side is not waiting on response?
      localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
          MessageType.STORAGE_EVENT, new GeigerUrl(msg.getTargetId(),
          "storageException/" + "/failedToFlushDatabaseContent")));
    }
  }

  /**
   * Either calls zap on the GenericController or throws StorageException,
   * because zap is never appropriate within a Plugin
   *
   * @param msg received message to process
   * @param identifier used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void zap(Message msg, String identifier, String[] optionalArgs) {
    // msg is a request without response
    try {
      storageController.zap();
    } catch (StorageException se) {
      // TODO relay storageexception back to plugin
      // TODO how to throw Storageexception if other side is not waiting on response?
      localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
          MessageType.STORAGE_EVENT, new GeigerUrl(msg.getTargetId(),
          "storageException/" + "/failedToClearDatabase")));
    }
  }

  /**
   * Returns StorageException to the caller.
   *
   * @param msg received message to process
   * @param identifier used to identify return objects inside the caller
   * @param optionalArgs string arguments used for the called method
   */
  private void storageException(Message msg, String identifier, String[] optionalArgs) {
    // TODO throw exception
    // TODO how to handle these exceptions thrown with the plugin?
  }


}
