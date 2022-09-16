// ignore_for_file: avoid_print, prefer_const_constructors
import 'dart:async';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:test/test.dart';

import 'print_logger.dart';

Future<void> updateTests() async {
  group('controller update tests', () {
    storageTest('Owner Update On Node', (controller, _) async {
      print('## Testing controller in UNKNOWN');
      await controller.add(NodeImpl(':testNodeOwner1', owner));
      Node node = await controller.get(':testNodeOwner1');
      expect(node.owner, owner);
    });

    storageTest('Storage Node Create', (controller, _) async {
      await controller.add(NodeImpl(':StorageNodeCreate1', owner));
      // fetch stored node
      Node storedNode = await controller.get(':StorageNodeCreate1');

      // check results
      expect(storedNode.owner, owner);
      expect(storedNode.name, 'StorageNodeCreate1');
      expect(storedNode.path, ':StorageNodeCreate1');
      expect(storedNode.visibility, Visibility.red);
    });

    storageTest('Test Storage Node Add', (controller, _) async {
      await controller.add(NodeImpl('parent1', owner, ':'));
      await controller.add(NodeImpl('name2', owner, ':parent1'));

      // get the record
      Node storedNode = await controller.get(':parent1:name2');

      // check results
      expect(storedNode.owner, owner);
      expect(storedNode.name, 'name2');
      expect(storedNode.path, ':parent1:name2');
      expect(storedNode.visibility, Visibility.red);
    });

    // depends on correct functionality of the StorageController.create() function
    storageTest('test storage node update', (controller, _) async {
      // create original node
      await controller.add(NodeImpl(':nodeUpdateTest', owner));

      // updated Node with different visibility children
      Node node =
          NodeImpl('testNode1', owner, ':nodeUpdateTest', Visibility.green);
      await controller.add(node);
      expect(node.owner, owner);

      Node sn = NodeImpl('testChild1', owner, ':nodeUpdateTest:testNode1');
      await controller.add(sn);
      node.visibility = Visibility.red;
      await node.addChild(sn);

      // update with node from above
      await controller.update(node);

      // get the record
      Node storedNode = await controller.get(':nodeUpdateTest:testNode1');

      // check results
      expect(storedNode.owner, owner);
      expect(storedNode.name, 'testNode1');
      expect(storedNode.path, ':nodeUpdateTest:testNode1');
      expect(await storedNode.getChildNodesCsv(), 'testChild1');
      expect(storedNode.visibility, Visibility.red);
    });

    storageTest(
        'add node with missing parent',
        (controller, _) => expectFutureThrowsException<StorageException>(() =>
            controller.add(NodeImpl('testNode1', owner, ':nodeUpdateTest2'))));

    storageTest('create new node', (controller, _) async {
      List<Node> n = <Node>[
        NodeImpl(':nodeCreateTest', owner),
        NodeImpl(':nodeCreateTest:testNode1', owner)
      ];

      for (final Node tn in n) {
        print('## creating new node ${tn.path} (parent of ${tn.parentPath})');
        await controller.add(tn);
      }

      // add a value
      print('## adding value');
      await controller.addValue(
          ':nodeCreateTest:testNode1', NodeValueImpl('key1', 'valueFirst'));

      // update value
      print('## updating value');
      NodeValue value2 = NodeValueImpl('key1', 'valueSecond');
      await controller.updateValue(':nodeCreateTest:testNode1', value2);

      // get the record
      print('## testing updated value');
      Node n2 = await controller.get(':nodeCreateTest:testNode1');
      expect((await n2.getValue(value2.key))?.value, value2.value);

      print(
          '## testing removal of node ${n.first} with child nodes (${n.last.path})');

      try {
        await controller.delete(n[0].path);
        fail('Parental node was deleted despite a child node exists');
      } on StorageException catch (e) {
        print('## got expected exception when deleting parent node ($e)');
      } catch (e) {
        fail('got exception of wrong type ${e.toString()}');
      }

      for (final Node tn in List.from(n.reversed)) {
        print('## removing node ${tn.path} (parent of ${tn.parentPath})');
        await controller.delete(tn.path);
      }
    });
  });
}

