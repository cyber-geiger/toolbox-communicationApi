library geiger_localstorage;

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

class StorageListenerFilter extends StorageListener {
  final StorageListener _listener;
  final PluginInformation _owner;

  StorageListenerFilter(this._owner, this._listener);

  bool _canStay(Node node) {
    return (node.visibility == Visibility.white && node.owner == _owner.id) ||
        _owner.declaration == Declaration.doNotShareData;
  }

  @override
  void gotStorageChange(EventType event, Node? oldNode, Node? newNode) {
    if (oldNode != null && !_canStay(oldNode)) {
      oldNode = null;
    }
    if (newNode != null && !_canStay(newNode)) {
      newNode = null;
    }

    if (oldNode == null && newNode == null) return;
    _listener.gotStorageChange(event, oldNode, newNode);
  }
}

class OwnerEnforcerWrapper extends StorageController {
  final StorageController _controller;
  final PluginInformation owner;
  final bool enforceTimestampUpdate;

  final Map<StorageListener, StorageListener> _listeners = {};

  OwnerEnforcerWrapper(this._controller, this.owner,
      {this.enforceTimestampUpdate = true});

  Node _updateOwnerAndTimestamp(Node n) {
    if (n.owner != owner.id) {
      (n as NodeImpl).set(Field.owner, owner.id);
      if (enforceTimestampUpdate) {
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
    if (enforceTimestampUpdate) {
      value.touch();
    }
    final actualOwner = (await _controller.getNodeOrTombstone(path)).owner;
    if (actualOwner != owner.id) {
      throw StorageException(
          'Cannot add node value to foreign node (owned by $actualOwner).');
    }
    return await _controller.addValue(path, value);
  }

  @override
  Future<void> close() async {
    throw StorageException('access denied');
  }

  @override
  Future<Node> delete(String path) async {
    final node = await _controller.getNodeOrTombstone(path);
    if (node.owner == owner.id) {
      return await _controller.delete(path);
    }
    throw StorageException(
        'cannot delete nodes of foreign owners (path: $path)');
  }

  @override
  Future<NodeValue> deleteValue(String path, String key) async {
    return await _controller.deleteValue(path, key);
  }

  @override
  Future<List<SearchCriteria>> deregisterChangeListener(
      StorageListener listener) async {
    if (owner.declaration == Declaration.doShareData) {
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
    return await _controller.flush();
  }

  @override
  Future<Node> get(String path) async {
    // nothing to do
    Node node = await _controller.get(path);
    if (node.visibility == Visibility.white ||
        node.owner == owner.id ||
        owner.declaration == Declaration.doNotShareData) {
      return node;
    }
    throw StorageException('access denied');
  }

  @override
  Future<Node> getNodeOrTombstone(String path) async {
    Node node = await _controller.getNodeOrTombstone(path);
    if (node.visibility == Visibility.white ||
        node.owner == owner.id ||
        owner.declaration == Declaration.doNotShareData) {
      return node;
    }
    throw StorageException('access denied');
  }

  @override
  Future<NodeValue?> getValue(String path, String key) async {
    // nothing to do
    Node node = await _controller.get(path);
    if (node.visibility == Visibility.white ||
        node.owner == owner.id ||
        owner.declaration == Declaration.doNotShareData) {
      return await _controller.getValue(path, key);
    }
    throw StorageException('access denied');
  }

  @override
  Future<void> registerChangeListener(
      StorageListener listener, SearchCriteria criteria) async {
    if (owner.declaration == Declaration.doShareData) {
      _listeners[listener] = listener = StorageListenerFilter(owner, listener);
    } else {
      _listeners[listener] = listener;
    }
    return await _controller.registerChangeListener(listener, criteria);
  }

  @override
  Future<void> rename(String oldPath, String newName) async {
    Node node = await _controller.get(oldPath);
    if (node.owner == owner.id) {
      return await _controller.rename(oldPath, newName);
    }
    throw StorageException('access denied');
  }

  @override
  Future<List<Node>> search(SearchCriteria criteria) async {
    List<Node> nl = await _controller.search(criteria);
    List<Node> ret = <Node>[];
    for (Node node in nl) {
      if (node.visibility == Visibility.white ||
          node.owner == owner.id ||
          owner.declaration == Declaration.doNotShareData) {
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
    if (nodeOld.owner == owner.id) {
      return await _controller.update(node);
    }
    throw StorageException('access denied');
  }

  @override
  Future<void> updateValue(String nodeName, NodeValue value) async {
    if ((await _controller.get(nodeName)).owner == owner.id) {
      return await _controller.updateValue(nodeName, value);
    }
    throw StorageException('access denied');
  }

  @override
  Future<void> zap() async {
    throw StorageException('access denied');
  }

  @override
  Future<bool> addOrUpdateValue(String path, NodeValue value) async {
    // nothing to do (Is that so?)
    if ((await _controller.get(path)).owner == owner.id) {
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
