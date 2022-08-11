import 'package:flutter_test/flutter_test.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

import '../../../utils/api.dart';
import '../../../utils/logger.dart';

const pluginId = "plugin";
const menuId = "menu";

void assertRequestMessage(Message actual, MessageType type, String function) {
  expect(actual.sourceId, pluginId);
  expect(actual.targetId, GeigerApi.masterId);
  expect(actual.type, type);
  expect(actual.action, GeigerUrl(null, GeigerApi.masterId, function));
}

Future<MenuItem> generateTestMenu() async {
  Node menu = await NodeImpl.fromPath(':$menuId', pluginId, nodeValues: [
    NodeValueImpl('name', 'test'),
    NodeValueImpl('tooltip', 'test')
  ]);
  menu.lastModified = 0;
  return MenuItem(menu, GeigerUrl(null, pluginId, menuId), true);
}

void main() {
  printLogger();
  testMaster('testRegisterExternalPlugin', (master, collector) async {
    assertRequestMessage(await collector.awaitMessage(0),
        MessageType.registerPlugin, 'registerPlugin');
    await collector.awaitCount(2);
  });
  testMaster('testActivatePlugin', (master, collector) async {
    assertRequestMessage(await collector.awaitMessage(1),
        MessageType.activatePlugin, "activatePlugin");
  });
  testMaster('testDeactivatePlugin', (master, collector) async {
    assertRequestMessage(await collector.awaitMessage(2),
        MessageType.deregisterPlugin, 'deregisterPlugin');
  });
  testMaster('testRegisterMenu', (master, collector) async {
    final message = await collector.awaitMessage(2);
    assertRequestMessage(message, MessageType.registerMenu, 'registerMenu');
    expect(
        await MenuItem.fromByteArrayStream(ByteStream(null, message.payload)),
        await generateTestMenu());
  });
  testMaster('testDisableMenu', (master, collector) async {
    final message = await collector.awaitMessage(3);
    assertRequestMessage(message, MessageType.disableMenu, 'disableMenu');
    expect(message.payloadString, menuId);
  });
  testMaster('testMenuPressed', (master, collector) async {
    await collector.awaitCount(3);
    master.menuPressed(master.getMenuList().first.action);
  });
}
