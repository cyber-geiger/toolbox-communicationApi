import 'dart:convert';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_api/src/communication/communication_helper.dart';
import 'package:geiger_api/src/message/secured_message.dart';
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
    final PluginInformation payload = PluginInformation('plugin1', './plugin1',
        5555, Declaration.doNotShareData, CommunicationSecret.empty());
    final Message request = SecuredMessage(GeigerApi.masterId, GeigerApi.masterId,
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
    final Message request = SecuredMessage(GeigerApi.masterId, GeigerApi.masterId,
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
    final PluginInformation payload = PluginInformation('plugin1', './plugin1',
        5555, Declaration.doNotShareData, CommunicationSecret.empty());
    // Pregister plugin
    final Message request = SecuredMessage(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.registerPlugin, testUrl, await payload.toByteArray());
    await CommunicationHelper.sendAndWait(localMaster, request);
    // activate plugin
    const int payloadActivate = 255; //ToDo correct 8bit bytevalue before 5555
    final Message requestActivate = SecuredMessage(
        GeigerApi.masterId,
        GeigerApi.masterId,
        MessageType.activatePlugin,
        testUrl,
        SerializerHelper.intToByteArray(payloadActivate));
    final Message replyActivate =
        await CommunicationHelper.sendAndWait(localMaster, requestActivate);
    expect(MessageType.comapiSuccess, replyActivate.type,
        reason: 'checking message type');
    expect(request.sourceId, replyActivate.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, replyActivate.sourceId,
        reason: 'checking sender of reply');
    expect('activatePlugin', replyActivate.action!.path,
        reason: 'checking geigerURL');
    await localMaster.close();
  });

  test('testDeactivatePlugin', () async {
    flushGeigerApiCache();
    final GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    await localMaster.zapState();
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.masterId}/test');
    final PluginInformation payload = PluginInformation('plugin1', './plugin1',
        5555, Declaration.doNotShareData, CommunicationSecret.empty());
    // Pregister plugin
    final Message request = SecuredMessage(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.registerPlugin, testUrl, await payload.toByteArray());
    await CommunicationHelper.sendAndWait(localMaster, request);
    // activate plugin
    const int payloadActivate = 255; //ToDo: Correct 8bit bytevalue, before 5555
    final Message requestActivate = SecuredMessage(
        GeigerApi.masterId,
        GeigerApi.masterId,
        MessageType.activatePlugin,
        testUrl,
        SerializerHelper.intToByteArray(payloadActivate));
    await CommunicationHelper.sendAndWait(localMaster, requestActivate);
    // deactivate Plugin
    final Message requestDeactivate = SecuredMessage(GeigerApi.masterId,
        GeigerApi.masterId, MessageType.deactivatePlugin, testUrl);
    final Message replyDeactivate =
        await CommunicationHelper.sendAndWait(localMaster, requestDeactivate);
    expect(MessageType.comapiSuccess, replyDeactivate.type,
        reason: 'checking message type');
    expect(request.sourceId, replyDeactivate.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, replyDeactivate.sourceId,
        reason: 'checking sender of reply');
    expect('deactivatePlugin', replyDeactivate.action!.path,
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
    final Message request = SecuredMessage(GeigerApi.masterId, GeigerApi.masterId,
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
    final Message request = SecuredMessage(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.registerMenu, testUrl, await payload.toByteArray());
    // register a MenuItem
    await CommunicationHelper.sendAndWait(localMaster, request);

    final Message request2 = SecuredMessage(GeigerApi.masterId, GeigerApi.masterId,
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
    final Message request = SecuredMessage(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.registerMenu, testUrl, await payload.toByteArray());
    // register a disabled menuItem
    await CommunicationHelper.sendAndWait(localMaster, request);

    // enable the menuItem
    final Message request2 = SecuredMessage(GeigerApi.masterId, GeigerApi.masterId,
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
    final Message request = SecuredMessage(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.registerMenu, testUrl, await payload.toByteArray());
    // register a disabled menuItem
    await CommunicationHelper.sendAndWait(localMaster, request);

    // enable the menuItem
    final Message request2 = SecuredMessage(GeigerApi.masterId, GeigerApi.masterId,
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
    final Message request = SecuredMessage(GeigerApi.masterId, GeigerApi.masterId,
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
