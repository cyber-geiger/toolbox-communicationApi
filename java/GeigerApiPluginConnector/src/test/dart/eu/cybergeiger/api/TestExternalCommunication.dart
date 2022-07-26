import 'package:flutter_test/flutter_test.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

import '../../../utils/message_collector.dart';

const pluginId = "plugin";
const menuId = "menu";

void assertRequestMessage(Message actual, MessageType type, String function) {
  expect(actual.sourceId, pluginId);
  expect(actual.targetId, GeigerApi.masterId);
  expect(actual.type, type);
  expect(actual.action, GeigerUrl(null, GeigerApi.masterId, function));
}

Future<GeigerApi> createMaster() async {
  return (await getGeigerApi(
      '', GeigerApi.masterId, Declaration.doNotShareData))!;
}

Future<MenuItem> generateTestMenu() async {
  Node menu = await NodeImpl.fromPath(':$menuId', pluginId,
      nodeValues: [NodeValueImpl('name', 'test')]);
  menu.lastModified = 0;
  return MenuItem(menu, GeigerUrl(null, pluginId, menuId), true);
}

void main() {
  test('testRegisterExternalPlugin', () async {
    final master = await createMaster();
    final collector = MessageCollector(master);
    assertRequestMessage(await collector.awaitMessage(0),
        MessageType.registerPlugin, 'registerPlugin');
    await collector.awaitCount(2);
    await master.close();
  });
  test('testActivatePlugin', () async {
    final master = await createMaster();
    final collector = MessageCollector(master);
    assertRequestMessage(await collector.awaitMessage(1),
        MessageType.activatePlugin, "activatePlugin");
    await master.close();
  });
  test('testDeactivatePlugin', () async {
    final master = await createMaster();
    final collector = MessageCollector(master);
    assertRequestMessage(await collector.awaitMessage(2),
        MessageType.deregisterPlugin, 'deregisterPlugin');
    await master.close();
  });
  test('testRegisterMenu', () async {
    final master = await createMaster();
    final collector = MessageCollector(master);
    final message = await collector.awaitMessage(2);
    assertRequestMessage(message, MessageType.registerMenu, 'registerMenu');
    expect(
        await MenuItem.fromByteArrayStream(ByteStream(null, message.payload)),
        await generateTestMenu());
    await master.close();
  });
  test('testDisableMenu', () async {
    final master = await createMaster();
    final collector = MessageCollector(master);
    final message = await collector.awaitMessage(3);
    assertRequestMessage(message, MessageType.disableMenu, 'disableMenu');
    expect(message.payloadString, menuId);
    await master.close();
  });
  test('testMenuPressed', () async {
    final master = await createMaster();
    final collector = MessageCollector(master);
    await collector.awaitCount(3);
    master.menuPressed(master.getMenuList().first.action);
    await master.close();
  });
}
