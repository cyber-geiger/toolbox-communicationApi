library geiger_api;

import 'dart:io';

import 'package:communicationapi/src/communication/communication_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

import 'geiger_api.dart';
import 'message.dart';
import 'message_type.dart';
import 'plugin_listener.dart';
import 'geiger_url.dart';

/// [StorageEventHandler] processes StorageEvents accordingly.
class StorageEventHandler with PluginListener {
  final CommunicationApi localApi;
  final StorageController storageController;
  bool isMaster = false;

  StorageEventHandler(this.localApi, this.storageController);

  /// Decides which storage method has been called for [msg].
  void storageEventParser(Message msg) {
    if (GeigerApi.MASTER == msg.targetId) {
      isMaster = true;
    }
    var urlParts = (msg.action!.path)??''.split('/');
    var action = urlParts[0];
    var identifier = urlParts[1];
    var optionalArgs = urlParts.sublist(2, urlParts.length);
    switch (action) {
      case 'getNode':
        getNode(msg, identifier, optionalArgs);
        break;
      case 'addNode':
        addNode(msg, identifier, optionalArgs);
        break;
      case 'updateNode':
        updateNode(msg, identifier, optionalArgs);
        break;
      case 'removeNode':
        deleteNode(msg, identifier, optionalArgs);
        break;
      case 'getValue':
        getValue(msg, identifier, optionalArgs);
        break;
      case 'addValue':
        addValue(msg, identifier, optionalArgs);
        break;
      case 'updateValue':
        updateValue(msg, identifier, optionalArgs);
        break;
      case 'removeValue':
        deleteValue(msg, identifier, optionalArgs);
        break;
      case 'rename':
        rename(msg, identifier, optionalArgs);
        break;
      case 'search':
        search(msg, identifier, optionalArgs);
        break;
      case 'registerChangeListener':
        registerChangeListener(msg, identifier, optionalArgs);
        break;
      case 'close':
        close(msg, identifier, optionalArgs);
        break;
      case 'flush':
        flush(msg, identifier, optionalArgs);
        break;
      case 'zap':
        zap(msg, identifier, optionalArgs);
        break;
      default:
        break;
    }
  }

  static String join(String delimiter, List<String> args) {
    var ret = StringBuffer();
    for (var arg in args) {
      if (ret.length > 0) {
        ret.write(delimiter);
      }
      ret.write(arg);
    }
    return ret.toString();
  }

