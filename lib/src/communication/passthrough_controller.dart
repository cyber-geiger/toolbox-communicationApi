library geiger_api;

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

import 'communication_helper.dart';

/// Class for handling storage events in Plugins.
class PassthroughController extends StorageController {
  final GeigerApi api;
  final Map<String, Message> receivedMessages = <String, Message>{};

  /// Creates a [PassthroughController] for the given [api] and plugin (provide its [api.id]).
  PassthroughController(this.api);

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
              GeigerUrl(null, api.id, name), await sink?.bytes));
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
    return (await SerializerHelper.readRawInt(result)) == 1;
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
    var result =
        await _remoteCall('searchNodes', (sink) => criteria.toByteArrayStream(sink));
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

  /// Register a [StorageListener] for a Node defined by [SearchCriteria].
  ///
  /// Throws a [StorageException] if the listener could not be registered.
  @override
  Future<void> registerChangeListener(
      StorageListener listener, SearchCriteria criteria) async {
    throw UnimplementedError();
    /*var command = 'registerChangeListener';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    ByteSink byteArrayOutputStream = ByteSink();
    byteArrayOutputStream.sink.add(await criteria.toByteArray());
    try {
      api.sendMessage(
          GeigerApi.masterId,
          Message(
              api.id,
              GeigerApi.masterId,
              MessageType.storageEvent,
              GeigerUrl(GeigerApi.masterId, (command + '/') + identifier),
              byteArrayOutputStream.toByteArray()));
    } on MalformedUrlException catch (e) {}
    Message response = waitForResult(command, identifier);
    if (response.getType() == MessageType.STORAGE_ERROR) {
      try {
        throw await StorageException.fromByteArrayStream(
            ByteStream(null, response.getPayload()));
      } on IOException catch (e) {
        throw StorageException('Could not rename Node', e);
      }
    }*/
  }

  /// Deregister a [StorageListener] from the Storage and returns the associated [SearchCriteria].
  ///
  /// Throws a [StorageException] if listener could not be deregistered.
  @override
  List<SearchCriteria> deregisterChangeListener(StorageListener listener) {
    throw UnimplementedError();
    /*var command = 'deregisterChangeListener';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    ByteStream byteArrayOutputStream = ByteStream();
    try {
      api.sendMessage(
          GeigerApi.masterId,
          Message(
              api.id,
              GeigerApi.masterId,
              MessageType.storageEvent,
              GeigerUrl(GeigerApi.masterId, (command + '/') + identifier),
              byteArrayOutputStream.toByteArray()));
    } on MalformedUrlException catch (e) {}
    Message response = waitForResult(command, identifier);
    if (response.getType() == MessageType.STORAGE_ERROR) {
      try {
        throw await StorageException.fromByteArrayStream(
            ByteStream(null, response.payload));
      } on IOException catch (e) {
        throw StorageException('Could not rename Node', e);
      }
    } else {
      SearchCriteria.fromByteArrayStream(
          ByteStream(null, response.getPayload()));
      return [];
    }*/
  }
}
