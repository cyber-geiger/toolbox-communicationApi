import 'dart:convert';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_api/src/communication/communication_helper.dart';
import 'package:geiger_api/src/communication/geiger_communicator.dart';
import 'package:geiger_api/src/plugin/communication_secret.dart';
import 'package:geiger_api/src/storage/passthrough_controller.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:test/test.dart';

import 'print_logger.dart';

void main() {
  printLogger();

  test('testRegisterPlugin', () async {
    flushGeigerApiCache();
    final GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    await localMaster.zapState();
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.masterId}/test');
    final PluginInformation payload = PluginInformation(
        GeigerApi.masterId,
        GeigerApi.masterExecutor,
        GeigerCommunicator.masterPort,
        Declaration.doNotShareData,
        CommunicationSecret.random());
    final Message request = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.registerPlugin, testUrl, await payload.toByteArray());
    final Message reply =
        await CommunicationHelper.sendAndWait(localMaster, request);
    expect(MessageType.comapiSuccess, reply.type,
        reason: 'checking message type');
    expect(request.sourceId, reply.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, reply.sourceId,
        reason: 'checking sender of reply');
    expect('registerPlugin', reply.action!.path, reason: 'checking geigerURL');
    await localMaster.close();
  });

  test('testDeregisterPlugin', () async {
    flushGeigerApiCache();
    final GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    await localMaster.zapState();
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.masterId}/test');
    final Message request = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.deregisterPlugin, testUrl);
    final Message reply =
        await CommunicationHelper.sendAndWait(localMaster, request);
    expect(MessageType.comapiSuccess, reply.type,
        reason: 'checking message type');
    expect(request.sourceId, reply.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, reply.sourceId,
        reason: 'checking sender of reply');
    expect('deregisterPlugin', reply.action!.path,
        reason: 'checking geigerURL');
    await localMaster.close();
  });

  test('testActivatePlugin', () async {
    flushGeigerApiCache();
    final GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    await localMaster.zapState();
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.masterId}/test');
    // Pregister plugin
    await localMaster.registerPlugin();
    // activate plugin
    final Message request = Message(
        GeigerApi.masterId,
        GeigerApi.masterId,
        MessageType.activatePlugin,
        testUrl,
        SerializerHelper.intToByteArray(GeigerCommunicator.masterPort));
    final Message reply =
        await CommunicationHelper.sendAndWait(localMaster, request);
    expect(MessageType.comapiSuccess, reply.type,
        reason: 'checking message type');
    expect(request.sourceId, reply.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, reply.sourceId,
        reason: 'checking sender of reply');
    expect('activatePlugin', reply.action!.path, reason: 'checking geigerURL');
    await localMaster.close();
  });

  test('testDeactivatePlugin', () async {
    flushGeigerApiCache();
    final GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    await localMaster.zapState();
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.masterId}/test');
    // Pregister plugin
    await localMaster.registerPlugin();
    await localMaster.activatePlugin();
    // deactivate Plugin
    final Message request = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.deactivatePlugin, testUrl);
    final Message reply =
        await CommunicationHelper.sendAndWait(localMaster, request);
    expect(MessageType.comapiSuccess, reply.type,
        reason: 'checking message type');
    expect(request.sourceId, reply.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, reply.sourceId,
        reason: 'checking sender of reply');
    expect('deactivatePlugin', reply.action!.path,
        reason: 'checking geigerURL');
    await localMaster.close();
  });

  test('testGetStorage', () async {
    flushGeigerApiCache();
    // check master
    final GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    await localMaster.zapState();
    final StorageController masterController = localMaster.storage;
    expect(true, masterController is GenericController);

    // check plugin
    final GeigerApi? pluginApi =
        await getGeigerApi('./plugin1', 'plugin1', Declaration.doNotShareData);
    await pluginApi?.registerPlugin();
    await pluginApi?.activatePlugin();
    final StorageController pluginController = pluginApi!.storage;
    expect(pluginController is PassthroughController, isTrue,
        reason: 'Expected controller is not wrapped');
    await localMaster.close();
    await pluginApi.close();
  });

  test('testRegisterMenu', () async {
    flushGeigerApiCache();
    final GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    await localMaster.zapState();
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.masterId}/test');
    final GeigerUrl menuUrl = GeigerUrl.fromSpec('geiger://plugin1/Score');
    final MenuItem payload = MenuItem(
        await NodeImpl.fromPath(':menu:1111-1111-111111-111111:test', 'pid',
            nodeValues: [NodeValueImpl('name', 'testentry')]),
        menuUrl);
    final Message request = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.registerMenu, testUrl, await payload.toByteArray());
    final Message reply =
        await CommunicationHelper.sendAndWait(localMaster, request);

    expect(MessageType.comapiSuccess, reply.type,
        reason: 'checking message type');
    expect(request.sourceId, reply.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, reply.sourceId,
        reason: 'checking sender of reply');
    expect('registerMenu', reply.action!.path, reason: 'checking geigerURL');
    expect(1, localMaster.getMenuList().length);

    expect(payload, localMaster.getMenuList()[0],
        reason: 'checking stored menuItem');
    await localMaster.close();
  });

  test('testDeregisterMenu', () async {
    flushGeigerApiCache();
    final GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    await localMaster.zapState();
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.masterId}/test');
    final GeigerUrl menuUrl = GeigerUrl.fromSpec('geiger://plugin1/Score');
    final MenuItem payload = MenuItem(
        await NodeImpl.fromPath(':menu:1111-1111-111111-111112:test', 'pid',
            nodeValues: [NodeValueImpl('name', 'Plugin1Score')]),
        menuUrl);
    final Message request = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.registerMenu, testUrl, await payload.toByteArray());
    // register a MenuItem
    await CommunicationHelper.sendAndWait(localMaster, request);

    final Message request2 = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.deregisterMenu, testUrl, utf8.encode(payload.menu.path));
    final Message reply2 =
        await CommunicationHelper.sendAndWait(localMaster, request2);

    expect(MessageType.comapiSuccess, reply2.type,
        reason: 'checking message type');
    expect(request.sourceId, reply2.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, reply2.sourceId,
        reason: 'checking sender of reply');
    expect('deregisterMenu', reply2.action!.path, reason: 'checking geigerURL');
    expect(0, localMaster.getMenuList().length);
    await localMaster.close();
  });

  test('testEnableMenu', () async {
    flushGeigerApiCache();
    final GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    await localMaster.zapState();
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.masterId}/test');
    final GeigerUrl menuUrl = GeigerUrl.fromSpec('geiger://plugin1/Score');
    // create a disabled menu
    final MenuItem payload = MenuItem(
        await NodeImpl.fromPath(':menu:1111-1111-111111-111113:test', 'pid',
            nodeValues: [NodeValueImpl('name', 'Plugin2Score')]),
        menuUrl,
        false);
    final Message request = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.registerMenu, testUrl, await payload.toByteArray());
    // register a disabled menuItem
    await CommunicationHelper.sendAndWait(localMaster, request);

    // enable the menuItem
    final Message request2 = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.enableMenu, testUrl, utf8.encode(payload.menu.path));
    final Message reply2 =
        await CommunicationHelper.sendAndWait(localMaster, request2);

    expect(MessageType.comapiSuccess, reply2.type,
        reason: 'checking message type');
    expect(request.sourceId, reply2.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, reply2.sourceId,
        reason: 'checking sender of reply');
    expect('enableMenu', reply2.action!.path, reason: 'checking geigerURL');
    expect(1, localMaster.getMenuList().length);

    payload.enabled = true;
    expect(payload, isNot(equals(localMaster.getMenuList()[0])),
        reason: 'checking stored menuItem');
    await localMaster.close();
  });

  test('testDisableMenu', () async {
    flushGeigerApiCache();
    final GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    await localMaster.zapState();
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.masterId}/test');
    final GeigerUrl menuUrl = GeigerUrl.fromSpec('geiger://plugin1/Score');
    // create an enabled menu
    final MenuItem payload = MenuItem(
        await NodeImpl.fromPath(':menu:1111-1111-111111-111113:test', 'pid',
            nodeValues: [NodeValueImpl('name', 'Plugin3Score')]),
        menuUrl,
        true);
    final Message request = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.registerMenu, testUrl, await payload.toByteArray());
    // register a disabled menuItem
    await CommunicationHelper.sendAndWait(localMaster, request);

    // enable the menuItem
    final Message request2 = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.disableMenu, testUrl, utf8.encode(payload.menu.path));
    final Message reply2 =
        await CommunicationHelper.sendAndWait(localMaster, request2);

    expect(MessageType.comapiSuccess, reply2.type,
        reason: 'checking message type');
    expect(request.sourceId, reply2.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, reply2.sourceId,
        reason: 'checking sender of reply');
    expect('disableMenu', reply2.action!.path, reason: 'checking geigerURL');
    expect(1, localMaster.getMenuList().length);

    payload.enabled = false;
    expect(payload, isNot(equals(localMaster.getMenuList()[0])),
        reason: 'checking stored menuItem');
    await localMaster.close();
  });

  test('testPing', () async {
    flushGeigerApiCache();
    final GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    await localMaster.zapState();
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.masterId}/test');
    final Message request = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.ping, testUrl, utf8.encode('payload'));
    final Message reply = await CommunicationHelper.sendAndWait(
        localMaster, request,
        responseTypes: [MessageType.pong]);
    expect(utf8.decode(request.payload), utf8.decode(reply.payload),
        reason: 'comparing payloads');
    expect(MessageType.pong, reply.type, reason: 'checking message type');
    expect(request.sourceId, reply.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, reply.sourceId,
        reason: 'checking sender of reply');
    await localMaster.close();
  });
}
