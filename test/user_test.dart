// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart' as toolbox_api;
import 'package:geiger_localstorage/geiger_localstorage.dart';

class NodeListener implements toolbox_api.StorageListener {
  final List<EventChange> events = [];
  late final toolbox_api.StorageController storageController;

  NodeListener(this.storageController);

  @override
  Future<void> gotStorageChange(toolbox_api.EventType event,
      toolbox_api.Node? oldNode, toolbox_api.Node? newNode) async {
    print("**********************************************************");
    print(oldNode);
    print(newNode);
    print(event);
    events.add(EventChange(event, oldNode, newNode));
  }
}

class EventChange {
  final toolbox_api.EventType type;
  final toolbox_api.Node? oldNode;
  final toolbox_api.Node? newNode;

  EventChange(this.type, this.oldNode, this.newNode);

  @override
  String toString() {
    return 'EventChange{type: $type, oldNode: $oldNode, newNode: $newNode}';
  }
}

Future<void> algarclamTests() async {
  test('STORAGE LISTENER - LAST NODE UPDATED', () async {
    print("LISTENER TEST - CHECKS DELETE BEHAVIOUR");
    GeigerApi localMaster =
        (await getGeigerApi("", GeigerApi.masterId, Declaration.doShareData))!;
    // ignore: unused_local_variable
    toolbox_api.StorageController storageController = localMaster.getStorage()!;
    toolbox_api.SearchCriteria sc = toolbox_api.SearchCriteria(searchPath: ':');
    NodeListener stListener = NodeListener(storageController);
    storageController.registerChangeListener(stListener, sc);
    print("UPDATE A NODE UNDER :LOCAL");
    toolbox_api.Node demoExample1 =
        toolbox_api.NodeImpl(':Local:DemoExample', 'CloudAdapter');
    await storageController.addOrUpdate(demoExample1);
    print(stListener.events);
    print("UPDATE A NODE NOT UNDER :LOCAL");
    toolbox_api.Node demoExample11 =
        toolbox_api.NodeImpl(':Devices:DemoExampleTest', 'CloudAdapter');
    await storageController.addOrUpdate(demoExample11);
    print(stListener.events);
    await storageController.deregisterChangeListener(stListener);
  });
  test('STORAGE LISTENER - LAST NODE DELETED', () async {
    print("LISTENER TEST - CHECKS DELETE BEHAVIOUR");
    GeigerApi localMaster =
        (await getGeigerApi("", GeigerApi.masterId, Declaration.doShareData))!;
    // ignore: unused_local_variable
    toolbox_api.StorageController storageController = localMaster.getStorage()!;
    toolbox_api.SearchCriteria sc = toolbox_api.SearchCriteria(searchPath: ':');
    toolbox_api.Node demoExample11 =
        toolbox_api.NodeImpl(':Local:DemoExampleTest', 'CloudAdapter');
    await storageController.addOrUpdate(demoExample11);
    NodeListener stListener = NodeListener(storageController);
    storageController.registerChangeListener(stListener, sc);
    print("UPDATE A NODE UNDER :LOCAL");
    toolbox_api.Node demoExample1 =
        toolbox_api.NodeImpl(':Local:DemoExample', 'CloudAdapter');
    await storageController.addOrUpdate(demoExample1);
    print(stListener.events);
    print("DELETE A NODE UNDER :LOCAL");
    await storageController.delete(':Local:DemoExampleTest');
    print(stListener.events);
    await storageController.deregisterChangeListener(stListener);
  });
  test('STORAGE LISTENER - DELETE AND ADD A NODE', () async {
    print("LISTENER TEST - CHECKS DELETE BEHAVIOUR");
    GeigerApi localMaster =
        (await getGeigerApi("", GeigerApi.masterId, Declaration.doShareData))!;
    // ignore: unused_local_variable
    toolbox_api.StorageController storageController = localMaster.getStorage()!;
    toolbox_api.SearchCriteria sc = toolbox_api.SearchCriteria(searchPath: ':');
    toolbox_api.Node demoExample11 =
        toolbox_api.NodeImpl(':Local:DemoExampleTest', 'CloudAdapter');
    await storageController.addOrUpdate(demoExample11);
    NodeListener stListener = NodeListener(storageController);
    storageController.registerChangeListener(stListener, sc);
    print("UPDATE A NODE UNDER :LOCAL");
    toolbox_api.Node demoExample1 =
        toolbox_api.NodeImpl(':Local:DemoExample', 'CloudAdapter');
    await storageController.addOrUpdate(demoExample1);
    print(stListener.events);
    print("DELETE A NODE UNDER :LOCAL");
    await storageController.delete(':Local:DemoExampleTest');
    print(stListener.events);
    print("UPDATE A NODE UNDER :LOCAL");
    toolbox_api.Node demoExample12 =
        toolbox_api.NodeImpl(':Local:NewTest', 'CloudAdapter');
    await storageController.addOrUpdate(demoExample12);
    print(stListener.events);
    await storageController.deregisterChangeListener(stListener);
  });
}

void isolatePluginTest1(SendPort snd) async {
  print('## Initializing expander');
  //await StorageMapper.initDatabaseExpander();
  print('## Getting storage');
  StorageController? geigerToolboxStorageController =
      (await getGeigerApi('', "testplugin", Declaration.doNotShareData))!
          .getStorage();
  if (geigerToolboxStorageController == null) {
    throw toolbox_api.StorageException('got null storage');
  }
  print('## adding value');
  await geigerToolboxStorageController
      .addOrUpdate(NodeImpl(':Users:test', 'testowner'));
  expect(await geigerToolboxStorageController.get(':Users:Test'), isNotNull,
      reason: 'User node not found');
  print('## deleting value');
  await geigerToolboxStorageController.delete(':Users:test');
  print('## dumping on plugin');
  print(await geigerToolboxStorageController.dump(':Users'));
  print('## done');
  sleep(const Duration(seconds: 1));
}

Future<void> luongTests() async {
  group('luong test', () {
    test('20220131 - Dump problem using sub-branches in external plugins',
        () async {
      await StorageMapper.initDatabaseExpander();
      StorageController? geigerToolboxStorageController =
          (await getGeigerApi("", GeigerApi.masterId))!.getStorage();
      ReceivePort recv = ReceivePort();
      ReceivePort err = ReceivePort();
      recv.listen((e) {
        print('P: $e');
      });
      err.listen((e) {
        print('Exception occurred');
        print("P: $e");
        throw e;
      });
      ReceivePort ext = ReceivePort();
      await Isolate.spawn(isolatePluginTest1, recv.sendPort,
          onError: err.sendPort, onExit: ext.sendPort);
      await ext.last;
      print('## dumping on MASTER');
      print(await geigerToolboxStorageController!.dump(':Users'));
    });
  });
}

Future<void> main() async {
  await algarclamTests();
  await luongTests();
}
