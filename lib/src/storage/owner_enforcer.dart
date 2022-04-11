library geiger_localstorage;

import 'package:geiger_localstorage/geiger_localstorage.dart';

class StorageListenerFilter extends StorageListener {
  final StorageListener _listener;
  final String _owner;

  StorageListenerFilter(this._owner, this._listener);

  @override
  void gotStorageChange(EventType event, Node? oldNode, Node? newNode) {
    if (oldNode != null &&
        (oldNode.visibility != Visibility.white && oldNode.owner != _owner)) {
      oldNode = null;
    }
    if (newNode != null &&
        (newNode.visibility != Visibility.white && newNode.owner != _owner)) {
      newNode = null;
    }

    if (oldNode != null || newNode != null) {
      _listener.gotStorageChange(event, oldNode, newNode);
    }
  }
}

class OwnerEnforcerWrapper extends StorageController {
  final StorageController _controller;
  final String _owner;
  final bool _enforceTimestampUpdate;
  final bool _sharingFilter;
  final bool _pulledFromFactory;

  final Map<StorageListener, StorageListener> _listeners = {};

  OwnerEnforcerWrapper(this._controller, this._owner,
      [this._enforceTimestampUpdate = true,
      this._pulledFromFactory = false,
      this._sharingFilter = true]);

  String get owner => _owner;

  bool get enforceTimestampUpdate => _enforceTimestampUpdate;

  bool get pulledFromFactory => _pulledFromFactory;

  Node _updateOwnerAndTimestamp(Node n) {
    if (n.owner != owner) {
      (n as NodeImpl).set(Field.owner, owner);
      if (_enforceTimestampUpdate) {
        n.touch();
      }
    }
    return n;
  }

  @override
  Future<void> add(Node node) async {
    Node n = await node.deepClone();
    n = _updateOwnerAndTimestamp(n);
    return await _controller.add(n);
  }

  @override
  Future<bool> addOrUpdate(Node node) async {
    Node n = await node.deepClone();
    n = _updateOwnerAndTimestamp(n);
    return await _controller.addOrUpdate(n);
  }

  @override
  Future<void> addValue(String path, NodeValue value) async {
    if (_enforceTimestampUpdate) {
      value.touch();
    }
    if ((await _controller.getNodeOrTombstone(path)).owner == _owner) {
      return await _controller.addValue(path, value);
    }
  }

  @override
  Future<void> close() async {
    // nothing to do
    return await _controller.close();
  }

  @override
  Future<Node> delete(String path) async {
    // nothing to do
    // timestamp is updated anyway
    if ((await _controller.getNodeOrTombstone(path)).owner == _owner) {
      return await _controller.delete(path);
    }
    throw StorageException(
        'cannot delete nodes of foreign owners (path: $path)');
  }

  @override
  Future<NodeValue> deleteValue(String path, String key) async {
    // nothing to do
    return await _controller.deleteValue(path, key);
  }

  @override
  Future<List<SearchCriteria>> deregisterChangeListener(
      StorageListener listener) async {
    if (_sharingFilter) {
      StorageListener? pl = _listeners.remove(listener);
      if (pl == null) {
        return [];
      }
      return await _controller.deregisterChangeListener(pl);
    } else {
      return await _controller.deregisterChangeListener(listener);
    }
  }

  @override
  Future<void> flush() async {
    // nothing to do
    return await _controller.flush();
  }

  @override
  Future<Node> get(String path) async {
    // nothing to do
    Node node = await _controller.get(path);
    if (node.visibility == Visibility.white ||
        node.owner == _owner ||
        !_sharingFilter) {
      return node;
    }
    throw StorageException('access denied');
  }

  @override
  Future<Node> getNodeOrTombstone(String path) async {
    Node node = await _controller.getNodeOrTombstone(path);
    if (node.visibility == Visibility.white ||
        node.owner == _owner ||
        !_sharingFilter) {
      return node;
    }
    throw StorageException('access denied');
  }

  @override
  Future<NodeValue?> getValue(String path, String key) async {
    // nothing to do
    Node node = await _controller.get(path);
    if (node.visibility == Visibility.white ||
        node.owner == _owner ||
        !_sharingFilter) {
      return await _controller.getValue(path, key);
    }
    throw StorageException('access denied');
  }

  @override
  Future<void> registerChangeListener(
      StorageListener listener, SearchCriteria criteria) async {
    // nothing to do
    criteria.owner = owner;
    if (_sharingFilter) {
      _listeners[listener] = StorageListenerFilter(owner, listener);
      return await _controller.registerChangeListener(
          _listeners[listener]!, criteria);
    } else {
      _listeners[listener] = listener;
      return await _controller.registerChangeListener(listener, criteria);
    }
  }

  @override
  Future<void> rename(String oldPath, String newName) async {
    // nothing to do
    Node node = await _controller.get(oldPath);
    if (node.owner == _owner) {
      return await _controller.rename(oldPath, newName);
    }
    throw StorageException('access denied');
  }

  @override
  Future<List<Node>> search(SearchCriteria criteria) async {
    criteria.owner = owner;
    List<Node> nl = await _controller.search(criteria);
    // filter search results
    List<Node> ret = <Node>[];
    for (Node node in nl) {
      if (node.visibility == Visibility.white ||
          node.owner == _owner ||
          !_sharingFilter) {
        ret.add(node);
      }
    }
    return ret;
  }

  @override
  Future<void> update(Node node) async {
    // nothing to do
    node = _updateOwnerAndTimestamp(node);
    Node nodeOld = await _controller.get(node.path);
    if (nodeOld.owner == _owner) {
      return await _controller.update(node);
    }
    throw StorageException('access denied');
  }

  @override
  Future<void> updateValue(String nodeName, NodeValue value) async {
    if ((await _controller.get(nodeName)).owner == _owner) {
      return await _controller.updateValue(nodeName, value);
    }
    throw StorageException('access denied');
  }

  @override
  Future<void> zap() async {
    // external plugins may not zap the database
    // FIXME(mgwerder): Plugins should not be able to zap the database
    // throw StorageException('access denied');
    return await _controller.zap();
  }

  @override
  Future<bool> addOrUpdateValue(String path, NodeValue value) async {
    // nothing to do (Is that so?)
    if ((await _controller.get(path)).owner == _owner) {
      return await _controller.addOrUpdateValue(path, value);
    }
    throw StorageException('access denied');
  }

  @override
  Future<String> dump([String rootNode = ':', String prefix = '']) async {
    //TODO(mgwerder): filter search results of foreign owners
    return await _controller.dump(rootNode, prefix);
  }
}
