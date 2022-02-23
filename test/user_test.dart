// ignore_for_file: avoid_print

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

Future<void> isolatePluginTest1(SendPort ext) async {
  print('## Initializing expander');
  await StorageMapper.initDatabaseExpander();
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
  await geigerToolboxStorageController.get(':Users:test');
  await geigerToolboxStorageController
      .addOrUpdate(NodeImpl(':Users:test:test1', 'testowner'));
  await geigerToolboxStorageController
      .addOrUpdate(NodeImpl(':Users:test:test2', 'testowner'));
  await geigerToolboxStorageController.get(':Users:test:test1');
  print('## dumping on plugin');
  print(await geigerToolboxStorageController.dump(':Users'));
  print('## done');
  Isolate.exit(ext, 'end');
}

Future<void> luongTests() async {
  group('luong test', () {
    test('20220131 - Dump problem using sub-branches in external plugins',
        () async {
      await StorageMapper.initDatabaseExpander();
      StorageController geigerToolboxStorageController =
          (await getGeigerApi("", GeigerApi.masterId))!.getStorage()!;
      toolbox_api.StorageListener l =
          NodeListener(geigerToolboxStorageController);
      await geigerToolboxStorageController.registerChangeListener(
          l, toolbox_api.SearchCriteria(searchPath: 'Users:test'));
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
      Isolate i = await Isolate.spawn(isolatePluginTest1, ext.sendPort,
          onError: err.sendPort, onExit: ext.sendPort, paused: true);
      i.addOnExitListener(ext.sendPort, response: 'ended');
      i.resume(i.pauseCapability!);
      await ext.elementAt(0);
      print('## dumping on MASTER');
      print(await geigerToolboxStorageController!.dump(':Users'));
      await geigerToolboxStorageController.deregisterChangeListener(l);
      print('## deleting values');
      await geigerToolboxStorageController.delete(':Users:test:test1');
      await geigerToolboxStorageController.delete(':Users:test:test2');
      await geigerToolboxStorageController.delete(':Users:test');
    });
    // test('',() {
    //   GeigerApi? masterPlugin;
    //   GeigerApi? externalPlugin;
    //   StorageController? geigerStorage;
    //
    //   await initMasterPlugin();
    //   await initExternalPlugin();
    //
    //   initExternalPlugin() async {
    //     log('Going to initialize External Plugin');
    //     try {
    //       externalPlugin =
    //       await getGeigerApi('', 'external-plugin-id', Declaration.doShareData);
    //       if (externalPlugin != null) {
    //         log('External Plugin: ${externalPlugin.hashCode}');
    //         try {
    //           geigerStorage = externalPlugin!.getStorage();
    //           if (geigerStorage != null) {
    //             log('External -> geigerStorage: ${geigerStorage.hashCode}');
    //             try {
    //               Node local = await geigerStorage!.get(':Local');
    //               if (local != null) {
    //                 log('External -> geigerStorage -> local: ${local.hashCode}');
    //                 var temp = await local.getValue('currentUser');
    //                 String? userId = temp?.getValue('en');
    //                 log('Current user Id: $userId');
    //               }
    //             } catch (e3) {
    //               log('Failed to get current user');
    //               log(e3.toString());
    //             }
    //           }
    //         } catch (e2) {
    //           log('Failed to get local storage');
    //           log(e2.toString());
    //         }
    //       }
    //     } catch (e) {
    //       log('Failed to init external plugin');
    //       log(e.toString());
    //     }
    //   }
    //
    //   initMasterPlugin() async {
    //     log('Going to initialize Master Plugin');
    //     try {
    //       flushGeigerApiCache();
    //       masterPlugin =
    //       await getGeigerApi('', GeigerApi.masterId, Declaration.doShareData);
    //       masterPlugin!.zapState();
    //       log('Master Plugin: ${masterPlugin.hashCode}');
    //     } catch (e) {
    //       log('Failed to init master plugin');
    //       log(e.toString());
    //     }
    //   }
    // });
  });
}

Future<void> main() async {
  await algarclamTests();
  await luongTests();
}