Future<void> removeTests() async {
  group('remove tests', () {
    storageTest('remove node from storage', (controller, _) async {
      await controller.add(NodeImpl('removalNode1', owner, ':'));
      Node node = NodeImpl('name1', owner, ':removalNode1');
      NodeValue nv = NodeValueImpl('key', 'value');
      await node.addValue(nv);
      await controller.add(node);
      Node removed = await controller.delete(':removalNode1:name1');

      // check nodes
      expect(node, removed, reason: 'removed node does not match added node');
      await expectFutureThrowsException<StorageException>(
          () async => await controller.get(removed.path));

      // check values
      expect(await removed.getValue('key'), nv);
      await expectFutureThrowsException<StorageException>(
          () => controller.getValue(removed.path, 'key'));
    });

    storageTest('Remove node with children', (controller, _) async {
      await controller.add(NodeImpl(':removalNode3', owner));
      Node node = NodeImpl('name1', owner, ':removalNode3');
      // add child
      var nodeImpl = NodeImpl('child1', owner, ':removalNode3:name1');
      Node childNode = nodeImpl;
      await node.addChild(childNode);
      await controller.addOrUpdate(node);
      await controller.addOrUpdate(childNode);

      expect(() async => await controller.delete(':removalNode3:name1'),
          throwsA(TypeMatcher<StorageException>()));

      // check if node still exists and is equal
      expect(node.equals(await controller.get(':removalNode3:name1')), isTrue);
    });
  });
}

