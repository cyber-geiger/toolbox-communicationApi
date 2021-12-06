library geiger_api;

import 'dart:io';

import 'package:geiger_api/src/communication/communication_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:logging/logging.dart';

import 'geiger_url.dart';
import 'message.dart';
import 'message_type.dart';
import 'plugin_listener.dart';

/// [StorageEventHandler] processes StorageEvents accordingly.
class StorageEventHandler with PluginListener {
  final CommunicationApi _api;
  final StorageController _controller;

  static final Logger log = Logger("GeigerApi");

  StorageEventHandler(this._api, this._controller);

  /// Decides which storage method has been called for [msg].
  Future<void> storageEventParser(Message msg) async {
    final List<String> urlParts = ((msg.action!.path)).split('/');
    final String action = urlParts[0];
    final List<String> optionalArgs = urlParts.sublist(1, urlParts.length);
    switch (action) {
      case 'getNode':
        await getNode(msg, optionalArgs);
        break;
      case 'addNode':
        addNode(msg, optionalArgs);
        break;
      case 'updateNode':
        updateNode(msg, optionalArgs);
        break;
      case 'removeNode':
        await deleteNode(msg, optionalArgs);
        break;
      case 'getValue':
        await getValue(msg, optionalArgs);
        break;
      case 'addValue':
        await addValue(msg, optionalArgs);
        break;
      case 'updateValue':
        await updateValue(msg, optionalArgs);
        break;
      case 'removeValue':
        await deleteValue(msg, optionalArgs);
        break;
      case 'rename':
        await rename(msg, optionalArgs);
        break;
      case 'search':
        await search(msg, optionalArgs);
        break;
      case 'registerChangeListener':
        await registerChangeListener(msg, optionalArgs);
        break;
      case 'close':
        await close(msg, optionalArgs);
        break;
      case 'flush':
        await flush(msg, optionalArgs);
        break;
      case 'zap':
        await zap(msg, optionalArgs);
        break;
      default:
        break;
    }
  }