  /// Calls [GenericController.getNode] and sends the Node back to the [msg] source.
  void getNode(Message msg, String identifier, List<String> optionalArgs) {
    var path = join('/', optionalArgs);
    try {
      var node = storageController.get(path);
      ByteSink bos =ByteSink();
      node.toByteArrayStream(bos);
      List<int> payload = bos.toByteArray();
      localApi.sendMessage(
          msg.sourceId,
          Message(
              msg.targetId,
              msg.sourceId,
              MessageType.STORAGE_SUCCESS,
              GeigerUrl(
                  msg.sourceId, (('getNode/' + identifier) + '/') + path),
              payload));
    } on IOException catch (e) {
      try {
        ByteSink bos =ByteSink();
        StorageException('Could not get Node' + path, e).toByteArrayStream(bos);
        List<int> payload = bos.toByteArray();
        localApi.sendMessage(
            msg.sourceId,
            Message(
                msg.targetId,
                msg.getSourceId(),
                MessageType.STORAGE_ERROR,
                GeigerUrl(msg.getSourceId()!, 'getNode/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Calls [GenericController.addNode].
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  void addNode(Message msg, String identifier, List<String> optionalArgs) {
    Node node;
    try {
      node = NodeImpl.fromByteArrayStream(ByteStream(null,msg.getPayload());
      storageController.add(node);
    } on Exception catch (e) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not add Node', e).toByteArrayStream(bos);
        bos.close();
        List<int> payload = bos.toByteArray();
        localApi.sendMessage(
            msg.getSourceId()!,
            Message(
                msg.targetId,
                msg.getSourceId(),
                MessageType.STORAGE_ERROR,
                GeigerUrl(msg.getSourceId()!, 'addNode/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Calls [GenericController.updateNode].
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  void updateNode(Message msg, String identifier, List<String> optionalArgs) {
    Node node;
    try {
      node = NodeImpl.fromByteArrayStream(ByteStream(null,msg.getPayload()));
      storageController.update(node);
    } on Exception catch (e) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not update Node', e).toByteArrayStream(bos);
        List<int> payload = bos.toByteArray();
        localApi.sendMessage(
            msg.getSourceId()!,
            Message(
                msg.targetId,
                msg.getSourceId(),
                MessageType.STORAGE_ERROR,
                GeigerUrl(msg.getSourceId()!, 'updateNode/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Calls [GenericController.deleteNode] and sends the deleted node back to the [msg] source.
  void deleteNode(Message msg, String identifier, List<String> optionalArgs) {
    try {
      var node = storageController.delete(optionalArgs[0]);
      if (node != null) {
        ByteSink bos =ByteSink();
        node.toByteArrayStream(bos);
        bos.close();
        List<int> payload = await bos.bytes();
        localApi.sendMessage(
            msg.getSourceId()!,
            Message(
                msg.targetId,
                msg.getSourceId(),
                MessageType.STORAGE_SUCCESS,
                GeigerUrl(msg.targetId!, 'deleteNode/' + identifier),
                payload));
      } else {
        localApi.sendMessage(
            msg.getSourceId()!,
            Message(
                msg.targetId,
                msg.getSourceId(),
                MessageType.STORAGE_SUCCESS,
                GeigerUrl(msg.targetId!, 'deleteNode/' + identifier)));
      }
    } on Exception catch (e) {
      try {
        ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos =
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
        StorageException('Could not delete Node', e).toByteArrayStream(bos);
        List<int> payload = bos.toByteArray();
        localApi.sendMessage(
            msg.getSourceId()!,
            Message(
                msg.targetId,
                msg.getSourceId(),
                MessageType.STORAGE_ERROR,
                GeigerUrl(msg.getSourceId()!, 'deleteNode/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Calls [GenericController.getValue] and sends the [NodeValue] back to the [msg] source.
  void getValue(Message msg, String identifier, List<String> optionalArgs) {
    try {
      var nodeValue =
          storageController.getValue(optionalArgs[0], optionalArgs[1]);
      if (nodeValue != null) {
        ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos =
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
        nodeValue.toByteArrayStream(bos);
        List<int> payload = bos.toByteArray();
        localApi.sendMessage(
            msg.getSourceId()!,
            Message(
                msg.targetId,
                msg.getSourceId(),
                MessageType.STORAGE_SUCCESS,
                GeigerUrl(msg.targetId!, 'getValue/' + identifier),
                payload));
      } else {
        localApi.sendMessage(
            msg.getSourceId()!,
            Message(
                msg.targetId,
                msg.getSourceId(),
                MessageType.STORAGE_SUCCESS,
                GeigerUrl(msg.targetId!, 'getValue/' + identifier)));
      }
    } on Exception catch (e) {
      try {
        ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos =
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
        StorageException('Could not get NodeValue', e).toByteArrayStream(bos);
        List<int> payload = bos.toByteArray();
        localApi.sendMessage(
            msg.getSourceId()!,
            Message(
                msg.targetId,
                msg.getSourceId(),
                MessageType.STORAGE_ERROR,
                GeigerUrl(msg.getSourceId()!, 'getValue/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Calls [GenericController.addValue].
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  void addValue(Message msg, String identifier, List<String> optionalArgs) {
    NodeValue nodeValue;
    try {
      nodeValue = NodeValueImpl.fromByteArrayStream(
          ch_fhnw_geiger_totalcross_ByteArrayInputStream(msg.getPayload()));
      storageController.addValue(optionalArgs[0], nodeValue);
    } on Exception catch (e) {
      try {
        ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos =
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
        StorageException('Could not add NodeValue', e).toByteArrayStream(bos);
        List<int> payload = bos.toByteArray();
        localApi.sendMessage(
            msg.getSourceId()!,
            Message(
                msg.targetId,
                msg.getSourceId(),
                MessageType.STORAGE_ERROR,
                GeigerUrl(msg.getSourceId()!, 'addValue/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Calls [GenericController.updateValue].
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  void updateValue(Message msg, String identifier, List<String> optionalArgs) {
    NodeValue nodeValue;
    try {
      nodeValue = NodeValueImpl.fromByteArrayStream(
          ch_fhnw_geiger_totalcross_ByteArrayInputStream(msg.getPayload()));
      storageController.updateValue(optionalArgs[0], nodeValue);
    } on Exception catch (e) {
      try {
        ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos =
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
        StorageException('Could not update NodeValue', e)
            .toByteArrayStream(bos);
        List<int> payload = bos.toByteArray();
        localApi.sendMessage(
            msg.getSourceId()!,
            Message(
                msg.targetId,
                msg.getSourceId(),
                MessageType.STORAGE_ERROR,
                GeigerUrl(msg.getSourceId()!, 'updateValue/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Either calls [GenericController.removeValue] and sends the [NodeValue] back to the [msg] source
  /// or stores the received [NodeValue] in the storageEventObject map.
  void deleteValue(Message msg, String identifier, List<String> optionalArgs) {
    try {
      var nodeValue =
          storageController.deleteValue(optionalArgs[0], optionalArgs[1]);
      ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos =
          ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
      nodeValue.toByteArrayStream(bos);
      List<int> payload = bos.toByteArray();
      localApi.sendMessage(
          msg.getSourceId()!,
          Message(
              msg.targetId,
              msg.getSourceId(),
              MessageType.STORAGE_SUCCESS,
              GeigerUrl(msg.targetId!, 'deleteNodeValue/' + identifier),
              payload));
    } on Exception catch (e) {
      try {
        ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos =
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
        StorageException('Could not delete NodeValue', e)
            .toByteArrayStream(bos);
        List<int> payload = bos.toByteArray();
        localApi.sendMessage(
            msg.getSourceId()!,
            Message(
                msg.targetId,
                msg.getSourceId(),
                MessageType.STORAGE_ERROR,
                GeigerUrl(msg.getSourceId()!, 'deleteValue/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Calls [GenericController.rename]
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  void rename(Message msg, String identifier, List<String> optionalArgs) {
    try {
      storageController.rename(optionalArgs[0], optionalArgs[1]);
    } on StorageException catch (e) {
      try {
        ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos =
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
        StorageException('Could not rename Node', e).toByteArrayStream(bos);
        List<int> payload = bos.toByteArray();
        localApi.sendMessage(
            msg.getSourceId()!,
            Message(
                msg.targetId,
                msg.getSourceId(),
                MessageType.STORAGE_ERROR,
                GeigerUrl(msg.getSourceId()!, 'rename/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Calls [GenericController.search] and sends the List of Nodes back to the [msg] source.
  void search(Message msg, String identifier, List<String> optionalArgs) {
    try {
      SearchCriteria searchCriteria =
          SearchCriteria.fromByteArray(msg.getPayload());
      var nodes = storageController.search(searchCriteria);
      if (nodes.size() > 0) {
        List<int> payload;
        ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos =
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
        for (var n in nodes) {
          n.toByteArrayStream(bos);
        }
        payload = bos.toByteArray();
        localApi.sendMessage(
            msg.getSourceId()!,
            Message(
                msg.targetId,
                msg.getSourceId(),
                MessageType.STORAGE_SUCCESS,
                GeigerUrl(msg.targetId!, 'search/' + identifier),
                payload));
      } else {
        localApi.sendMessage(
            msg.getSourceId()!,
            Message(
                msg.targetId,
                msg.getSourceId(),
                MessageType.STORAGE_SUCCESS,
                GeigerUrl(msg.targetId!, 'search/' + identifier)));
      }
    } on Exception catch (e) {
      try {
        ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos =
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
        StorageException('Could not search Node', e).toByteArrayStream(bos);
        List<int> payload = bos.toByteArray();
        localApi.sendMessage(
            msg.getSourceId()!,
            Message(
                msg.targetId,
                msg.getSourceId(),
                MessageType.STORAGE_ERROR,
                GeigerUrl(msg.getSourceId()!, 'search/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Calls [GenericController.close].
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  void close(Message msg, String identifier, List<String> optionalArgs) {
    try {
      storageController.close();
    } on StorageException catch (e) {
      try {
        ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos =
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
        StorageException('Could not close', e).toByteArrayStream(bos);
        List<int> payload = bos.toByteArray();
        localApi.sendMessage(
            msg.getSourceId()!,
            Message(
                msg.targetId,
                msg.getSourceId(),
                MessageType.STORAGE_ERROR,
                GeigerUrl(msg.getSourceId()!, 'close/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Calls [GenericController.flush].
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  void flush(Message msg, String identifier, List<String> optionalArgs) {
    try {
      storageController.flush();
    } on StorageException catch (e) {
      try {
        ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos =
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
        StorageException('Could not flush', e).toByteArrayStream(bos);
        List<int> payload = bos.toByteArray();
        localApi.sendMessage(
            msg.getSourceId()!,
            Message(
                msg.targetId,
                msg.getSourceId(),
                MessageType.STORAGE_ERROR,
                GeigerUrl(msg.getSourceId()!, 'flush/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Calls [GenericController.zap].
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  void zap(Message msg, String identifier, List<String> optionalArgs) {
    try {
      storageController.zap();
    } on StorageException catch (e) {
      try {
        ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos =
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
        StorageException('Could not zap', e).toByteArrayStream(bos);
        List<int> payload = bos.toByteArray();
        localApi.sendMessage(
            msg.getSourceId()!,
            Message(
                msg.targetId,
                msg.getSourceId(),
                MessageType.STORAGE_ERROR,
                GeigerUrl(msg.getSourceId()!, 'zap/' + identifier),
                payload));
      } on IOException {}
    }
  }

  @override
  void pluginEvent(GeigerUrl url, Message msg) {
    storageEventParser(msg);
  }

  /// Registers a [StorageListener].
  void registerChangeListener(
      Message msg, String identifier, List<String> optionalArgs) {
    msg.getPayload();
    StorageListener? listener;
    SearchCriteria criteria = SearchCriteria.fromByteArray(msg.getPayload());
  }

  List<SearchCriteria> deregisterChangeListener(StorageListener listener) {
    return [];
  }
}