Future<void> renameTests() async {
  group('rename tests', () {
    storageTest('rename node', (controller, _) async {
      List<Node> nodes = <Node>[
        NodeImpl(':renameTests', owner),
        NodeImpl('name1', owner, ':renameTests'),
        NodeImpl('name11', owner, ':renameTests:name1'),
        NodeImpl('name2', owner, ':renameTests'),
        NodeImpl('name21', owner, ':renameTests:name2'),
        NodeImpl('name3', owner, ':renameTests')
      ];
      for (Node n in nodes) {
        await controller.add(n);
      }

      // rename by name
      await controller.rename(':renameTests:name1', 'name1a');

      // rename by path
      await controller.rename(':renameTests:name2', ':renameTests:name2a');

      // check old nodes
      expect(() async => await controller.get(':renameTests:name1'),
          throwsA(TypeMatcher<StorageException>()));
      expect(() async => await controller.get(':renameTests:name2'),
          throwsA(TypeMatcher<StorageException>()));

      // check new nodes
      for (final name in [':renameTests:name1a', ':renameTests:name2a']) {
        expect((await controller.get(name)).path, name,
            reason: 'renaming node seems unsuccessful (new node missing)');
      }
      // check name
      expect((await controller.get(':renameTests:name1a')).name, 'name1a',
          reason: 'renaming node seems unsuccessful (new node name wrong)');
      expect((await controller.get(':renameTests:name2a')).name, 'name2a',
          reason: 'renaming node seems unsuccessful (new node name wrong)');

      // check path
      expect((await controller.get(':renameTests:name1a')).path,
          ':renameTests:name1a',
          reason: 'renaming node seems unsuccessful (new node path wrong)');

      expect((await controller.get(':renameTests:name2a')).path,
          ':renameTests:name2a',
          reason: 'renaming node seems unsuccessful (new node path wrong)');

      // check child nodes
      for (final String name in <String>[
        ':renameTests:name1a:name11',
        ':renameTests:name2a:name21'
      ]) {
        expect((await controller.get(name)).path, name,
            reason: 'renaming node seems unsuccessful (sub-node missing)');
      }
      // check child node name
      expect(
          'name11', (await controller.get(':renameTests:name1a:name11')).name,
          reason: 'renaming node seems unsuccessful (sub-node name wrong)');
      expect(
          'name21', (await controller.get(':renameTests:name2a:name21')).name,
          reason: 'renaming node seems unsuccessful (sub-node name wrong)');

      // check child node path
      expect((await controller.get(':renameTests:name1a:name11')).path,
          ':renameTests:name1a:name11',
          reason: 'renaming node seems unsuccessful (sub-node path wrong)');
      expect((await controller.get(':renameTests:name2a:name21')).path,
          ':renameTests:name2a:name21',
          reason: 'renaming node seems unsuccessful (sub-node path wrong)');

      // test rename of non existing nodes
      await expectFutureThrowsException<StorageException>(
          () => controller.rename(':renameTests:name4', ':renameTests:name4a'));
      await expectFutureThrowsException<StorageException>(
          () => controller.rename(':renameTests:name4', 'name4a'));

      // test rename to an existing node
      await expectFutureThrowsException<StorageException>(
          () => controller.rename(':renameTests:name2a', ':renameTests:name3'));
      await expectFutureThrowsException<StorageException>(
          () => controller.rename(':renameTests:name2a', 'name3'));
    });

    storageTest('Rename node with values', (controller, _) async {
      List<Node> nodes = <Node>[
        NodeImpl(':renameTests3', owner),
        NodeImpl('name1', owner, ':renameTests3'),
        NodeImpl('name2', owner, ':renameTests3'),
        NodeImpl('name21', owner, ':renameTests3:name2'),
        NodeImpl('name3', owner, ':renameTests3')
      ];

      NodeValue nv = NodeValueImpl('key', 'value');
      NodeValue nv1 = NodeValueImpl('key1', 'value1');
      NodeValue nv2 = NodeValueImpl('key2', 'value2');
      NodeValue nv21 = NodeValueImpl('key21', 'value21');

      await nodes[0].addValue(nv);
      await nodes[1].addValue(nv1);
      await nodes[2].addValue(nv2);
      await nodes[3].addValue(nv21);

      for (final Node n in nodes) {
        await controller.add(n);
      }
      await controller.rename(':renameTests3:name2', ':renameTests3:name2a');

      // check old node
      expect(() async => await controller.get(':renameTests:name2'),
          throwsA(TypeMatcher<StorageException>()));

      expect((await controller.get(':renameTests3:name2a')).path,
          ':renameTests3:name2a',
          reason: 'renaming node seems unsuccessful (new node missing)');
      expect((await controller.get(':renameTests3:name2a')).name, 'name2a',
          reason: 'renaming node seems unsuccessful (new node name wrong)');
      expect((await controller.get(':renameTests3:name2a')).path,
          ':renameTests3:name2a',
          reason: 'renaming node seems unsuccessful (new node path wrong)');
      expect(await controller.get(':renameTests3:name2a:name21'), isNotNull,
          reason: 'renaming node seems unsuccessful (sub-node missing)');
      expect(
          (await controller.get(':renameTests3:name2a:name21')).name, 'name21',
          reason: 'renaming node seems unsuccessful (sub-node missing)');
      expect((await controller.get(':renameTests3:name2a:name21')).path,
          ':renameTests3:name2a:name21',
          reason: 'renaming node seems unsuccessful (sub-node path wrong)');

      // check values
      var value = await (await controller.get(':renameTests3')).getValue('key');
      expect(value, nv, reason: 'value lost on parent');
      expect(
          await (await controller.get(':renameTests3:name1')).getValue('key1'),
          nv1,
          reason: 'value lost on sibling');
      expect(
          await (await controller.get(':renameTests3:name2a')).getValue('key2'),
          nv2,
          reason: 'value lost moved node');
      expect(
          await (await controller.get(':renameTests3:name2a:name21'))
              .getValue('key21'),
          nv21,
          reason: 'value lost on sub-node');

      // check old values
      await expectFutureThrowsException<StorageException>(
          () => controller.getValue(':renameTests3:name2', 'key2'));
      await expectFutureThrowsException<StorageException>(
          () => controller.getValue(':renameTests3:name2:name21', 'key2'));
    });
  });
}

