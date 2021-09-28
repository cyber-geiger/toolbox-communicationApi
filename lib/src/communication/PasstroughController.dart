import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:communicationapi/src/totalcross/MalformedUrlException.dart';
import 'package:localstorage/localstorage.dart';

import 'GeigerUrl.dart';
import 'LocalApi.dart';
import 'Message.dart';
import 'MessageType.dart';
import 'PluginListener.dart';

/// <p>Class for handling storage events in Plugins.</p>
class PasstroughController
    with StorageController, PluginListener, ChangeRegistrar {
  final LocalApi localApi;
  final String id;
  final Object comm = Object();
  final Map<String, Message> receivedMessages = HashMap();

  /// <p>Constructor for PasstroughController.</p>
  /// @param api the LocalApi it belongs to
  /// @param id  the PluginId it belongs to
  PasstroughController(this.localApi, this.id) {
    localApi.registerListener([
      MessageType.STORAGE_EVENT,
      MessageType.STORAGE_SUCCESS,
      MessageType.STORAGE_ERROR
    ], this);
  }

  Message? waitForResult(String command, String identifier) {
    var token = command + '/' + identifier;
    var start = DateTime
        .now()
        .millisecondsSinceEpoch;
    while (receivedMessages[token] == null) {
      // try {
      // synchronized(comm, {
      // comm.wait(1000);
      sleep(Duration(seconds: 1))
      // });
      /*} on InterruptedException catch (e) {
                e.printStackTrace();
            }*/
      if ((DateTime
          .now()
          .millisecondsSinceEpoch - start) > 5000) {
        throw Exception('Lost communication while waiting for ' + token);
      }
    }
    return receivedMessages[token];
  }

  Node get(String path) {
    var command = 'getNode';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      localApi.sendMessage(LocalApi.MASTER, Message(
          id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          GeigerUrl(id, (((command + '/') + identifier) + '/') + path)));
    } on MalformedUrlException catch (e) {}
    Message response = waitForResult(command, identifier);
    try {
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      } else {
        return NodeImpl.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      }
    } on IOException catch (e) {
      throw StorageException('Could not get Node', e);
    }
  }

  Node getNodeOrTombstone(String path) {
    var command = 'getNodeOrTombstone';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      localApi.sendMessage(LocalApi.MASTER, Message(
          id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          GeigerUrl(id, (((command + '/') + identifier) + '/') + path)));
    } on MalformedUrlException catch (e) {}
    Message response = waitForResult(command, identifier);
    try {
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      } else {
        return NodeImpl.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      }
    } on IOException catch (e) {
      throw StorageException('Could not get Node', e);
    }
  }

  void add(Node node) {
    var command = 'addNode';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
      node.toByteArrayStream(bos);
      List<int> payload = bos.toByteArray();
      var m = Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          GeigerUrl(id, (command + '/') + identifier), payload);
      localApi.sendMessage(LocalApi.MASTER, m);
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      }
    } on IOException catch (e) {
      throw StorageException('Could not add Node', e);
    }
  }

  void update(Node node) {
    var command = 'updateNode';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
      node.toByteArrayStream(bos);
      List<int> payload = bos.toByteArray();
      var m = Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          GeigerUrl(id, (command + '/') + identifier), payload);
      localApi.sendMessage(LocalApi.MASTER, m);
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      }
    } on IOException catch (e) {
      throw StorageException('Could not update Node', e);
    }
  }

  bool addOrUpdate(Node node) {
    var command = 'addOrUpdateNode';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
      node.toByteArrayStream(bos);
      List<int> payload = bos.toByteArray();
      var m = Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          GeigerUrl(id, (command + '/') + identifier), payload);
      localApi.sendMessage(LocalApi.MASTER, m);
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      }
      return true;
    } on IOException catch (e) {
      throw StorageException('Could not add or update Node', e);
    }
  }

  Node delete(String path) {
    var command = 'deleteNode';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      localApi.sendMessage(LocalApi.MASTER, Message(
          id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          GeigerUrl(id, (((command + '/') + identifier) + '/') + path)));
    } on MalformedUrlException catch (e) {}
    Message response = waitForResult(command, identifier);
    try {
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      } else {
        return NodeImpl.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      }
    } on IOException catch (e) {
      throw StorageException('Could not delete Node', e);
    }
  }

  NodeValue getValue(String path, String key) {
    var command = 'getValue';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      localApi.sendMessage(LocalApi.MASTER, Message(
          id, LocalApi.MASTER, MessageType.STORAGE_EVENT, GeigerUrl(
          id, (((((command + '/') + identifier) + '/') + path) + '/') + key)));
    } on MalformedUrlException catch (e) {}
    Message response = waitForResult(command, identifier);
    try {
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      } else {
        return NodeValueImpl.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      }
    } on IOException catch (e) {
      throw StorageException('Could not get Value', e);
    }
  }

  void addValue(String path, NodeValue value) {
    var command = 'addValue';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
      value.toByteArrayStream(bos);
      List<int> payload = bos.toByteArray();
      var m = Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          GeigerUrl(id, (((command + '/') + identifier) + '/') + path),
          payload);
      localApi.sendMessage(LocalApi.MASTER, m);
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      }
    } on IOException catch (e) {
      throw StorageException('Could not add NodeValue', e);
    }
  }

  void updateValue(String nodeName, NodeValue value) {
    var command = 'updateValue';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
      value.toByteArrayStream(bos);
      List<int> payload = bos.toByteArray();
      var m = Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          GeigerUrl(id, (((command + '/') + identifier) + '/') + nodeName),
          payload);
      localApi.sendMessage(LocalApi.MASTER, m);
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      }
    } on IOException catch (e) {
      throw StorageException('Could not update NodeValue', e);
    }
  }

  NodeValue deleteValue(String path, String key) {
    var command = 'deleteValue';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      localApi.sendMessage(LocalApi.MASTER, Message(
          id, LocalApi.MASTER, MessageType.STORAGE_EVENT, GeigerUrl(
          id, (((((command + '/') + identifier) + '/') + path) + '/') + key)));
    } on MalformedUrlException catch (e) {}
    Message response = waitForResult(command, identifier);
    try {
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      } else {
        return NodeValueImpl.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      }
    } on IOException catch (e) {
      throw StorageException('Could not delete Value', e);
    }
  }

  void rename(String oldPath, String newPathOrName) {
    var command = 'deleteValue';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      localApi.sendMessage(LocalApi.MASTER, Message(
          id, LocalApi.MASTER, MessageType.STORAGE_EVENT, GeigerUrl(id,
          (((((command + '/') + identifier) + '/') + oldPath) + '/') +
              newPathOrName)));
    } on MalformedUrlException catch (e) {}
    Message response = waitForResult(command, identifier);
    if (response.getType() == MessageType.STORAGE_ERROR) {
      try {
        throw StorageException.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      } on IOException catch (e) {
        throw StorageException('Could not rename Node', e);
      }
    }
  }

  java_util_List<Node> search(
      ch_fhnw_geiger_localstorage_SearchCriteria criteria) {
    var command = 'search';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
      criteria.toByteArrayStream(bos);
      List<int> payload = bos.toByteArray();
      var m = Message(id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          GeigerUrl(id, (command + '/') + identifier), payload);
      localApi.sendMessage(LocalApi.MASTER, m);
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      } else {
        List<int> receivedPayload = response.getPayload();
        int numNodes = GeigerCommunicator.byteArrayToInt(
            Arrays.copyOfRange(receivedPayload, 0, 4));
        List<int> receivedNodes = Arrays.copyOfRange(
            receivedPayload, 5, receivedPayload.length);
        java_util_List<Node> nodes = java_util_ArrayList();
        for (var i = 0; i < numNodes; (++i)) {
          nodes.add(NodeImpl.fromByteArrayStream(
              ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                  receivedNodes)));
        }
        return nodes;
      }
    } on IOException catch (e) {
      throw StorageException('Could not start Search', e);
    }
  }

  void close() {
    var command = 'close';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      localApi.sendMessage(LocalApi.MASTER, Message(
          id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          GeigerUrl(id, (command + '/') + identifier)));
    } on MalformedUrlException catch (e) {}
    Message response = waitForResult(command, identifier);
    if (response.getType() == MessageType.STORAGE_ERROR) {
      try {
        throw StorageException.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      } on IOException catch (e) {
        throw StorageException('Could not close', e);
      }
    }
  }

  void flush() {
    var command = 'flush';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      localApi.sendMessage(LocalApi.MASTER, Message(
          id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          GeigerUrl(id, (command + '/') + identifier)));
    } on MalformedUrlException catch (e) {}
    Message response = waitForResult(command, identifier);
    if (response.getType() == MessageType.STORAGE_ERROR) {
      try {
        throw StorageException.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      } on IOException catch (e) {
        throw StorageException('Could not flush', e);
      }
    }
  }

  void zap() {
    var command = 'zap';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      localApi.sendMessage(LocalApi.MASTER, Message(
          id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          GeigerUrl(id, (command + '/') + identifier)));
    } on MalformedUrlException catch (e) {}
    Message response = waitForResult(command, identifier);
    if (response.getType() == MessageType.STORAGE_ERROR) {
      try {
        throw StorageException.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      } on IOException catch (e) {
        throw StorageException('Could not zap', e);
      }
    }
  }

  void pluginEvent(GeigerUrl url, Message msg) {
    synchronized(receivedMessages, {
    receivedMessages.put(url.getPath(), msg);
    });
    synchronized(comm, {
    comm.notifyAll();
    });
  }

  /// Register a StorageListener for a Node defined by SearchCriteria.
  /// @param listener StorageListener to be registered
  /// @param criteria SearchCriteria to search for the Node
  /// @throws StorageException if the listener could not be registered
  void registerChangeListener(
      ch_fhnw_geiger_localstorage_StorageListener listener,
      ch_fhnw_geiger_localstorage_SearchCriteria criteria) {
    var command = 'registerChangeListener';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    ch_fhnw_geiger_totalcross_ByteArrayOutputStream byteArrayOutputStream = ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
    byteArrayOutputStream.write(criteria.toByteArray());
    try {
      localApi.sendMessage(LocalApi.MASTER, Message(
          id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          GeigerUrl(LocalApi.MASTER, (command + '/') + identifier),
          byteArrayOutputStream.toByteArray()));
    } on MalformedUrlException catch (e) {}
    Message response = waitForResult(command, identifier);
    if (response.getType() == MessageType.STORAGE_ERROR) {
      try {
        throw StorageException.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      } on IOException catch (e) {
        throw StorageException('Could not rename Node', e);
      }
    }
  }

  /// Deregister a StorageListener from the Storage.
  /// @param listener the listener to Deregister
  /// @return the SearchCriteria that were deregistered
  /// @throws StorageException if listener could not be deregistered
  List<ch_fhnw_geiger_localstorage_SearchCriteria> deregisterChangeListener(
      ch_fhnw_geiger_localstorage_StorageListener listener) {
    var command = 'deregisterChangeListener';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    ch_fhnw_geiger_totalcross_ByteArrayOutputStream byteArrayOutputStream = ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
    try {
      localApi.sendMessage(LocalApi.MASTER, Message(
          id, LocalApi.MASTER, MessageType.STORAGE_EVENT,
          GeigerUrl(LocalApi.MASTER, (command + '/') + identifier),
          byteArrayOutputStream.toByteArray()));
    } on MalformedUrlException catch (e) {}
    Message response = waitForResult(command, identifier);
    if (response.getType() == MessageType.STORAGE_ERROR) {
      try {
        throw StorageException.fromByteArrayStream(
            ch_fhnw_geiger_totalcross_ByteArrayInputStream(
                response.getPayload()));
      } on IOException catch (e) {
        throw StorageException('Could not rename Node', e);
      }
    } else {
      SearchCriteria_.fromByteArray(response.getPayload());
      return List<ch_fhnw_geiger_localstorage_SearchCriteria>(0);
    }
  }

}
