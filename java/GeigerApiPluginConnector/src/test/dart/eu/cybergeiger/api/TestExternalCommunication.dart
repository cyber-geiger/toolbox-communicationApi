import 'package:flutter_test/flutter_test.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

import '../../../utils/message_collector.dart';

const pluginId = "plugin";
const menuId = "menu";

Future<MenuItem> generateTestMenu() async {
  Node menu = await NodeImpl.fromPath(':$menuId', pluginId,
      nodeValues: [NodeValueImpl('name', 'test')]);
  menu.lastModified = 0;
  return MenuItem(menu, GeigerUrl(null, pluginId, menuId), true);
}

void main() {
  test('testRegisterExternalPlugin', () async {
    final master = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    final collector = MessageCollector();
    master.registerListener(MessageType.values, collector);
    await collector.awaitCount(1);
    final message = collector.messages[0];
    expect(message.type, MessageType.registerPlugin);
    expect(message.sourceId, pluginId);
    expect(message.action?.protocol, GeigerUrl.geigerProtocol);
    expect(message.action?.plugin, GeigerApi.masterId);
    expect(message.action?.path, 'registerPlugin');
    await collector.awaitCount(2);
    await master.close();
  });
  test('testActivatePlugin', () async {
    final master = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    final collector = MessageCollector();
    master.registerListener(MessageType.values, collector);
    await collector.awaitCount(2);
    final message = collector.messages[1];
    expect(message.type, MessageType.activatePlugin);
    expect(message.sourceId, 'plugin');
    expect(message.action, null);
    await master.close();
  });
  test('testDeactivatePlugin', () async {
    final master = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    final collector = MessageCollector();
    master.registerListener(MessageType.values, collector);
    await collector.awaitCount(3);
    final message = collector.messages[2];
    expect(message.type, MessageType.deregisterPlugin);
    expect(message.sourceId, 'plugin');
    expect(message.action?.protocol, GeigerUrl.geigerProtocol);
    expect(message.action?.plugin, GeigerApi.masterId);
    expect(message.action?.path, 'deregisterPlugin');
    await master.close();
  });
  test('testRegisterMenu', () async {
    final master = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    final collector = MessageCollector();
    master.registerListener(MessageType.values, collector);
    await collector.awaitCount(3);
    final message = collector.messages[2];
    expect(message.type, MessageType.registerMenu);
    expect(message.sourceId, 'plugin');
    expect(message.action?.protocol, 'geiger');
    expect(message.action?.plugin, GeigerApi.masterId);
    expect(message.action?.path, 'registerMenu');
    expect(
        await MenuItem.fromByteArrayStream(ByteStream(null, message.payload)),
        await generateTestMenu());
    await master.close();
  });
  test('testDisableMenu', () async {
    final master = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    final collector = MessageCollector();
    master.registerListener(MessageType.values, collector);
    await collector.awaitCount(4);
    final message = collector.messages[3];
    expect(message.type, MessageType.disableMenu);
    expect(message.sourceId, 'plugin');
    expect(message.action?.protocol, 'geiger');
    expect(message.action?.plugin, GeigerApi.masterId);
    expect(message.action?.path, 'disableMenu');
    expect(message.payloadString, menuId);
    await master.close();
  });
  test('testMenuPressed', () async {
    final master = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    final collector = MessageCollector();
    master.registerListener(MessageType.values, collector);
    await collector.awaitCount(3);
    master.menuPressed(master.getMenuList().first.action);
    await master.close();
  });
}