class ChangeEvent {
  final EventType type;
  final Node? oldNode;
  final Node? newNode;

  ChangeEvent(this.type, this.oldNode, this.newNode);

  @override
  String toString() {
    return 'ChangeEvent{type: $type, oldNode: $oldNode, newNode: $newNode}';
  }
}

class _ConditionalCompleter {
  final bool Function(List<ChangeEvent>) canComplete;
  final List<ChangeEvent> Function(List<ChangeEvent>) createResult;

  final _completer = Completer<List<ChangeEvent>>();

  Future<List<ChangeEvent>> get future => _completer.future;

  _ConditionalCompleter(this.canComplete, this.createResult);

  void complete(List<ChangeEvent> events) {
    if (!canComplete(events)) return;
    _completer.complete(createResult(events));
  }
}

class CollectingListener with StorageListener {
  final List<ChangeEvent> events = [];

  final Set<_ConditionalCompleter> completers = {};

  @override
  Future<void> gotStorageChange(
      EventType event, Node? oldNode, Node? newNode) async {
    events.add(ChangeEvent(event, oldNode, newNode));
    for (final completer in completers) {
      completer.complete(events);
    }
  }

  Future<List<ChangeEvent>> awaitCount(int count,
      [Duration timeLimit = const Duration(seconds: 1)]) {
    bool canComplete(List events) => events.length >= count;
    List<ChangeEvent> createResult(List<ChangeEvent> events) =>
        List<ChangeEvent>.from(events.getRange(0, count));
    if (canComplete(events)) {
      return Future.value(createResult(events));
    }

    final completer = _ConditionalCompleter(canComplete, createResult);
    completers.add(completer);
    return completer.future.timeout(timeLimit, onTimeout: () {
      completers.remove(completer);
      throw TimeoutException(
          'Did not receive enough change events before timeout.', timeLimit);
    });
  }
}

const owner = 'test-owner';

void storageTest(String name,
    Future Function(StorageController controller, GeigerApi master) body) {
  test(name, () async {
    flushGeigerApiCache();
    final master = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    await master.zapState();
    await master.storage.zap();
    final plugin =
        (await getGeigerApi(';;', owner, Declaration.doNotShareData))!;
    await plugin.registerPlugin();
    await plugin.activatePlugin();
    try {
      await body(plugin.storage, master);
    } finally {
      await plugin.close();
      await master.close();
    }
  });
}

Future expectFutureThrowsException<TException>(Future Function() body) async {
  try {
    await body();
    fail('Expected exception was not thrown.');
  } catch (e) {
    expect(e, isA<TException>());
  }
}

