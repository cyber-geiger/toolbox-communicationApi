import 'dart:async';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_api/src/storage/owner_enforcer.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:test/test.dart';

import 'print_logger.dart';

Future<void> ownerEnforcerTests(final StorageController controller) async {
  test('Owner get Node', () async {
    OwnerEnforcerWrapper ownerEnforcerWrapper =
        OwnerEnforcerWrapper(controller, 'testOwner');
    await ownerEnforcerWrapper.add(NodeImpl(':testNode1', 'testOwner'));
    Node node = await ownerEnforcerWrapper.get(':testNode1');
    expect(node.owner, 'testOwner');
  });

  test('Owner get Node visibility', () async {
    OwnerEnforcerWrapper ownerEnforcerWrapper =
        OwnerEnforcerWrapper(controller, 'testOwner');
    OwnerEnforcerWrapper ownerEnforcerWrapper2 =
        OwnerEnforcerWrapper(controller, 'testOwner2');
    Node nodeimpl = NodeImpl(':testNode2', 'testOwner2');
    nodeimpl.visibility = Visibility.white;
    await ownerEnforcerWrapper.add(nodeimpl);
    Node node = await ownerEnforcerWrapper2.get(':testNode2');
    expect(node.owner, 'testOwner');
  });

  test('update Node', () async {
    OwnerEnforcerWrapper ownerEnforcerWrapper =
        OwnerEnforcerWrapper(controller, 'testOwner');
    Node node = await ownerEnforcerWrapper.get(':testNode1');
    node.visibility = Visibility.amber;
    await ownerEnforcerWrapper.update(node);
    Node updatedNode = await ownerEnforcerWrapper.get(':testNode1');
    expect(updatedNode.visibility, Visibility.amber);
  });

  test('get Value', () async {
    OwnerEnforcerWrapper ownerEnforcerWrapper =
        OwnerEnforcerWrapper(controller, 'testOwner');
    await ownerEnforcerWrapper.addValue(
        ":testNode1", NodeValueImpl("key1", "value1"));
    NodeValue? value =
        await ownerEnforcerWrapper.getValue(':testNode1', 'key1');
    expect(value!.value, 'value1');
  });

  test('update Value', () async {
    OwnerEnforcerWrapper ownerEnforcerWrapper =
        OwnerEnforcerWrapper(controller, 'testOwner');
    await ownerEnforcerWrapper.updateValue(
        ':testNode1', NodeValueImpl("key1", "value2"));
    NodeValue? value =
        await ownerEnforcerWrapper.getValue(':testNode1', 'key1');
    expect(value!.value, "value2");
  });
}

void main() async {
  printLogger();
  flushGeigerApiCache();
  final GeigerApi localMaster =
      (await getGeigerApi('', GeigerApi.masterId, Declaration.doNotShareData))!;
  await localMaster.zapState();
  await localMaster.storage.zap();
  await ownerEnforcerTests(localMaster.storage);
}
