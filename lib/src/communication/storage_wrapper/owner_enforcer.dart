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
    return _controller.add(n);
  }

  @override
  Future<bool> addOrUpdate(Node node) async {
    Node n = await node.deepClone();
    n.owner = _owner;
    if (_enforceTimestampUpdate) {
      n.touch();
    }
    return _controller.addOrUpdate(n);
  }

  @override
  Future<void> addValue(String path, NodeValue value) async {
    if (_enforceTimestampUpdate) {
      value.touch();
    }
    return _controller.addValue(path, value);
  }

  @override
  Future<void> close() {
    // nothing to do
    return _controller.close();
  }

  @override
  Future<Node> delete(String path) {
    // nothing to do
    // timestamp is updated anyway
    return _controller.delete(path);
  }

  @override
  Future<NodeValue> deleteValue(String path, String key) {
    // nothing to do
    return _controller.deleteValue(path, key);
  }

  @override
  List<SearchCriteria> deregisterChangeListener(StorageListener listener) {
    // nothing to do
    return _controller.deregisterChangeListener(listener);
  }

  @override
  Future<void> flush() {
    // nothing to do
    return _controller.flush();
  }

  @override
  Future<Node> get(String path) {
    // nothing to do
    return _controller.get(path);
  }

  @override
  Future<Node> getNodeOrTombstone(String path) {
    // nothing to do
    return _controller.getNodeOrTombstone(path);
  }

  @override
  Future<NodeValue?> getValue(String path, String key) {
    // nothing to do
    return _controller.getValue(path, key);
  }

  @override
  void registerChangeListener(
      StorageListener listener, SearchCriteria criteria) {
    // nothing to do
    return _controller.registerChangeListener(listener, criteria);
  }

  @override
  Future<void> rename(String oldPath, String newName) {
    // nothing to do
    return _controller.rename(oldPath, newName);
  }

  @override
  Future<List<Node>> search(SearchCriteria criteria) {
    // nothing to do
    return _controller.search(criteria);
  }

  @override
  Future<void> update(Node node) async {
    // nothing to do
    return _controller.update(node);
  }

  @override
  Future<void> updateValue(String nodeName, NodeValue value) {
    // nothing to do
    return _controller.updateValue(nodeName, value);
  }

  @override
  Future<void> zap() {
    // nothing to do
    return _controller.zap();
  }
}
