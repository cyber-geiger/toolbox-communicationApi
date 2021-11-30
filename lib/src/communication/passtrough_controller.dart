library geiger_api;

// TODO(mgwerder): completely redo this concept
/*
/// Class for handling storage events in Plugins.
class PasstroughController implements StorageController, PluginListener {
  final GeigerApi localApi;
  final String id;
  final Object comm = Object();
  final Map<String, Message> receivedMessages = <String, Message>{};

  /// Creates a [PasstroughController] for the given [api] and plugin (provide its [id]).
  PasstroughController(this.localApi, this.id) {
    localApi.registerListener([
      MessageType.storageError,
      MessageType.storageEvent,
      MessageType.storageSuccess
    ], this);
  }

  Message? waitForResult(String command, String identifier) {
    var token = command + '/' + identifier;
    var start = DateTime.now().millisecondsSinceEpoch;
    while (receivedMessages[token] == null) {
      Future.delayed(const Duration(seconds: 1));
      if ((DateTime.now().millisecondsSinceEpoch - start) > 5000) {
        throw Exception('Lost communication while waiting for ' + token);
      }
    }
    return receivedMessages[token];
  }

  @override
  Future<Node> get(String path) async {
    var command = 'getNode';
    String identifier = ExtendedTimestamp.extendedNow();
    try {
      Message response = await CommunicationHelper.sendAndWait(
          localApi,
          Message(
              id,
              GeigerApi.masterId,
              MessageType.storageEvent,
              GeigerUrl(
                  null, id, (((command + '/') + identifier) + '/') + path)));
      if (response.type == MessageType.storageError) {
        throw StorageException.fromByteArrayStream(
            ByteStream(null, response.payload));
      } else {
        return NodeImpl.fromByteArrayStream(ByteStream(null, response.payload));
      }
    } on Exception catch (e) {
      throw CommunicationException('Could not get Node', e);
    }
  }

  @override
  Future<Node> getNodeOrTombstone(String path) {
    var command = 'getNodeOrTombstone';
    try {
      Message msg = await CommunicationHelper.sendAndWait(
          localApi,
          Message(id, GeigerApi.masterId, MessageType.storageEvent,
              GeigerUrl(null, id, '$command/$path')));
    } on MalformedUrlException catch (e) {}
    Message response = waitForResult(command, identifier);
    try {
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException.fromByteArrayStream(
            ByteStream(null, response.getPayload()));
      } else {
        return NodeImpl.fromByteArrayStream(
            ByteStream(null, response.getPayload()));
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
      ByteSink bos = ByteSink();
      node.toByteArrayStream(bos);
      List<int> payload = bos.toByteArray();
      var m = Message(id, GeigerApi.MASTER, MessageType.STORAGE_EVENT,
          GeigerUrl(id, (command + '/') + identifier), payload);
      localApi.sendMessage(GeigerApi.MASTER, m);
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
      ByteSink bos = ByteSink();
      node.toByteArrayStream(bos);
      List<int> payload = bos.toByteArray();
      var m = Message(id, GeigerApi.MASTER, MessageType.STORAGE_EVENT,
          GeigerUrl(id, (command + '/') + identifier), payload);
      localApi.sendMessage(GeigerApi.MASTER, m);
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException.fromByteArrayStream(
            ByteStream(null, response.getPayload()));
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
      ByteSink bos = ByteSink();
      node.toByteArrayStream(bos);
      List<int> payload = bos.toByteArray();
      var m = Message(id, GeigerApi.MASTER, MessageType.STORAGE_EVENT,
          GeigerUrl(id, (command + '/') + identifier), payload);
      localApi.sendMessage(GeigerApi.MASTER, m);
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw StorageException.fromByteArrayStream(
            ByteStream(null, response.getPayload()));
      }
      return true;
    } on IOException catch (e) {
      throw StorageException('Could not add or update Node', e);
    }
  }

  @override
  Future<Node> delete(String path) async {
    var command = 'deleteNode';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      localApi.sendMessage(
          GeigerApi.MASTER,
          Message(id, GeigerApi.MASTER, MessageType.STORAGE_EVENT,
              GeigerUrl(id, (((command + '/') + identifier) + '/') + path)));
    } on MalformedUrlException catch (e) {}
    Message response = waitForResult(command, identifier);
    try {
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw await StorageException.fromByteArrayStream(
            ByteStream(null, response.getPayload()));
      } else {
        return await NodeImpl.fromByteArrayStream(
            ByteStream(null, response.getPayload()));
      }
    } on IOException catch (e) {
      throw StorageException('Could not delete Node', e);
    }
  }

  @override
  Future<NodeValue> getValue(String path, String key) async {
    var command = 'getValue';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      localApi.sendMessage(
          GeigerApi.MASTER,
          Message(
              id,
              GeigerApi.MASTER,
              MessageType.STORAGE_EVENT,
              GeigerUrl(
                  id,
                  (((((command + '/') + identifier) + '/') + path) + '/') +
                      key)));
    } on MalformedUrlException catch (e) {}
    Message response = waitForResult(command, identifier);
    try {
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw await StorageException.fromByteArrayStream(
            ByteStream(null, response.getPayload()));
      } else {
        return NodeValueImpl.fromByteArrayStream(
            ByteStream(null, response.getPayload()));
      }
    } on IOException catch (e) {
      throw StorageException('Could not get Value', e);
    }
  }

  @override
  Future<void> addValue(String path, NodeValue value) async {
    var command = 'addValue';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      ByteSink bos = ByteSink();
      value.toByteArrayStream(bos);
      bos.close();
      List<int> payload = await bos.bytes;
      var m = Message(
          id,
          GeigerApi.MASTER,
          MessageType.STORAGE_EVENT,
          GeigerUrl(id, (((command + '/') + identifier) + '/') + path),
          payload);
      localApi.sendMessage(GeigerApi.MASTER, m);
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
  Future<void> updateValue(String nodeName, NodeValue value) async {
    var command = 'updateValue';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      ByteSink bos = ByteSink();
      value.toByteArrayStream(bos);
      bos.close();
      List<int> payload = await bos.bytes;
      var m = Message(
          id,
          GeigerApi.MASTER,
          MessageType.STORAGE_EVENT,
          GeigerUrl(id, (((command + '/') + identifier) + '/') + nodeName),
          payload);
      localApi.sendMessage(GeigerApi.MASTER, m);
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw await StorageException.fromByteArrayStream(
            ByteStream(null, response.getPayload()));
      }
    } on IOException catch (e) {
      throw StorageException('Could not update NodeValue', e);
    }
  }

  @override
  Future<NodeValue> deleteValue(String path, String key) async {
    var command = 'deleteValue';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      localApi.sendMessage(
          GeigerApi.MASTER,
          Message(
              id,
              GeigerApi.MASTER,
              MessageType.STORAGE_EVENT,
              GeigerUrl(
                  id,
                  (((((command + '/') + identifier) + '/') + path) + '/') +
                      key)));
    } on MalformedUrlException catch (e) {}
    Message response = await waitForResult(command, identifier);
    try {
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw await StorageException.fromByteArrayStream(
            ByteStream(null, response.getPayload()));
      } else {
        return NodeValueImpl.fromByteArrayStream(
            ByteStream(null, response.getPayload()));
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
      localApi.sendMessage(
          GeigerApi.MASTER,
          Message(
              id,
              GeigerApi.MASTER,
              MessageType.STORAGE_EVENT,
              GeigerUrl(
                  id,
                  (((((command + '/') + identifier) + '/') + oldPath) + '/') +
                      newPathOrName)));
    } on MalformedUrlException catch (e) {}
    Message response = waitForResult(command, identifier);
    if (response.getType() == MessageType.STORAGE_ERROR) {
      try {
        throw await StorageException.fromByteArrayStream(
            ByteStream(null, response.getPayload()));
      } on IOException catch (e) {
        throw StorageException('Could not rename Node', e);
      }
    }
  }

  @override
  Future<List<Node>> search(SearchCriteria criteria) async {
    var command = 'search';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      ByteSink bos = ByteSink();
      criteria.toByteArrayStream(bos);
      bos.close();
      List<int> payload = bos.toByteArray();
      var m = Message(id, GeigerApi.MASTER, MessageType.STORAGE_EVENT,
          GeigerUrl(id, (command + '/') + identifier), payload);
      localApi.sendMessage(GeigerApi.MASTER, m);
      Message response = waitForResult(command, identifier);
      if (response.getType() == MessageType.STORAGE_ERROR) {
        throw await StorageException.fromByteArrayStream(
            ByteStream(null, response.getPayload()));
      } else {
        var receivedPayload = response.getPayload();
        int numNodes =
            GeigerCommunicator.byteArrayToInt(receivedPayload?.sublist(0, 4));
        var receivedNodes = receivedPayload?.sublist(5, receivedPayload.length);
        var nodes = List<Node>.empty(growable: true);
        for (var i = 0; i < numNodes; (++i)) {
          // does this advance the stream? after every read the next one needs to start at
          // the ned of the last read + 1
          nodes.add(await NodeImpl.fromByteArrayStream(
              ByteStream(null, receivedNodes)));
        }
        return nodes;
      }
    } on IOException catch (e) {
      throw StorageException('Could not start Search', e);
    }
  }

  @override
  Future<void> close() async {
    var command = 'close';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      localApi.sendMessage(
          GeigerApi.MASTER,
          Message(id, GeigerApi.MASTER, MessageType.STORAGE_EVENT,
              GeigerUrl(id, (command + '/') + identifier)));
    } on MalformedUrlException catch (e) {}
    Message response = waitForResult(command, identifier);
    if (response.getType() == MessageType.STORAGE_ERROR) {
      try {
        throw await StorageException.fromByteArrayStream(
            ByteStream(null, response.getPayload()));
      } on IOException catch (e) {
        throw StorageException('Could not close', e);
      }
    }
  }

  @override
  Future<void> flush() async {
    var command = 'flush';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      localApi.sendMessage(
          GeigerApi.MASTER,
          Message(id, GeigerApi.MASTER, MessageType.STORAGE_EVENT,
              GeigerUrl(id, (command + '/') + identifier)));
    } on MalformedUrlException catch (e) {}
    Message response = waitForResult(command, identifier);
    if (response.getType() == MessageType.STORAGE_ERROR) {
      try {
        throw StorageException.fromByteArrayStream(
            ByteStream(null, response.getPayload()));
      } on IOException catch (e) {
        throw StorageException('Could not flush', e);
      }
    }
  }

  @override
  Future<void> zap() async {
    var command = 'zap';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    try {
      localApi.sendMessage(
          GeigerApi.MASTER,
          Message(id, GeigerApi.MASTER, MessageType.STORAGE_EVENT,
              GeigerUrl(id, (command + '/') + identifier)));
    } on MalformedUrlException catch (e) {}
    Message response = await waitForResult(command, identifier);
    if (response.getType() == MessageType.STORAGE_ERROR) {
      try {
        throw await StorageException.fromByteArrayStream(
            ByteStream(null, response.getPayload()));
      } on IOException catch (e) {
        throw StorageException('Could not zap', e);
      }
    }
  }

  @override
  void pluginEvent(GeigerUrl url, Message msg) {
    receivedMessages[url.getPath()] = msg;
    // FIXME(mgwerder): notify all comm.notifyAll();
  }

  /// Register a [StorageListener] for a Node defined by [SearchCriteria].
  ///
  /// Throws a [StorageException] if the listener could not be registered.
  @override
  Future<void> registerChangeListener(
      StorageListener listener, SearchCriteria criteria) async {
    var command = 'registerChangeListener';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    ByteSink byteArrayOutputStream = ByteSink();
    byteArrayOutputStream.sink.add(await criteria.toByteArray());
    try {
      localApi.sendMessage(
          GeigerApi.MASTER,
          Message(
              id,
              GeigerApi.MASTER,
              MessageType.STORAGE_EVENT,
              GeigerUrl(GeigerApi.MASTER, (command + '/') + identifier),
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
    }
  }

  /// Deregister a [StorageListener] from the Storage and returns the associated [SearchCriteria].
  ///
  /// Throws a [StorageException] if listener could not be deregistered.
  @override
  List<SearchCriteria> deregisterChangeListener(StorageListener listener) {
    var command = 'deregisterChangeListener';
    var identifier = Random().nextInt(pow(2, 53).toInt()).toString();
    ByteStream byteArrayOutputStream = ByteStream();
    try {
      localApi.sendMessage(
          GeigerApi.MASTER,
          Message(
              id,
              GeigerApi.MASTER,
              MessageType.STORAGE_EVENT,
              GeigerUrl(GeigerApi.MASTER, (command + '/') + identifier),
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
    }
  }
}
*/
