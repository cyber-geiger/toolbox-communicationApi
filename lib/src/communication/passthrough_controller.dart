library geiger_api;

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:logging/logging.dart';

import 'communication_helper.dart';

/// Class for handling storage events in Plugins.
class PassthroughController extends StorageController
    implements PluginListener {
  final GeigerApi api;

  final Map<String, StorageListener> _idToListener = {};
  final Map<SearchCriteria, String> _listenerCriteriaToId = {};
  final Map<String, SearchCriteria> _idToListenerCriteria = {};

  /// Creates a [PassthroughController] for the given [api] and plugin (provide its [api.id]).
  PassthroughController(this.api);

  @override
  void pluginEvent(GeigerUrl? url, Message msg) {
    if (msg.action?.path.endsWith('changeEvent') != true) return;
    _processChangeEvent(msg);
  }

  Future<void> _processChangeEvent(Message message) async {
    try {
      var stream = ByteStream(null, message.payload);
      var id = (await SerializerHelper.readString(stream))!;
      var listener = _idToListener[id];
      if (listener == null) {
        throw StorageException('Listener "$id" for change event not found.');
      }

      var typeString = (await SerializerHelper.readString(stream))!;
      var type = EventTypeExtension.fromString(typeString);
      if (type == null) {
        throw StorageException(
            'Change event contained invalid event type "$typeString".');
      }

      var nodeAvailability = await SerializerHelper.readInt(stream);
      var oldNode = nodeAvailability & 1 == 0
          ? null
          : await NodeImpl.fromByteArrayStream(stream);
      var newNode = nodeAvailability & 2 == 0
          ? null
          : await NodeImpl.fromByteArrayStream(stream);

      // TODO: proper exception handling
      listener.gotStorageChange(type, oldNode, newNode);
    } on Exception catch (e, st) {
      GeigerApi.logger.log(
          Level.WARNING, 'Got exception while processing change event.', e, st);
    }
  }

  Future<ByteStream> _remoteCall(String name,
      [Function(ByteSink)? payloadSerializer]) async {
    try {
      ByteSink? sink;
      if (payloadSerializer != null) {
        sink = ByteSink();
        payloadSerializer(sink);
        sink.close();
      }
      var response = await CommunicationHelper.sendAndWait(
          api,
          Message(api.id, GeigerApi.masterId, MessageType.storageEvent,
              GeigerUrl(null, GeigerApi.masterId, name), await sink?.bytes));
      var stream = ByteStream(null, response.payload);
      if (response.type == MessageType.storageError) {
        throw await StorageException.fromByteArrayStream(stream);
      }
      return stream;
    } on Exception catch (e, st) {
      throw StorageException('Remote call failed', null, e, st);
    }
  }

  @override
  Future<Node> get(String path) async {
    return NodeImpl.fromByteArrayStream(await _remoteCall(
        'getNode', (sink) => SerializerHelper.writeString(sink, path)));
  }

  @override
  Future<Node> getNodeOrTombstone(String path) async {
    return NodeImpl.fromByteArrayStream(await _remoteCall('getNodeOrTombstone',
        (sink) => SerializerHelper.writeString(sink, path)));
  }

  @override
  Future<void> add(Node node) async {
    await _remoteCall('addNode', (sink) => node.toByteArrayStream(sink));
  }

  @override
  Future<void> update(Node node) async {
    await _remoteCall('updateNode', (sink) => node.toByteArrayStream(sink));
  }

  @override
  Future<bool> addOrUpdate(Node node) async {
    var result = await _remoteCall(
        'addOrUpdateNode', (sink) => node.toByteArrayStream(sink));
    return (await SerializerHelper.readInt(result)) == 1;
  }

  @override
  Future<Node> delete(String path) async {
    return await NodeImpl.fromByteArrayStream(await _remoteCall(
        'deleteNode', (sink) => SerializerHelper.writeString(sink, path)));
  }

  @override
  Future<NodeValue?> getValue(String path, String key) async {
    var result = await _remoteCall('getValue', (sink) {
      SerializerHelper.writeString(sink, path);
      SerializerHelper.writeString(sink, key);
    });
    return (await result.bytes).isEmpty
        ? null
        : await NodeValueImpl.fromByteArrayStream(result);
  }

  @override
  Future<void> addValue(String path, NodeValue value) async {
    await _remoteCall('addValue', (sink) {
      SerializerHelper.writeString(sink, path);
      value.toByteArrayStream(sink);
    });
  }

  @override
  Future<void> updateValue(String nodeName, NodeValue value) async {
    await _remoteCall('updateValue', (sink) {
      SerializerHelper.writeString(sink, nodeName);
      value.toByteArrayStream(sink);
    });
  }

  @override
  Future<bool> addOrUpdateValue(String path, NodeValue value) async {
    var result = await _remoteCall('addOrUpdateValue', (sink) {
      SerializerHelper.writeString(sink, path);
      value.toByteArrayStream(sink);
    });
    return (await SerializerHelper.readInt(result)) == 1;
  }

  @override
  Future<NodeValue> deleteValue(String path, String key) async {
    return await NodeValueImpl.fromByteArrayStream(
        await _remoteCall('deleteValue', (sink) {
      SerializerHelper.writeString(sink, path);
      SerializerHelper.writeString(sink, key);
    }));
  }

  @override
  Future<void> rename(String oldPath, String newName) async {
    await _remoteCall('renameNode', (sink) {
      SerializerHelper.writeString(sink, oldPath);
      SerializerHelper.writeString(sink, newName);
    });
  }

  @override
  Future<List<Node>> search(SearchCriteria criteria) async {
    var result = await _remoteCall(
        'searchNodes', (sink) => criteria.toByteArrayStream(sink));
    int nodeCount = await SerializerHelper.readInt(result);
    List<Node> nodes = [];
    for (var i = 0; i < nodeCount; i++) {
      nodes.add(await NodeImpl.fromByteArrayStream(result));
    }
    return nodes;
  }

  @override
  Future<void> close() async {
    await _remoteCall('close');
  }

  @override
  Future<void> flush() async {
    await _remoteCall('flush');
  }

  @override
  Future<void> zap() async {
    await _remoteCall('zap');
  }

  @override
  Future<String> dump([String rootNode = ':', String prefix = '']) async {
    var result = await _remoteCall('dump', (sink) {
      SerializerHelper.writeString(sink, rootNode);
      SerializerHelper.writeString(sink, prefix);
    });
    return (await SerializerHelper.readString(result))!;
  }

  @override
  Future<void> registerChangeListener(
      StorageListener listener, SearchCriteria criteria) async {
    var id = _listenerCriteriaToId[criteria];
    if (id == null) {
      final response = await _remoteCall(
          'registerChangeListener', (sink) => criteria.toByteArrayStream(sink));
      id = (await SerializerHelper.readString(response))!;
      _listenerCriteriaToId[criteria] = id;
      _idToListenerCriteria[id] = criteria;
    }
    _idToListener[id] = listener;
  }

  @override
  Future<List<SearchCriteria>> deregisterChangeListener(
      StorageListener listener) async {
    final ids = _idToListener.entries
        .where((e) => e.value == listener)
        .map((e) => e.key)
        .toList();
    if (ids.isEmpty) {
      throw StorageException(
          'Cannot unregistered not registered StorageListener.');
    }

    await _remoteCall('deregisterChangeListeners', (sink) {
      SerializerHelper.writeInt(sink, ids.length);
      for (final id in ids) {
        SerializerHelper.writeString(sink, id);
      }
    });

    for (final id in ids) {
      _idToListener.remove(id);
    }
    final criteriaList =
        ids.map((id) => _idToListenerCriteria.remove(id)!).toList();
    for (final criteria in criteriaList) {
      _listenerCriteriaToId.remove(criteria);
    }
    return criteriaList;
  }
}
