library geiger_localstorage;

import 'package:geiger_localstorage/geiger_localstorage.dart';

class OwnerEnforcerWrapper extends StorageController {
  final StorageController _controller;
  final String _owner;
  final bool _enforceTimestampUpdate;

  OwnerEnforcerWrapper(this._controller, this._owner,
      [this._enforceTimestampUpdate = true]);

  String get owner => _owner;

  bool get enforceTimestampUpdate => _enforceTimestampUpdate;

  @override
  Future<void> add(Node node) async {
    Node n = await node.deepClone();
    n.owner = _owner;
    if (_enforceTimestampUpdate) {
      n.touch();
    }
    return await _controller.add(n);
  }

  @override
  Future<bool> addOrUpdate(Node node) async {
    Node n = await node.deepClone();
    n.owner = _owner;
    if (_enforceTimestampUpdate) {
      n.touch();
    }
    return await _controller.addOrUpdate(n);
  }

  @override
  Future<void> addValue(String path, NodeValue value) async {
    if (_enforceTimestampUpdate) {
      value.touch();
    }
    return await _controller.addValue(path, value);
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
    return await _controller.delete(path);
  }

  @override
  Future<NodeValue> deleteValue(String path, String key) async {
    // nothing to do
    return await _controller.deleteValue(path, key);
  }

  @override
  Future<List<SearchCriteria>> deregisterChangeListener(
      StorageListener listener) async {
    // nothing to do
    return await _controller.deregisterChangeListener(listener);
  }

  @override
  Future<void> flush() async {
    // nothing to do
    return await _controller.flush();
  }

  @override
  Future<Node> get(String path) async {
    // nothing to do
    return await _controller.get(path);
  }

  @override
  Future<Node> getNodeOrTombstone(String path) async {
    // nothing to do
    return await _controller.getNodeOrTombstone(path);
  }

  @override
  Future<NodeValue?> getValue(String path, String key) async {
    // nothing to do
    return await _controller.getValue(path, key);
  }

  @override
  Future<void> registerChangeListener(
      StorageListener listener, SearchCriteria criteria) async {
    // nothing to do
    return await _controller.registerChangeListener(listener, criteria);
  }

  @override
  Future<void> rename(String oldPath, String newName) async {
    // nothing to do
    return await _controller.rename(oldPath, newName);
  }

  @override
  Future<List<Node>> search(SearchCriteria criteria) async {
    // nothing to do
    return await _controller.search(criteria);
  }

  @override
  Future<void> update(Node node) async {
    // nothing to do
    return await _controller.update(node);
  }

  @override
  Future<void> updateValue(String nodeName, NodeValue value) async {
    // nothing to do
    return await _controller.updateValue(nodeName, value);
  }

  @override
  Future<void> zap() async {
    // nothing to do
    return await _controller.zap();
  }

  @override
  Future<bool> addOrUpdateValue(String path, NodeValue value) async {
    // nothing to do (Is that so?)
    return await _controller.addOrUpdateValue(path, value);
  }

  @override
  Future<String> dump([String rootNode = ':', String prefix = '']) async {
    return await _controller.dump(rootNode, prefix);
  }
}
