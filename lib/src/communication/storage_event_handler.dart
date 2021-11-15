library geiger_api;

import 'dart:io';

import 'package:communicationapi/src/communication/communication_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

import 'geiger_api.dart';
import 'geiger_url.dart';
import 'message.dart';
import 'message_type.dart';
import 'plugin_listener.dart';

/// [StorageEventHandler] processes StorageEvents accordingly.
class StorageEventHandler with PluginListener {
  final CommunicationApi _api;
  final StorageController _controller;
  bool _isMaster = false;

  StorageEventHandler(this._api, this._controller);

  /// Decides which storage method has been called for [msg].
  Future<void> storageEventParser(Message msg) async {
    if (GeigerApi.MASTER_ID == msg.targetId) {
      _isMaster = true;
    }
    final List<String> urlParts = ((msg.action!.path)).split('/');
    final String action = urlParts[0];
    final String identifier = urlParts[1];
    final List<String> optionalArgs = urlParts.sublist(2, urlParts.length);
    switch (action) {
      case 'getNode':
        await getNode(msg, identifier, optionalArgs);
        break;
      case 'addNode':
        addNode(msg, identifier, optionalArgs);
        break;
      case 'updateNode':
        updateNode(msg, identifier, optionalArgs);
        break;
      case 'removeNode':
        await deleteNode(msg, identifier, optionalArgs);
        break;
      case 'getValue':
        await getValue(msg, identifier, optionalArgs);
        break;
      case 'addValue':
        await addValue(msg, identifier, optionalArgs);
        break;
      case 'updateValue':
        await updateValue(msg, identifier, optionalArgs);
        break;
      case 'removeValue':
        await deleteValue(msg, identifier, optionalArgs);
        break;
      case 'rename':
        await rename(msg, identifier, optionalArgs);
        break;
      case 'search':
        await search(msg, identifier, optionalArgs);
        break;
      case 'registerChangeListener':
        await registerChangeListener(msg, identifier, optionalArgs);
        break;
      case 'close':
        await close(msg, identifier, optionalArgs);
        break;
      case 'flush':
        await flush(msg, identifier, optionalArgs);
        break;
      case 'zap':
        await zap(msg, identifier, optionalArgs);
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
  Future<void> getNode(
      Message msg, String identifier, List<String> optionalArgs) async {
    var path = join('/', optionalArgs);
    try {
      final Node node = await _controller.get(path);
      final ByteSink bos = ByteSink();
      node.toByteArrayStream(bos);
      bos.close();
      final List<int> payload = await bos.bytes;
      await _api.sendMessage(
          msg.sourceId,
          Message(
              msg.targetId ?? 'UNKONWN_TARGET',
              msg.sourceId,
              MessageType.STORAGE_SUCCESS,
              GeigerUrl(
                  null, msg.sourceId, (('getNode/' + identifier) + '/') + path),
              payload));
    } on IOException catch (e) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not get Node' + path, null, e)
            .toByteArrayStream(bos);
        bos.close();
        List<int> payload = await bos.bytes;
        await _api.sendMessage(
            msg.sourceId,
            Message(
                msg.targetId!,
                msg.sourceId,
                MessageType.STORAGE_ERROR,

                GeigerUrl(null,msg.sourceId, 'getNode/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Calls [GenericController.addNode].
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  Future<void> addNode(Message msg, String identifier, List<String> optionalArgs) async {
    Node node;
    try {
      node = await NodeImpl.fromByteArrayStream(ByteStream(null, msg.payload));
      _controller.add(node);
    } on Exception catch (e) {
      try {
        final ByteSink bos = ByteSink();
        StorageException('Could not add Node', null, e).toByteArrayStream(bos);
        bos.close();
        final List<int> payload = await bos.bytes;
        await _api.sendMessage(
            msg.sourceId,
            Message(
                msg.targetId!,
                msg.sourceId,
                MessageType.STORAGE_ERROR,
                GeigerUrl(null,msg.sourceId, 'addNode/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Calls [GenericController.updateNode].
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  Future<void> updateNode(Message msg, String identifier, List<String> optionalArgs) async {
    Node node;
    try {
      node = await NodeImpl.fromByteArrayStream(ByteStream(null, msg.payload));
      _controller.update(node);
    } on Exception catch (e, st) {
      try {
        final ByteSink bos = ByteSink();
        StorageException('Could not update Node', null, e, st)
            .toByteArrayStream(bos);
        bos.close();
        final List<int> payload = await bos.bytes;
        await _api.sendMessage(
            msg.sourceId,
            Message(
                msg.targetId!,
                msg.sourceId,
                MessageType.STORAGE_ERROR,
                GeigerUrl(null, msg.sourceId, 'updateNode/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Calls [GenericController.deleteNode] and sends the deleted node back to the [msg] source.
  Future<void> deleteNode(
      Message msg, String identifier, List<String> optionalArgs) async {
    try {
      final NodeImpl node = _controller.delete(optionalArgs[0]) as NodeImpl;
      if (node != null) {
        final ByteSink bos = ByteSink();
        node.toByteArrayStream(bos);
        bos.close();
        List<int> payload = await bos.bytes;
        await _api.sendMessage(
            msg.sourceId,
            Message(
                msg.targetId!,
                msg.sourceId,
                MessageType.STORAGE_SUCCESS,
                GeigerUrl(null, msg.targetId!, 'deleteNode/' + identifier),
                payload));
      } else {
        await _api.sendMessage(
            msg.sourceId,
            Message(msg.targetId!, msg.sourceId, MessageType.STORAGE_SUCCESS,
                GeigerUrl(null, msg.targetId!, 'deleteNode/' + identifier)));
      }
    } on Exception catch (e) {
      try {
        final ByteSink bos = ByteSink();
        StorageException('Could not delete Node', null, e)
            .toByteArrayStream(bos);
        bos.close();
        final List<int> payload = await bos.bytes;
        await _api.sendMessage(
            msg.sourceId,
            Message(
                msg.targetId!,
                msg.sourceId,
                MessageType.STORAGE_ERROR,
                GeigerUrl(null,msg.sourceId, 'deleteNode/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Calls [GenericController.getValue] and sends the [NodeValue] back to the [msg] source.
  Future<void> getValue(
      Message msg, String identifier, List<String> optionalArgs) async {
    try {
      NodeImpl nodeValue = _controller.getValue(optionalArgs[0], optionalArgs[1]) as NodeImpl;
      if (nodeValue != null) {
        ByteSink bos = ByteSink();
        nodeValue.toByteArrayStream(bos);
        bos.close();
        List<int> payload = await bos.bytes;
        await _api.sendMessage(
            msg.sourceId,
            Message(
                msg.targetId!,
                msg.sourceId,
                MessageType.STORAGE_SUCCESS,
                GeigerUrl(null, msg.targetId!, 'getValue/' + identifier),
                payload));
      } else {
        await _api.sendMessage(
            msg.sourceId,
            Message(msg.targetId!, msg.sourceId, MessageType.STORAGE_SUCCESS,
                GeigerUrl(null, msg.targetId!, 'getValue/' + identifier)));
      }
    } on Exception catch (e,st) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not get NodeValue', null, e)
            .toByteArrayStream(bos);
        bos.close();
        List<int> payload = await bos.bytes;
        await _api.sendMessage(
            msg.sourceId,
            Message(
                msg.targetId!,
                msg.sourceId,
                MessageType.STORAGE_ERROR,
                GeigerUrl(null,msg.sourceId, 'getValue/' + identifier),
                payload));
      } on IOException catch (e,s) {
        throw StorageException('Unable to send Storage exception to endpoint',null,e,s);
      }
    }
  }

  /// Calls [GenericController.addValue].
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  Future<void> addValue(
      Message msg, String identifier, List<String> optionalArgs) async {
    NodeValue nodeValue;
    try {
      nodeValue = await NodeValueImpl.fromByteArrayStream(
          ByteStream(null, msg.payload));
      _controller.addValue(optionalArgs[0], nodeValue);
    } on Exception catch (e) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not add NodeValue', null, e)
            .toByteArrayStream(bos);
        bos.close();
        List<int> payload = await bos.bytes;
        await _api.sendMessage(
            msg.sourceId,
            Message(
                msg.targetId!,
                msg.sourceId,
                MessageType.STORAGE_ERROR,
                GeigerUrl(null, msg.sourceId, 'addValue/' + identifier),
                payload));
      } on IOException catch(e,s)  {
        throw StorageException('Unable to send exception on adding value to endpoint',null,e,s);
      }
    }
  }

  /// Calls [GenericController.updateValue].
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  Future<void> updateValue(
      Message msg, String identifier, List<String> optionalArgs) async {
    NodeValue nodeValue;
    try {
      nodeValue = await NodeValueImpl.fromByteArrayStream(
          ByteStream(null, msg.payload));
      _controller.updateValue(optionalArgs[0], nodeValue);
    } on Exception catch (e) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not update NodeValue', null, e)
            .toByteArrayStream(bos);
        bos.close();
        List<int> payload = await bos.bytes;
        await _api.sendMessage(
            msg.sourceId,
            Message(
                msg.targetId!,
                msg.sourceId,
                MessageType.STORAGE_ERROR,
                GeigerUrl(null, msg.sourceId, 'updateValue/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Either calls [GenericController.removeValue] and sends the [NodeValue] back to the [msg] source
  /// or stores the received [NodeValue] in the storageEventObject map.
  Future<void> deleteValue(
      Message msg, String identifier, List<String> optionalArgs) async {
    try {
      NodeImpl nodeValue = _controller.deleteValue(optionalArgs[0], optionalArgs[1]) as NodeImpl;
      ByteSink bos = ByteSink();
      nodeValue.toByteArrayStream(bos);
      bos.close();
      List<int> payload = await bos.bytes;
      await _api.sendMessage(
          msg.sourceId,
          Message(
              msg.targetId!,
              msg.sourceId,
              MessageType.STORAGE_SUCCESS,
              GeigerUrl(null, msg.targetId!, 'deleteNodeValue/' + identifier),
              payload));
    } on Exception catch (e) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not delete NodeValue', null, e)
            .toByteArrayStream(bos);
        bos.close();
        final List<int> payload = await bos.bytes;
        await _api.sendMessage(
            msg.sourceId,
            Message(
                msg.targetId!,
                msg.sourceId,
                MessageType.STORAGE_ERROR,
                GeigerUrl(null, msg.sourceId, 'deleteValue/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Calls [GenericController.rename]
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  Future<void> rename(
      Message msg, String identifier, List<String> optionalArgs) async {
    try {
      _controller.rename(optionalArgs[0], optionalArgs[1]);
    } on StorageException catch (e) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not rename Node', null, e)
            .toByteArrayStream(bos);
        bos.close();
        final List<int> payload = await bos.bytes;
        await _api.sendMessage(
            msg.sourceId,
            Message(
                msg.targetId!,
                msg.sourceId,
                MessageType.STORAGE_ERROR,
                GeigerUrl(null, msg.sourceId, 'rename/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Calls [GenericController.search] and sends the List of Nodes back to the [msg] source.
  Future<void> search(
      Message msg, String identifier, List<String> optionalArgs) async {
    try {
      final SearchCriteria searchCriteria =
          await SearchCriteria.fromByteArrayStream(
              ByteStream(null, msg.payload));
      List<Node> nodes = await _controller.search(searchCriteria);
      if (nodes.length > 0) {
        List<int> payload;
        ByteSink bos = ByteSink();
        for (NodeImpl n in nodes as List<NodeImpl>) {
          n.toByteArrayStream(bos);
        }
        bos.close();
        payload = await bos.bytes;
        await _api.sendMessage(
            msg.sourceId,
            Message(
                msg.targetId!,
                msg.sourceId,
                MessageType.STORAGE_SUCCESS,
                GeigerUrl(null, msg.targetId!, 'search/' + identifier),
                payload));
      } else {
        await _api.sendMessage(
            msg.sourceId,
            Message(msg.targetId!, msg.sourceId, MessageType.STORAGE_SUCCESS,
                GeigerUrl(null, msg.targetId!, 'search/' + identifier)));
      }
    } on Exception catch (e) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not search Node', null, e)
            .toByteArrayStream(bos);
        bos.close();
        List<int> payload = await bos.bytes;
        await _api.sendMessage(
            msg.sourceId,
            Message(
                msg.targetId!,
                msg.sourceId,
                MessageType.STORAGE_ERROR,
                GeigerUrl(null, msg.sourceId, 'search/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Calls [GenericController.close].
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  Future<void> close(
      Message msg, String identifier, List<String> optionalArgs) async {
    try {
      _controller.close();
    } on StorageException catch (e) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not close', null, e).toByteArrayStream(bos);
        bos.close();
        List<int> payload = await bos.bytes;
        await _api.sendMessage(
            msg.sourceId,
            Message(
                msg.targetId!,
                msg.sourceId,
                MessageType.STORAGE_ERROR,
                GeigerUrl(null,msg.sourceId, 'close/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Calls [GenericController.flush].
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  Future<void> flush(
      Message msg, String identifier, List<String> optionalArgs) async {
    try {
      _controller.flush();
    } on StorageException catch (e) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not flush', null, e).toByteArrayStream(bos);
        bos.close();
        List<int> payload = await bos.bytes;
        await _api.sendMessage(
            msg.sourceId,
            Message(
                msg.targetId!,
                msg.sourceId,
                MessageType.STORAGE_ERROR,
                GeigerUrl(null,msg.sourceId, 'flush/' + identifier),
                payload));
      } on IOException {}
    }
  }

  /// Calls [GenericController.zap].
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  Future<void> zap(
      Message msg, String identifier, List<String> optionalArgs) async {
    try {
      _controller.zap();
    } on StorageException catch (e) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not zap', null, e).toByteArrayStream(bos);
        bos.close();
        List<int> payload = await bos.bytes;
        await _api.sendMessage(
            msg.sourceId,
            Message(msg.targetId!, msg.sourceId, MessageType.STORAGE_ERROR,
                GeigerUrl(null, msg.sourceId, 'zap/' + identifier), payload));
      } on IOException {}
    }
  }

  @override
  Future<void> pluginEvent(GeigerUrl? url, Message msg) async {
    await storageEventParser(msg);
  }

  /// Registers a [StorageListener].
  Future<void> registerChangeListener(
      Message msg, String identifier, List<String> optionalArgs) async {
    msg.payloadString;
    StorageListener? listener;
    SearchCriteria criteria =
        await SearchCriteria.fromByteArrayStream(ByteStream(null, msg.payload));
  }

  List<SearchCriteria> deregisterChangeListener(StorageListener listener) {
    throw Exception('unimplemented');
  }
}