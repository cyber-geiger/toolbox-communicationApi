import 'dart:async';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_api/src/storage/owner_enforcer.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:test/test.dart';

import 'print_logger.dart';

Future<void> ownerEnforcerTests(final StorageController controller) async {
  final owner1 = PluginInformation('owner1', '', 0, Declaration.doShareData);
  final owner2 = PluginInformation('owner2', '', 0, Declaration.doShareData);

  test('Owner get Node', () async {
    OwnerEnforcerWrapper ownerEnforcerWrapper =
        OwnerEnforcerWrapper(controller, owner1);
    await ownerEnforcerWrapper.add(NodeImpl(':testNode1', owner1.id));
    Node node = await ownerEnforcerWrapper.get(':testNode1');
    expect(node.owner, owner1.id);
  });

  test('Owner get Node visibility', () async {
    OwnerEnforcerWrapper ownerEnforcerWrapper =
        OwnerEnforcerWrapper(controller, owner1);
    OwnerEnforcerWrapper ownerEnforcerWrapper2 =
        OwnerEnforcerWrapper(controller, owner2);
    Node nodeimpl = NodeImpl(':testNode2', owner2.id);
    nodeimpl.visibility = Visibility.white;
    await ownerEnforcerWrapper.add(nodeimpl);
    Node node = await ownerEnforcerWrapper2.get(':testNode2');
    expect(node.owner, owner1.id);
  });

  test('update Node', () async {
    OwnerEnforcerWrapper ownerEnforcerWrapper =
        OwnerEnforcerWrapper(controller, owner1);
    Node node = await ownerEnforcerWrapper.get(':testNode1');
    node.visibility = Visibility.amber;
    await ownerEnforcerWrapper.update(node);
    Node updatedNode = await ownerEnforcerWrapper.get(':testNode1');
    expect(updatedNode.visibility, Visibility.amber);
  });

  test('get Value', () async {
    OwnerEnforcerWrapper ownerEnforcerWrapper =
        OwnerEnforcerWrapper(controller, owner1);
    await ownerEnforcerWrapper.addValue(
        ':testNode1', NodeValueImpl('key1', 'value1'));
    NodeValue? value =
        await ownerEnforcerWrapper.getValue(':testNode1', 'key1');
    expect(value!.value, 'value1');
  });

  test('update Value', () async {
    OwnerEnforcerWrapper ownerEnforcerWrapper =
        OwnerEnforcerWrapper(controller, owner1);
    await ownerEnforcerWrapper.updateValue(
        ':testNode1', NodeValueImpl('key1', 'value2'));
    NodeValue? value =
        await ownerEnforcerWrapper.getValue(':testNode1', 'key1');
    expect(value!.value, 'value2');
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