void main() async {
  printLogger();

  // all tests related to updates of nodes and values
  await updateTests();

  // all tests related to rename of nodes
  await renameTests();

  // all tests related to the removal of nodes
  await removeTests();

  storageTest('Check addOrUpdateValue', (controller, _) async {
    String nodeName = ':addOrDeleteValueTest';
    // make sure that node does not exist
    try {
      await controller.delete(nodeName);
    } on StorageException {
      // ignore the fact that the node does not exist
    }
    expect(
        () async => await controller.addOrUpdateValue(
            nodeName, NodeValueImpl('key', 'value')),
        throwsA(const TypeMatcher<StorageException>()),
        reason: 'unexpectedly successful missing node');
    await controller.add(NodeImpl(nodeName, owner));
    expect(await controller.getValue(nodeName, 'key'), isNull);
    expect(
        await controller.addOrUpdateValue(
            nodeName, NodeValueImpl('key', 'value')),
        isTrue);
    expect(await controller.getValue(nodeName, 'key'), isNotNull);
    expect(
        await controller.addOrUpdateValue(
            nodeName, NodeValueImpl('key', 'value')),
        isFalse);
  });
  group('change listener', () {
    storageTest('register/deregister', (controller, _) async {
      final listener = CollectingListener();
      final criteria = SearchCriteria();

      await controller.registerChangeListener(listener, criteria);
      // test overwrite
      await controller.registerChangeListener(listener, criteria);
      var result = await controller.deregisterChangeListener(listener);

      expect(result.length, 1);
      expect(result.first, criteria);

      // test deregister unregistered listener
      expect(() => controller.deregisterChangeListener(listener),
          throwsA(const TypeMatcher<StorageException>()));
    });

    group('event types', () {
      void testEventType(
          EventType expectedType,
          Node? expectedOldNode,
          Future<void> Function(StorageController) setup,
          Future<Node?> Function(StorageController) execute) {
        storageTest(expectedType.toValueString(), (controller, _) async {
          final listener = CollectingListener();
          final criteria = SearchCriteria();

          await setup(controller);
          await controller.registerChangeListener(listener, criteria);
          final expectedNewNode = await execute(controller);

          await listener.awaitCount(1, Duration(seconds: 30));
          await controller.deregisterChangeListener(listener);
          expect(listener.events.length, 1);
          final event = listener.events.first;
          expect(event.type, expectedType);
          expect(event.oldNode, expectedOldNode);
          expect(event.newNode, expectedNewNode);
        });
      }

      {
        final node = NodeImpl(':testNode', owner);
        testEventType(EventType.create, null, (_) async {}, (controller) async {
          await controller.add(node);
          return node;
        });
      }
      {
        const path = ':testNode';
        final oldNode = NodeImpl(path, owner);
        final newNode = NodeImpl(path, owner, null, Visibility.amber);
        testEventType(EventType.update, oldNode, (controller) async {
          await controller.add(oldNode);
        }, (controller) async {
          await controller.update(newNode);
          return newNode;
        });
      }
      {
        const path = ':testNode';
        final node = NodeImpl(path, owner);
        testEventType(EventType.delete, node, (controller) async {
          await controller.add(node);
        }, (controller) async {
          await controller.delete(path);
          return null;
        });
      }
      {
        const oldPath = ':oldTestNode';
        const newPath = ':newTestNode';
        final node = NodeImpl(oldPath, owner);
        testEventType(EventType.rename, node, (controller) async {
          await controller.add(node);
        }, (controller) async {
          await controller.rename(oldPath, newPath);
          return await controller.get(newPath);
        });
      }
    });

    storageTest('with criteria', (controller, _) async {
      const path = ':testNode';
      final node = NodeImpl(path, owner);
      final otherNode = NodeImpl(':otherTestNode', owner);

      final listener = CollectingListener();
      final criteria = SearchCriteria(searchPath: path);

      await controller.registerChangeListener(listener, criteria);
      await controller.add(otherNode);
      await controller.add(node);
      otherNode.lastModified = 1640991600000;
      await controller.update(otherNode);

      await listener.awaitCount(1);
      expect(listener.events.length, 1);
      expect(listener.events.first.newNode?.path, path,
          reason: 'Received event for the wrong node.');
    });

    storageTest('listen on master', (controller, master) async {
      final node = NodeImpl(':testNode', owner);

      final listener = CollectingListener();
      final criteria = SearchCriteria();
      final masterController = master.storage;

      await masterController.registerChangeListener(listener, criteria);
      await controller.add(node);

      await listener.awaitCount(1);
      await masterController.deregisterChangeListener(listener);
      expect(listener.events.length, 1);
      final event = listener.events.first;
      expect(event.type, EventType.create);
      expect(event.oldNode, null);
      expect(event.newNode, node);
    });
  });
}
