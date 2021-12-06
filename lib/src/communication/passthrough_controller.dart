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

  @override
  Future<Node> get(String path) async {
    try {
      Message response = await CommunicationHelper.sendAndWait(
          api,
          Message(api.id, GeigerApi.masterId, MessageType.storageEvent,
              GeigerUrl(null, api.id, 'getNode/$path')));
      if (response.type == MessageType.storageError) {
        throw StorageException.fromByteArrayStream(
            ByteStream(null, response.payload));
      } else {
        return NodeImpl.fromByteArrayStream(ByteStream(null, response.payload));
      }
    } on Exception catch (e) {
      throw StorageException('Could not get Node', null, e);
    }
  }

  @override
  Future<Node> getNodeOrTombstone(String path) async {
    try {
      Message response = await CommunicationHelper.sendAndWait(
          api,
          Message(api.id, GeigerApi.masterId, MessageType.storageEvent,
              GeigerUrl(null, api.id, 'getNodeOrTombstone/$path')));
      if (response.type == MessageType.storageError) {
        throw StorageException.fromByteArrayStream(
            ByteStream(null, response.payload));
      } else {
        return NodeImpl.fromByteArrayStream(ByteStream(null, response.payload));
      }
    } on Exception catch (e) {
      throw StorageException('Could not get Node', null, e);
    }
  }

  @override
  Future<void> add(Node node) async {
    try {
      ByteSink bos = ByteSink();
      node.toByteArrayStream(bos);
      Message response = await CommunicationHelper.sendAndWait(
          api,
          Message(api.id, GeigerApi.masterId, MessageType.storageEvent,
              GeigerUrl(null, api.id, 'addNode'), await bos.bytes));
      if (response.type == MessageType.storageError) {
        throw StorageException.fromByteArrayStream(
            ByteStream(null, response.payload));
      }
    } on Exception catch (e) {
      throw StorageException('Could not add Node', null, e);
    }
  }

  @override
  Future<void> update(Node node) async {
    try {
      ByteSink bos = ByteSink();
      node.toByteArrayStream(bos);
      var response = await CommunicationHelper.sendAndWait(
          api,
          Message(api.id, GeigerApi.masterId, MessageType.storageEvent,
              GeigerUrl(null, api.id, 'updateNode'), await bos.bytes));
      if (response.type == MessageType.storageError) {
        throw StorageException.fromByteArrayStream(
            ByteStream(null, response.payload));
      }
    } on Exception catch (e) {
      throw StorageException('Could not update Node', null, e);
    }
  }

  @override
  Future<bool> addOrUpdate(Node node) async {
    try {
      ByteSink bos = ByteSink();
      node.toByteArrayStream(bos);
      var response = await CommunicationHelper.sendAndWait(
          api,
          Message(api.id, GeigerApi.masterId, MessageType.storageEvent,
              GeigerUrl(null, api.id, 'addOrUpdateNode'), await bos.bytes));
      if (response.type == MessageType.storageError) {
        throw StorageException.fromByteArrayStream(
            ByteStream(null, response.payload));
      }
      return true;
    } on Exception catch (e) {
      throw StorageException('Could not add or update Node', null, e);
    }
  }

  @override
  Future<Node> delete(String path) async {
    try {
      var response = await CommunicationHelper.sendAndWait(
          api,
          Message(api.id, GeigerApi.masterId, MessageType.storageEvent,
              GeigerUrl(null, api.id, 'deleteNode/$path')));
      if (response.type == MessageType.storageEvent) {
        throw await StorageException.fromByteArrayStream(
            ByteStream(null, response.payload));
      } else {
        return await NodeImpl.fromByteArrayStream(
            ByteStream(null, response.payload));
      }
    } on Exception catch (e) {
      throw StorageException('Could not delete Node', null, e);
    }
  }

  @override
  Future<NodeValue> getValue(String path, String key) async {
    try {
      var response = await CommunicationHelper.sendAndWait(
          api,
          Message(api.id, GeigerApi.masterId, MessageType.storageEvent,
              GeigerUrl(null, api.id, 'getValue/$path/$key')));
      if (response.type == MessageType.storageEvent) {
        throw await StorageException.fromByteArrayStream(
            ByteStream(null, response.payload));
      } else {
        return await NodeValueImpl.fromByteArrayStream(
            ByteStream(null, response.payload));
      }
    } on Exception catch (e) {
      throw StorageException('Could not get Value', null, e);
    }
  }

  @override
  Future<void> addValue(String path, NodeValue value) async {
    try {
      ByteSink bos = ByteSink();
      value.toByteArrayStream(bos);
      bos.close();
      var response = await CommunicationHelper.sendAndWait(
          api,
          Message(api.id, GeigerApi.masterId, MessageType.storageEvent,
              GeigerUrl(null, api.id, 'addValue/$path'), await bos.bytes));
      if (response.type == MessageType.storageEvent) {
        throw await StorageException.fromByteArrayStream(
            ByteStream(null, response.payload));
      }
    } on Exception catch (e) {
      throw StorageException('Could not add NodeValue', null, e);
    }
  }

  @override
  Future<void> updateValue(String nodeName, NodeValue value) async {
    try {
      ByteSink bos = ByteSink();
      value.toByteArrayStream(bos);
      bos.close();
      var response = await CommunicationHelper.sendAndWait(
          api,
          Message(
              api.id,
              GeigerApi.masterId,
              MessageType.storageEvent,
              GeigerUrl(null, api.id, 'updateValue/$nodeName'),
              await bos.bytes));
      if (response.type == MessageType.storageEvent) {
        throw await StorageException.fromByteArrayStream(
            ByteStream(null, response.payload));
      }
    } on Exception catch (e) {
      throw StorageException('Could not update NodeValue', null, e);
    }
  }

  @override
  Future<NodeValue> deleteValue(String path, String key) async {
    try {
      var response = await CommunicationHelper.sendAndWait(
          api,
          Message(api.id, GeigerApi.masterId, MessageType.storageEvent,
              GeigerUrl(null, api.id, 'deleteValue/$path/$key')));
      if (response.type == MessageType.storageEvent) {
        throw await StorageException.fromByteArrayStream(
            ByteStream(null, response.payload));
      } else {
        return await NodeValueImpl.fromByteArrayStream(
            ByteStream(null, response.payload));
      }
    } on Exception catch (e) {
      throw StorageException('Could not delete Value', null, e);
    }
  }

  @override
  Future<void> rename(String oldPath, String newName) async {
    try {
      // this will not work if either the old or the new path contains any "/"
      var response = await CommunicationHelper.sendAndWait(
          api,
          Message(api.id, GeigerApi.masterId, MessageType.storageEvent,
              GeigerUrl(null, api.id, 'deleteValue/$oldPath/$newName')));
      if (response.type == MessageType.storageEvent) {
        throw await StorageException.fromByteArrayStream(
            ByteStream(null, response.payload));
      }
    } on Exception catch (e) {
      throw StorageException('Could not rename Node', null, e);
    }
  }

  @override
  Future<List<Node>> search(SearchCriteria criteria) async {
    try {
      ByteSink bos = ByteSink();
      criteria.toByteArrayStream(bos);
      bos.close();
      var response = Message(
          api.id,
          GeigerApi.masterId,
          MessageType.storageEvent,
          GeigerUrl(null, api.id, 'search'),
          await bos.bytes);
      if (response.type == MessageType.storageEvent) {
        throw await StorageException.fromByteArrayStream(
            ByteStream(null, response.payload));
      } else {
        var receivedPayload = ByteStream(null, response.payload);
        int numNodes = await SerializerHelper.readInt(receivedPayload);
        List<Node> nodes = [];
        for (var i = 0; i < numNodes; i++) {
          nodes.add(await NodeImpl.fromByteArrayStream(receivedPayload));
        }
        return nodes;
      }
    } on Exception catch (e) {
      throw StorageException('Could not start Search', null, e);
    }
  }

  @override
  Future<void> close() async {
    try {
      var response = await CommunicationHelper.sendAndWait(
          api,
          Message(api.id, GeigerApi.masterId, MessageType.storageEvent,
              GeigerUrl(null, api.id, 'close')));
      if (response.type == MessageType.storageEvent) {
        throw await StorageException.fromByteArrayStream(
            ByteStream(null, response.payload));
      }
    } on Exception catch (e) {
      throw StorageException('Could not close', null, e);
    }
  }

  @override
  Future<void> flush() async {
    try {
      var response = await CommunicationHelper.sendAndWait(
          api,
          Message(api.id, GeigerApi.masterId, MessageType.storageEvent,
              GeigerUrl(null, api.id, 'flush')));
      if (response.type == MessageType.storageEvent) {
        throw await StorageException.fromByteArrayStream(
            ByteStream(null, response.payload));
      }
    } on Exception catch (e) {
      throw StorageException('Could not flush', null, e);
    }
  }

  @override
  Future<void> zap() async {
    try {
      var response = await CommunicationHelper.sendAndWait(
          api,
          Message(api.id, GeigerApi.masterId, MessageType.storageEvent,
              GeigerUrl(null, api.id, 'command')));
      if (response.type == MessageType.storageEvent) {
        throw await StorageException.fromByteArrayStream(
            ByteStream(null, response.payload));
      }
    } on Exception catch (e) {
      throw StorageException('Could not zap', null, e);
    }
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
        throw StorageException.fromByteArrayStream(
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
        throw StorageException.fromByteArrayStream(
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
