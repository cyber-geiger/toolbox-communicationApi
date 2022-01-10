// ignore_for_file: avoid_print, prefer_const_constructors
import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:test/test.dart';

Future<void> updateTests(final StorageController controller) async {
  group('controller update tests', () {
    test('Owner Update On Node', () async {
      print('## Testing controller in UNKNOWN');
      await controller.add(NodeImpl(':testNodeOwner1', 'testOwner'));
      Node node = await controller.get(':testNodeOwner1');
      expect(node.owner, 'testOwner');
    });

    test('Storage Node Create', () async {
      await controller.add(NodeImpl(':StorageNodeCreate1', 'testOwner'));
      // fetch stored node
      Node storedNode = await controller.get(':StorageNodeCreate1');

      // check results
      expect(storedNode.owner, 'testOwner');
      expect(storedNode.name, 'StorageNodeCreate1');
      expect(storedNode.path, ':StorageNodeCreate1');
      expect(storedNode.visibility, Visibility.red);
    });

    test('Test Storage Node Add', () async {
      await controller.add(NodeImpl('parent1', 'testOwner', ':'));
      await controller.add(NodeImpl('name2', 'testOwner', ':parent1'));

      // get the record
      Node storedNode = await controller.get(':parent1:name2');

      // check results
      expect(storedNode.owner, 'testOwner');
      expect(storedNode.name, 'name2');
      expect(storedNode.path, ':parent1:name2');
      expect(storedNode.visibility, Visibility.red);
    });

    // depends on correct functionality of the StorageController.create() function
    test('test storage node update', () async {
      // create original node
      await controller.add(NodeImpl(':nodeUpdateTest', 'testOwner'));

      // updated Node with different visibility children
      Node node = NodeImpl(
          'testNode1', 'testOwner', ':nodeUpdateTest', Visibility.green);
      await controller.add(node);
      expect(node.owner, 'testOwner');

      Node sn =
          NodeImpl('testChild1', 'testOwner', ':nodeUpdateTest:testNode1');
      await controller.add(sn);
      node.visibility = Visibility.red;
      await node.addChild(sn);

      // update with node from above
      await controller.update(node);

      // get the record
      Node storedNode = await controller.get(':nodeUpdateTest:testNode1');

      // check results
      expect(storedNode.owner, 'testOwner');
      expect(storedNode.name, 'testNode1');
      expect(storedNode.path, ':nodeUpdateTest:testNode1');
      expect(await storedNode.getChildNodesCsv(), 'testChild1');
      expect(storedNode.visibility, Visibility.red);
    });

    test('add node with missing parent', () {
      expect(
          () async => await controller
              .add(NodeImpl('testNode1', 'testOwner', ':nodeUpdateTest2')),
          throwsA(TypeMatcher<StorageException>()));
    });

    test('create new node', () async {
      List<Node> n = <Node>[
        NodeImpl(':nodeCreateTest', 'testOwner'),
        NodeImpl(':nodeCreateTest:testNode1', 'testOwner')
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

Future<void> removeTests(StorageController controller) async {
  group('remove tests', () {
    test('remove node from storage', () async {
      await controller.add(NodeImpl('removalNode1', 'testOwner', ':'));
      Node node = NodeImpl('name1', 'testOwner', ':removalNode1');
      NodeValue nv = NodeValueImpl('key', 'value');
      await node.addValue(nv);
      await controller.add(node);
      Node removed = await controller.delete(':removalNode1:name1');

      // check nodes
      expect(node, removed, reason: 'removed node does not match added node');
      expect(() async => await controller.get(removed.path),
          throwsA(TypeMatcher<StorageException>()));

      // check values
      expect(await removed.getValue('key'), nv);
      expect(() async => await controller.getValue(removed.path, 'key'),
          throwsA(TypeMatcher<StorageException>()));
    });

    test('Remove node with children', () async {
      await controller.add(NodeImpl(':removalNode3', 'testOwner'));
      Node node = NodeImpl('name1', 'testOwner', ':removalNode3');
      // add child
      var nodeImpl = NodeImpl('child1', 'testOwner', ':removalNode3:name1');
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

Future<void> renameTests(StorageController controller) async {
  group('rename tests', () {
    test('rename node', () async {
      List<Node> nodes = <Node>[
        NodeImpl(':renameTests', 'testOwner'),
        NodeImpl('name1', 'testOwner', ':renameTests'),
        NodeImpl('name11', 'testOwner', ':renameTests:name1'),
        NodeImpl('name2', 'testOwner', ':renameTests'),
        NodeImpl('name21', 'testOwner', ':renameTests:name2'),
        NodeImpl('name3', 'testOwner', ':renameTests')
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
      expect(
          () async => await controller.rename(
              ':renameTests:name4', ':renameTests:name4a'),
          throwsA(TypeMatcher<StorageException>()));
      expect(
          () async => await controller.rename(':renameTests:name4', 'name4a'),
          throwsA(TypeMatcher<StorageException>()));

      // test rename to an existing node
      expect(
          () async => await controller.rename(
              ':renameTests:name2a', ':renameTests:name3'),
          throwsA(TypeMatcher<StorageException>()));
      expect(
          () async => await controller.rename(':renameTests:name2a', 'name3'),
          throwsA(TypeMatcher<StorageException>()));
    });

    test('Rename node with values', () async {
      List<Node> nodes = <Node>[
        NodeImpl(':renameTests3', 'testowner'),
        NodeImpl('name1', 'testowner', ':renameTests3'),
        NodeImpl('name2', 'testowner', ':renameTests3'),
        NodeImpl('name21', 'testowner', ':renameTests3:name2'),
        NodeImpl('name3', 'testowner', ':renameTests3')
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
      expect(
          () async => await controller.getValue(':renameTests3:name2', 'key2'),
          throwsA(TypeMatcher<StorageException>()));
      expect(
          () async =>
              await controller.getValue(':renameTests3:name2:name21', 'key2'),
          throwsA(TypeMatcher<StorageException>()));
    });
  });
}

void main() async {
  flushGeigerApiCache();
  final GeigerApi localMaster =
      (await getGeigerApi('', GeigerApi.masterId, Declaration.doNotShareData))!;
  await localMaster.zapState();
  await localMaster.getStorage()!.zap();
  final GeigerApi? pluginApi =
      await getGeigerApi('./plugin1', 'testOwner', Declaration.doNotShareData);
  final StorageController controller = pluginApi!.getStorage()!;

  // all tests related to updates of nodes and values
  await updateTests(controller);

  // all tests related to rename of nodes
  await renameTests(controller);

  // all tests related to the removal of nodes
  await removeTests(controller);

  test('Check addOrUpdateValue', () async {
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
    await controller.add(NodeImpl(nodeName, 'owner'));
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
}