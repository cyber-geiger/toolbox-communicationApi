import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_api/src/communication/communication_helper.dart';
import 'package:geiger_api/src/communication/communication_secret.dart';
import 'package:geiger_api/src/communication/geiger_url.dart';
import 'package:geiger_api/src/communication/menu_item.dart';
import 'package:geiger_api/src/communication/plugin_information.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:test/test.dart';

void main() {
  test('testRegisterPlugin', () async {
    final GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.masterId}/test');
    final PluginInformation payload =
        PluginInformation('./plugin1', 5555, CommunicationSecret.empty());
    final Message request = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.registerPlugin, testUrl, await payload.toByteArray());
    final Message reply = await CommunicationHelper.sendAndWait(localMaster,
        request, (Message msg) => msg.type == MessageType.comapiSuccess);
    expect(MessageType.comapiSuccess, reply.type,
        reason: 'checking message type');
    expect(request.sourceId, reply.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, reply.sourceId,
        reason: 'checking sender of reply');
    expect('registerPlugin', reply.action!.path, reason: 'checking geigerURL');
  });

  test('testDeregisterPlugin', () async {
    final GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.masterId}/test');
    final Message request = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.deregisterPlugin, testUrl);
    final Message reply = await CommunicationHelper.sendAndWait(
        localMaster,
        request,
        (Message msg) =>
            (msg.type == MessageType.comapiSuccess) &&
            msg.action!.path == 'deregisterPlugin');
    expect(MessageType.comapiSuccess, reply.type,
        reason: 'checking message type');
    expect(request.sourceId, reply.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, reply.sourceId,
        reason: 'checking sender of reply');
    expect('deregisterPlugin', reply.action!.path,
        reason: 'checking geigerURL');
  });

  test('testActivatePlugin', () async {
    final GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.masterId}/test');
    final PluginInformation payload =
        PluginInformation('./plugin1', 5555, CommunicationSecret.empty());
    // Pregister plugin
    final Message request = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.registerPlugin, testUrl, await payload.toByteArray());
    await CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) => msg.type == MessageType.comapiSuccess);
    // activate plugin
    const int payloadActivate = 255; //ToDo correct 8bit bytevalue before 5555
    final Message requestActivate = Message(
        GeigerApi.masterId,
        GeigerApi.masterId,
        MessageType.activatePlugin,
        testUrl,
        SerializerHelper.intToByteArray(payloadActivate));
    final Message replyActivate = await CommunicationHelper.sendAndWait(
        localMaster,
        requestActivate,
        (Message msg) => msg.type == MessageType.comapiSuccess);
    expect(MessageType.comapiSuccess, replyActivate.type,
        reason: 'checking message type');
    expect(request.sourceId, replyActivate.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, replyActivate.sourceId,
        reason: 'checking sender of reply');
    expect('activatePlugin', replyActivate.action!.path,
        reason: 'checking geigerURL');
  });

  test('testDeactivatePlugin', () async {
    final GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.masterId}/test');
    final PluginInformation payload =
        PluginInformation('./plugin1', 5555, CommunicationSecret.empty());
    // Pregister plugin
    final Message request = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.registerPlugin, testUrl, await payload.toByteArray());
    await CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) => msg.type == MessageType.comapiSuccess);
    // activate plugin
    const int payloadActivate = 255; //ToDo: Correct 8bit bytevalue, before 5555
    final Message requestActivate = Message(
        GeigerApi.masterId,
        GeigerApi.masterId,
        MessageType.activatePlugin,
        testUrl,
        SerializerHelper.intToByteArray(payloadActivate));
    await CommunicationHelper.sendAndWait(localMaster, requestActivate,
        (Message msg) => msg.type == MessageType.comapiSuccess);
    // deactivate Plugin
    final Message requestDeactivate = Message(GeigerApi.masterId,
        GeigerApi.masterId, MessageType.deactivatePlugin, testUrl);
    final Message replyDeactivate = await CommunicationHelper.sendAndWait(
        localMaster,
        requestDeactivate,
        (Message msg) => msg.type == MessageType.comapiSuccess);
    expect(MessageType.comapiSuccess, replyDeactivate.type,
        reason: 'checking message type');
    expect(request.sourceId, replyDeactivate.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, replyDeactivate.sourceId,
        reason: 'checking sender of reply');
    expect('deactivatePlugin', replyDeactivate.action!.path,
        reason: 'checking geigerURL');
  });

  test('testGetStorage', () async {
    // check master
    final GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    final StorageController? masterController = localMaster.getStorage();
    expect(true, masterController is GenericController);

    // check plugin
    final GeigerApi? pluginApi =
        await getGeigerApi('./plugin1', 'plugin1', Declaration.doNotShareData);
    final StorageController? pluginController = pluginApi!.getStorage();
    expect(true, pluginController is StorageController);
    // TODO(mgwerder): test with PasstroughController
  });

  test('testRegisterMenu', () async {
    final GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.masterId}/test');
    final GeigerUrl menuUrl = GeigerUrl.fromSpec('geiger://plugin1/Score');
    final MenuItem payload = MenuItem('plugin1Score', menuUrl);
    final Message request = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.registerMenu, testUrl, await payload.toByteArray());
    final Message reply = await CommunicationHelper.sendAndWait(localMaster,
        request, (Message msg) => msg.type == MessageType.comapiSuccess);

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
  });

  test('testDeregisterMenu', () async {
    final GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.masterId}/test');
    final GeigerUrl menuUrl = GeigerUrl.fromSpec('geiger://plugin1/Score');
    final MenuItem payload = MenuItem('plugin1Score', menuUrl);
    final Message request = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.registerMenu, testUrl, await payload.toByteArray());
    // register a MenuItem
    await CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) => msg.type == MessageType.comapiSuccess);

    final Message request2 = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.deregisterMenu, testUrl, utf8.encode(payload.menu));
    final Message reply2 = await CommunicationHelper.sendAndWait(localMaster,
        request2, (Message msg) => msg.type == MessageType.comapiSuccess);

    expect(MessageType.comapiSuccess, reply2.type,
        reason: 'checking message type');
    expect(request.sourceId, reply2.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, reply2.sourceId,
        reason: 'checking sender of reply');
    expect('deregisterMenu', reply2.action!.path, reason: 'checking geigerURL');
    expect(0, localMaster.getMenuList().length);
  });

  test('testEnableMenu', () async {
    final GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.masterId}/test');
    final GeigerUrl menuUrl = GeigerUrl.fromSpec('geiger://plugin1/Score');
    // create a disabled menu
    final MenuItem payload = MenuItem('plugin1Score', menuUrl, false);
    final Message request = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.registerMenu, testUrl, await payload.toByteArray());
    // register a disabled menuItem
    await CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) => msg.type == MessageType.comapiSuccess);

    // enable the menuItem
    final Message request2 = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.enableMenu, testUrl, utf8.encode(payload.menu));
    final Message reply2 = await CommunicationHelper.sendAndWait(localMaster,
        request2, (Message msg) => msg.type == MessageType.comapiSuccess);

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
  });

  test('testDisableMenu', () async {
    final GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.masterId}/test');
    final GeigerUrl menuUrl = GeigerUrl.fromSpec('geiger://plugin1/Score');
    // create an enabled menu
    final MenuItem payload = MenuItem('plugin1Score', menuUrl, true);
    final Message request = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.registerMenu, testUrl, await payload.toByteArray());
    // register a disabled menuItem
    await CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) => msg.type == MessageType.comapiSuccess);

    // enable the menuItem
    final Message request2 = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.disableMenu, testUrl, utf8.encode(payload.menu));
    final Message reply2 = await CommunicationHelper.sendAndWait(localMaster,
        request2, (Message msg) => msg.type == MessageType.comapiSuccess);

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
  });

  test('testPing', () async {
    final GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.masterId}/test');
    final Message request = Message(GeigerApi.masterId, GeigerApi.masterId,
        MessageType.ping, testUrl, utf8.encode('payload'));
    final Message reply = await CommunicationHelper.sendAndWait(
        localMaster,
        request,
        (Message msg) =>
            const ListEquality<int>().equals(msg.payload, request.payload) &&
            msg.type == MessageType.pong);
    expect(utf8.decode(request.payload), utf8.decode(reply.payload),
        reason: 'comparing payloads');
    expect(MessageType.pong, reply.type, reason: 'checking message type');
    expect(request.sourceId, reply.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, reply.sourceId,
        reason: 'checking sender of reply');
  });
}
