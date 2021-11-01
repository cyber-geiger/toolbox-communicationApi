import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:communicationapi/geiger_api.dart';
import 'package:communicationapi/src/communication/communication_helper.dart';
import 'package:communicationapi/src/communication/communication_secret.dart';
import 'package:communicationapi/src/communication/geiger_communicator.dart';
import 'package:communicationapi/src/communication/geiger_url.dart';
import 'package:communicationapi/src/communication/menu_item.dart';
import 'package:communicationapi/src/communication/plugin_information.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:test/test.dart';

void main() {
  test('testRegisterPlugin', () async {
    final GeigerApi localMaster =
        getGeigerApi('', GeigerApi.MASTER, Declaration.DO_NOT_SHARE_DATA)!;
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.MASTER}/test');
    final PluginInformation payload =
        PluginInformation('./plugin1', 5555, CommunicationSecret.empty());
    final Message request = Message(GeigerApi.MASTER, GeigerApi.MASTER,
        MessageType.REGISTER_PLUGIN, testUrl, await payload.toByteArray());
    final Message reply = CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) => msg.type == MessageType.COMAPI_SUCCESS);
    expect(MessageType.COMAPI_SUCCESS, reply.type,
        reason: 'checking message type');
    expect(request.sourceId, reply.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, reply.sourceId,
        reason: 'checking sender of reply');
    expect('registerPlugin', reply.action!.path, reason: 'checking geigerURL');
  });

  test('testDeregisterPlugin', () {
    final GeigerApi localMaster =
        getGeigerApi('', GeigerApi.MASTER, Declaration.DO_NOT_SHARE_DATA)!;
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.MASTER}/test');
    final Message request = Message(GeigerApi.MASTER, GeigerApi.MASTER,
        MessageType.DEREGISTER_PLUGIN, testUrl);
    final Message reply = CommunicationHelper.sendAndWait(
        localMaster,
        request,
        (Message msg) =>
            (msg.type == MessageType.COMAPI_SUCCESS) &&
            msg.action!.path == 'deregisterPlugin');
    expect(MessageType.COMAPI_SUCCESS, reply.type,
        reason: 'checking message type');
    expect(request.sourceId, reply.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, reply.sourceId,
        reason: 'checking sender of reply');
    expect('deregisterPlugin', reply.action!.path,
        reason: 'checking geigerURL');
  });

  test('testActivatePlugin', () async {
    final GeigerApi localMaster =
        getGeigerApi('', GeigerApi.MASTER, Declaration.DO_NOT_SHARE_DATA)!;
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.MASTER}/test');
    final PluginInformation payload =
        PluginInformation('./plugin1', 5555, CommunicationSecret.empty());
    // Pregister plugin
    final Message request = Message(GeigerApi.MASTER, GeigerApi.MASTER,
        MessageType.REGISTER_PLUGIN, testUrl, await payload.toByteArray());
    CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) => msg.type == MessageType.COMAPI_SUCCESS);
    // activate plugin
    const int payloadActivate = 5555;
    final Message requestActivate = Message(
        GeigerApi.MASTER,
        GeigerApi.MASTER,
        MessageType.ACTIVATE_PLUGIN,
        testUrl,
        GeigerCommunicator.intToByteArray(payloadActivate));
    final Message replyActivate = CommunicationHelper.sendAndWait(
        localMaster,
        requestActivate,
        (Message msg) => msg.type == MessageType.COMAPI_SUCCESS);
    expect(MessageType.COMAPI_SUCCESS, replyActivate.type,
        reason: 'checking message type');
    expect(request.sourceId, replyActivate.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, replyActivate.sourceId,
        reason: 'checking sender of reply');
    expect('activatePlugin', replyActivate.action!.path,
        reason: 'checking geigerURL');
  });

  test('testDeactivatePlugin', () async {
    final GeigerApi localMaster =
        getGeigerApi('', GeigerApi.MASTER, Declaration.DO_NOT_SHARE_DATA)!;
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.MASTER}/test');
    final PluginInformation payload =
        PluginInformation('./plugin1', 5555, CommunicationSecret.empty());
    // Pregister plugin
    final Message request = Message(GeigerApi.MASTER, GeigerApi.MASTER,
        MessageType.REGISTER_PLUGIN, testUrl, await payload.toByteArray());
    CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) => msg.type == MessageType.COMAPI_SUCCESS);
    // activate plugin
    const int payloadActivate = 5555;
    final Message requestActivate = Message(
        GeigerApi.MASTER,
        GeigerApi.MASTER,
        MessageType.ACTIVATE_PLUGIN,
        testUrl,
        GeigerCommunicator.intToByteArray(payloadActivate));
    CommunicationHelper.sendAndWait(localMaster, requestActivate,
        (Message msg) => msg.type == MessageType.COMAPI_SUCCESS);
    // deactivate Plugin
    final Message requestDeactivate = Message(GeigerApi.MASTER,
        GeigerApi.MASTER, MessageType.DEACTIVATE_PLUGIN, testUrl);
    final Message replyDeactivate = CommunicationHelper.sendAndWait(
        localMaster,
        requestDeactivate,
        (Message msg) => msg.type == MessageType.COMAPI_SUCCESS);
    expect(MessageType.COMAPI_SUCCESS, replyDeactivate.type,
        reason: 'checking message type');
    expect(request.sourceId, replyDeactivate.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, replyDeactivate.sourceId,
        reason: 'checking sender of reply');
    expect('deactivatePlugin', replyDeactivate.action!.path,
        reason: 'checking geigerURL');
  });

  test('testGetStorage', () {
    // check master
    final GeigerApi localMaster =
        getGeigerApi('', GeigerApi.MASTER, Declaration.DO_NOT_SHARE_DATA)!;
    final StorageController? masterController = localMaster.getStorage();
    expect(true, masterController is GenericController);

    // check plugin
    /*final GeigerApi pluginApi =
        getGeigerApi('./plugin1', 'plugin1', Declaration.DO_NOT_SHARE_DATA)!;
    final StorageController? pluginController = pluginApi.getStorage();
    expect(true, pluginController is PasstroughController);*/
    // TODO: test with PasstroughController
  });

  test('testRegisterMenu', () async {
    final GeigerApi localMaster =
        getGeigerApi('', GeigerApi.MASTER, Declaration.DO_NOT_SHARE_DATA)!;
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.MASTER}/test');
    final GeigerUrl menuUrl = GeigerUrl.fromSpec('geiger://plugin1/Score');
    final MenuItem payload = MenuItem('plugin1Score', menuUrl);
    final Message request = Message(GeigerApi.MASTER, GeigerApi.MASTER,
        MessageType.REGISTER_MENU, testUrl, await payload.toByteArray());
    final Message reply = CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) => msg.type == MessageType.COMAPI_SUCCESS);

    expect(MessageType.COMAPI_SUCCESS, reply.type,
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
    final GeigerApi localMaster =
        getGeigerApi('', GeigerApi.MASTER, Declaration.DO_NOT_SHARE_DATA)!;
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.MASTER}/test');
    final GeigerUrl menuUrl = GeigerUrl.fromSpec('geiger://plugin1/Score');
    final MenuItem payload = MenuItem('plugin1Score', menuUrl);
    final Message request = Message(GeigerApi.MASTER, GeigerApi.MASTER,
        MessageType.REGISTER_MENU, testUrl, await payload.toByteArray());
    // register a MenuItem
    CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) => msg.type == MessageType.COMAPI_SUCCESS);

    final Message request2 = Message(GeigerApi.MASTER, GeigerApi.MASTER,
        MessageType.DEREGISTER_MENU, testUrl, utf8.encode(payload.menu));
    final Message reply2 = CommunicationHelper.sendAndWait(localMaster,
        request2, (Message msg) => msg.type == MessageType.COMAPI_SUCCESS);

    expect(MessageType.COMAPI_SUCCESS, reply2.type,
        reason: 'checking message type');
    expect(request.sourceId, reply2.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, reply2.sourceId,
        reason: 'checking sender of reply');
    expect('deregisterMenu', reply2.action!.path, reason: 'checking geigerURL');
    expect(0, localMaster.getMenuList().length);
  });

  test('testEnableMenu', () async {
    final GeigerApi localMaster =
        getGeigerApi('', GeigerApi.MASTER, Declaration.DO_NOT_SHARE_DATA)!;
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.MASTER}/test');
    final GeigerUrl menuUrl = GeigerUrl.fromSpec('geiger://plugin1/Score');
    // create a disabled menu
    final MenuItem payload = MenuItem('plugin1Score', menuUrl, false);
    final Message request = Message(GeigerApi.MASTER, GeigerApi.MASTER,
        MessageType.REGISTER_MENU, testUrl, await payload.toByteArray());
    // register a disabled menuItem
    CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) => msg.type == MessageType.COMAPI_SUCCESS);

    // enable the menuItem
    final Message request2 = Message(GeigerApi.MASTER, GeigerApi.MASTER,
        MessageType.ENABLE_MENU, testUrl, utf8.encode(payload.menu));
    final Message reply2 = CommunicationHelper.sendAndWait(localMaster,
        request2, (Message msg) => msg.type == MessageType.COMAPI_SUCCESS);

    expect(MessageType.COMAPI_SUCCESS, reply2.type,
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
    final GeigerApi localMaster =
        getGeigerApi('', GeigerApi.MASTER, Declaration.DO_NOT_SHARE_DATA)!;
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.MASTER}/test');
    final GeigerUrl menuUrl = GeigerUrl.fromSpec('geiger://plugin1/Score');
    // create an enabled menu
    final MenuItem payload = MenuItem('plugin1Score', menuUrl, true);
    final Message request = Message(GeigerApi.MASTER, GeigerApi.MASTER,
        MessageType.REGISTER_MENU, testUrl, await payload.toByteArray());
    // register a disabled menuItem
    CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) => msg.type == MessageType.COMAPI_SUCCESS);

    // enable the menuItem
    final Message request2 = Message(GeigerApi.MASTER, GeigerApi.MASTER,
        MessageType.DISABLE_MENU, testUrl, utf8.encode(payload.menu));
    final Message reply2 = CommunicationHelper.sendAndWait(localMaster,
        request2, (Message msg) => msg.type == MessageType.COMAPI_SUCCESS);

    expect(MessageType.COMAPI_SUCCESS, reply2.type,
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

  test('testPing', () {
    final GeigerApi localMaster =
        getGeigerApi('', GeigerApi.MASTER, Declaration.DO_NOT_SHARE_DATA)!;
    final GeigerUrl testUrl =
        GeigerUrl.fromSpec('geiger://${GeigerApi.MASTER}/test');
    final Message request = Message(GeigerApi.MASTER, GeigerApi.MASTER,
        MessageType.PING, testUrl, utf8.encode('payload'));
    final Message reply = CommunicationHelper.sendAndWait(
        localMaster,
        request,
        (Message msg) =>
            const ListEquality<int>().equals(msg.payload, request.payload) &&
            msg.type == MessageType.PONG);
    expect(utf8.decode(request.payload), utf8.decode(reply.payload),
        reason: 'comparing payloads');
    expect(MessageType.PONG, reply.type, reason: 'checking message type');
    expect(request.sourceId, reply.targetId,
        reason: 'checking recipient of reply');
    expect(request.targetId, reply.sourceId,
        reason: 'checking sender of reply');
  });
}