  /// Calls [GenericController.getNode] and sends the Node back to the [msg] source.
  Future<void> getNode(Message msg, List<String> optionalArgs) async {
    var path = optionalArgs.join('/');
    try {
      final Node node = await _controller.get(path);
      final ByteSink bos = ByteSink();
      node.toByteArrayStream(bos);
      bos.close();
      await _api.sendMessage(Message(
          _api.id,
          msg.sourceId,
          MessageType.storageSuccess,
          GeigerUrl(null, msg.sourceId, 'getNode/$path'),
          await bos.bytes,
          msg.requestId));
    } on IOException catch (e) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not get Node' + path, null, e)
            .toByteArrayStream(bos);
        bos.close();
        await _api.sendMessage(Message(
            _api.id,
            msg.sourceId,
            MessageType.storageError,
            GeigerUrl(null, msg.sourceId, 'getNode/'),
            await bos.bytes,
            msg.requestId));
      } on IOException catch (e) {
        log.log(Level.SEVERE, 'got unexpected IOException', e);
      }
    }
  }

  /// Calls [GenericController.addNode].
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  Future<void> addNode(Message msg, List<String> optionalArgs) async {
    try {
      _controller.add(
          await NodeImpl.fromByteArrayStream(ByteStream(null, msg.payload)));
      await _api.sendMessage(Message(
          _api.id,
          msg.sourceId,
          MessageType.storageSuccess,
          GeigerUrl(null, msg.sourceId, 'addNode/'),
          null,
          msg.requestId));
    } on Exception catch (e) {
      try {
        final ByteSink bos = ByteSink();
        StorageException('Could not add Node', null, e).toByteArrayStream(bos);
        bos.close();
        await _api.sendMessage(Message(
            msg.targetId!,
            msg.sourceId,
            MessageType.storageError,
            GeigerUrl(null, msg.sourceId, 'addNode/'),
            await bos.bytes));
      } on IOException {
        log.log(Level.SEVERE, 'got unexpected IOException', e);
      }
    }
  }

  /// Calls [GenericController.updateNode].
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  Future<void> updateNode(Message msg, List<String> optionalArgs) async {
    try {
      _controller.update(
          await NodeImpl.fromByteArrayStream(ByteStream(null, msg.payload)));
      await _api.sendMessage(Message(
          _api.id,
          msg.sourceId,
          MessageType.storageSuccess,
          GeigerUrl(null, msg.sourceId, 'updateNode/'),
          null,
          msg.requestId));
    } on Exception catch (e, st) {
      try {
        final ByteSink bos = ByteSink();
        StorageException('Could not update Node', null, e, st)
            .toByteArrayStream(bos);
        bos.close();
        await _api.sendMessage(Message(
            _api.id,
            msg.sourceId,
            MessageType.storageError,
            GeigerUrl(null, msg.sourceId, 'updateNode/'),
            await bos.bytes,
            msg.requestId));
      } on IOException {
        log.log(Level.SEVERE, 'got unexpected IOException', e);
      }
    }
  }

  /// Calls [GenericController.deleteNode] and sends the deleted node back to the [msg] source.
  Future<void> deleteNode(Message msg, List<String> optionalArgs) async {
    try {
      final NodeImpl node = _controller.delete(optionalArgs[0]) as NodeImpl;
      final ByteSink bos = ByteSink();
      node.toByteArrayStream(bos);
      bos.close();
      await _api.sendMessage(Message(
          _api.id,
          msg.sourceId,
          MessageType.storageSuccess,
          GeigerUrl(null, msg.targetId!, 'deleteNode/'),
          await bos.bytes,
          msg.requestId));
    } on Exception catch (e) {
      try {
        final ByteSink bos = ByteSink();
        StorageException('Could not delete Node', null, e)
            .toByteArrayStream(bos);
        bos.close();
        await _api.sendMessage(Message(
            _api.id,
            msg.sourceId,
            MessageType.storageError,
            GeigerUrl(null, msg.sourceId, 'deleteNode/'),
            await bos.bytes,
            msg.requestId));
      } on IOException catch (e) {
        log.log(Level.SEVERE, 'got unexpected IOException', e);
      }
    }
  }

  /// Calls [GenericController.getValue] and sends the [NodeValue] back to the [msg] source.
  Future<void> getValue(Message msg, List<String> optionalArgs) async {
    try {
      NodeImpl nodeValue =
          _controller.getValue(optionalArgs[0], optionalArgs[1]) as NodeImpl;
      ByteSink bos = ByteSink();
      nodeValue.toByteArrayStream(bos);
      bos.close();
      await _api.sendMessage(Message(
          _api.id,
          msg.sourceId,
          MessageType.storageSuccess,
          GeigerUrl(null, msg.targetId!, 'getValue/'),
          await bos.bytes,
          msg.requestId));
    } on Exception catch (e) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not get NodeValue', null, e)
            .toByteArrayStream(bos);
        bos.close();
        await _api.sendMessage(Message(
            _api.id,
            msg.sourceId,
            MessageType.storageError,
            GeigerUrl(null, msg.sourceId, 'getValue/'),
            await bos.bytes,
            msg.requestId));
      } on IOException catch (e, s) {
        throw StorageException(
            'Unable to send Storage exception to endpoint', null, e, s);
      }
    }
  }

  /// Calls [GenericController.addValue].
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  Future<void> addValue(Message msg, List<String> optionalArgs) async {
    NodeValue nodeValue;
    try {
      nodeValue = await NodeValueImpl.fromByteArrayStream(
          ByteStream(null, msg.payload));
      _controller.addValue(optionalArgs[0], nodeValue);
      await _api.sendMessage(Message(
          _api.id,
          msg.sourceId,
          MessageType.storageSuccess,
          GeigerUrl(null, msg.targetId!, 'addValue/'),
          null,
          msg.requestId));
    } on Exception catch (e) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not add NodeValue', null, e)
            .toByteArrayStream(bos);
        bos.close();
        await _api.sendMessage(Message(
            _api.id,
            msg.sourceId,
            MessageType.storageError,
            GeigerUrl(null, msg.sourceId, 'addValue/'),
            await bos.bytes));
      } on IOException catch (e, s) {
        throw StorageException(
            'Unable to send exception on adding value to endpoint', null, e, s);
      }
    }
  }

  /// Calls [GenericController.updateValue].
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  Future<void> updateValue(Message msg, List<String> optionalArgs) async {
    NodeValue nodeValue;
    try {
      nodeValue = await NodeValueImpl.fromByteArrayStream(
          ByteStream(null, msg.payload));
      _controller.updateValue(optionalArgs[0], nodeValue);
      await _api.sendMessage(Message(
          _api.id,
          msg.sourceId,
          MessageType.storageSuccess,
          GeigerUrl(null, msg.sourceId, 'updateValue/'),
          null,
          msg.requestId));
    } on Exception catch (e) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not update NodeValue', null, e)
            .toByteArrayStream(bos);
        bos.close();
        await _api.sendMessage(Message(
            _api.id,
            msg.sourceId,
            MessageType.storageError,
            GeigerUrl(null, msg.sourceId, 'updateValue/'),
            await bos.bytes,
            msg.requestId));
      } on IOException catch (e) {
        log.log(Level.SEVERE, 'got unexpected IOException', e);
      }
    }
  }

  /// Either calls [GenericController.removeValue] and sends the [NodeValue] back to the [msg] source
  /// or stores the received [NodeValue] in the storageEventObject map.
  Future<void> deleteValue(Message msg, List<String> optionalArgs) async {
    try {
      NodeImpl nodeValue =
          _controller.deleteValue(optionalArgs[0], optionalArgs[1]) as NodeImpl;
      ByteSink bos = ByteSink();
      nodeValue.toByteArrayStream(bos);
      bos.close();
      await _api.sendMessage(Message(
          _api.id,
          msg.sourceId,
          MessageType.storageSuccess,
          GeigerUrl(null, _api.id, 'deleteNodeValue/'),
          await bos.bytes,
          msg.requestId));
    } on Exception catch (e) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not delete NodeValue', null, e)
            .toByteArrayStream(bos);
        bos.close();
        await _api.sendMessage(Message(
            _api.id,
            msg.sourceId,
            MessageType.storageError,
            GeigerUrl(null, msg.sourceId, 'deleteValue/'),
            await bos.bytes,
            msg.requestId));
      } on IOException catch (e) {
        log.log(Level.SEVERE, 'got unexpected IOException', e);
      }
    }
  }

  /// Calls [GenericController.rename]
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  Future<void> rename(Message msg, List<String> optionalArgs) async {
    try {
      _controller.rename(optionalArgs[0], optionalArgs[1]);
      await _api.sendMessage(Message(
          _api.id,
          msg.sourceId,
          MessageType.storageSuccess,
          GeigerUrl(null, _api.id, 'rename/'),
          null,
          msg.requestId));
    } on StorageException catch (e) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not rename Node', null, e)
            .toByteArrayStream(bos);
        bos.close();
        await _api.sendMessage(Message(
            _api.id,
            msg.sourceId,
            MessageType.storageError,
            GeigerUrl(null, msg.sourceId, 'rename/'),
            await bos.bytes,
            msg.requestId));
      } on IOException catch (e) {
        log.log(Level.SEVERE, 'got unexpected IOException', e);
      }
    }
  }

  /// Calls [GenericController.search] and sends the List of Nodes back to the [msg] source.
  Future<void> search(Message msg, List<String> optionalArgs) async {
    try {
      final SearchCriteria searchCriteria =
          await SearchCriteria.fromByteArrayStream(
              ByteStream(null, msg.payload));
      List<Node> nodes = await _controller.search(searchCriteria);
      if (nodes.isNotEmpty) {
        ByteSink bos = ByteSink();
        for (NodeImpl n in nodes as List<NodeImpl>) {
          n.toByteArrayStream(bos);
        }
        bos.close();
        await _api.sendMessage(Message(
            _api.id,
            msg.sourceId,
            MessageType.storageSuccess,
            GeigerUrl(null, msg.sourceId, 'search/'),
            await bos.bytes,
            msg.requestId));
      } else {
        await _api.sendMessage(Message(
            _api.id,
            msg.sourceId,
            MessageType.storageSuccess,
            GeigerUrl(null, msg.sourceId, 'search/'),
            null,
            msg.requestId));
      }
    } on Exception catch (e) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not search Node', null, e)
            .toByteArrayStream(bos);
        bos.close();
        await _api.sendMessage(Message(
            _api.id,
            msg.sourceId,
            MessageType.storageError,
            GeigerUrl(null, msg.sourceId, 'search/'),
            await bos.bytes,
            msg.requestId));
      } on IOException catch (e) {
        log.log(Level.SEVERE, 'got unexpected IOException', e);
      }
    }
  }

  /// Calls [GenericController.close].
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  Future<void> close(Message msg, List<String> optionalArgs) async {
    try {
      _controller.close();
      await _api.sendMessage(Message(
          _api.id,
          msg.sourceId,
          MessageType.storageSuccess,
          GeigerUrl(null, msg.sourceId, 'search/'),
          null,
          msg.requestId));
    } on StorageException catch (e) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not close', null, e).toByteArrayStream(bos);
        bos.close();
        await _api.sendMessage(Message(
            _api.id,
            msg.sourceId,
            MessageType.storageError,
            GeigerUrl(null, msg.sourceId, 'close/'),
            await bos.bytes,
            msg.requestId));
      } on IOException catch (e) {
        log.log(Level.SEVERE, 'got unexpected IOException', e);
      }
    }
  }

  /// Calls [GenericController.flush].
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  Future<void> flush(Message msg, List<String> optionalArgs) async {
    try {
      _controller.flush();
      await _api.sendMessage(Message(
          _api.id,
          msg.sourceId,
          MessageType.storageSuccess,
          GeigerUrl(null, msg.sourceId, 'flush/'),
          null,
          msg.requestId));
    } on StorageException catch (e) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not flush', null, e).toByteArrayStream(bos);
        bos.close();
        await _api.sendMessage(Message(
            msg.targetId!,
            msg.sourceId,
            MessageType.storageError,
            GeigerUrl(null, msg.sourceId, 'flush/'),
            await bos.bytes,
            msg.requestId));
      } on IOException catch (e) {
        log.log(Level.SEVERE, 'got unexpected IOException', e);
      }
    }
  }

  /// Calls [GenericController.zap].
  ///
  /// If it fails it sends a [StorageException] to the [msg] source.
  Future<void> zap(Message msg, List<String> optionalArgs) async {
    try {
      _controller.zap();
      await _api.sendMessage(Message(
          _api.id,
          msg.sourceId,
          MessageType.storageSuccess,
          GeigerUrl(null, msg.sourceId, 'zap/'),
          null,
          msg.requestId));
    } on StorageException catch (e) {
      try {
        ByteSink bos = ByteSink();
        StorageException('Could not zap', null, e).toByteArrayStream(bos);
        bos.close();
        await _api.sendMessage(Message(
            msg.targetId!,
            msg.sourceId,
            MessageType.storageError,
            GeigerUrl(null, msg.sourceId, 'zap/'),
            await bos.bytes));
      } on IOException catch (e) {
        log.log(Level.SEVERE, 'got unexpected IOException', e);
      }
    }
  }

  @override
  Future<void> pluginEvent(GeigerUrl? url, Message msg) async {
    await storageEventParser(msg);
  }

  /// Registers a [StorageListener].
  Future<void> registerChangeListener(
      Message msg, List<String> optionalArgs) async {
    throw Exception('unimplemented');
  }

  List<SearchCriteria> deregisterChangeListener(StorageListener listener) {
    throw Exception('unimplemented');
  }
}
