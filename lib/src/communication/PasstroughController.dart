import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'MalformedUrlException.dart';
import 'package:localstorage/localstorage.dart';

import 'GeigerUrl.dart';
import 'LocalApi.dart';
import 'Message.dart';
import 'MessageType.dart';
import 'PluginListener.dart';

/// Class for handling storage events in Plugins.
class PasstroughController
    with StorageController, PluginListener, ChangeRegistrar {
  final LocalApi localApi;
  final String id;
  final Object comm = Object();
  final Map<String, Message> receivedMessages = HashMap();

  /// Creates a [PasstroughController] for the given [api] and plugin (provide its [id]).
  PasstroughController(this.localApi, this.id) {
    localApi.registerListener([
      MessageType.STORAGE_EVENT,
      MessageType.STORAGE_SUCCESS,
      MessageType.STORAGE_ERROR
    ], this, true);
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
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

  @override
  void rename(String oldPath, String newPathOrName) {
    var command = 'deleteValue';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      // this will not work if either the old or the new path contains any "/"
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

  @override
  List<Node> search(SearchCriteria criteria) {
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
        var receivedPayload = response.getPayload();
        int numNodes = GeigerCommunicator.byteArrayToInt(
            receivedPayload?.sublist(0, 4));
        var receivedNodes = receivedPayload?.sublist(
            5, receivedPayload.length);
        var nodes = List<Node>.empty(growable: true);
        for (var i = 0; i < numNodes; (++i)) {
          // does this advance the stream? after every read the next one needs to start at
          // the ned of the last read + 1
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

  @override
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

  @override
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

  @override
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

  @override
  void pluginEvent(GeigerUrl url, Message msg) {
    synchronized(receivedMessages, {
    receivedMessages.put(url.getPath(), msg);
    });
    synchronized(comm, {
    comm.notifyAll();
    });
  }

  /// Register a [StorageListener] for a Node defined by [SearchCriteria].
  ///
  /// Throws a [StorageException] if the listener could not be registered.
  @override
  void registerChangeListener(StorageListener listener,
      SearchCriteria criteria) {
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

  /// Deregister a [StorageListener] from the Storage and returns the associated [SearchCriteria].
  ///
  /// Throws a [StorageException] if listener could not be deregistered.
  @override
  List<SearchCriteria> deregisterChangeListener(StorageListener listener) {
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
      SearchCriteria.fromByteArray(response.getPayload());
      return [];
    }
  }

}
