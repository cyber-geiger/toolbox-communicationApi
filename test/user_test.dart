// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart' as toolbox_api;

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

Future<void> main() async {
  await algarclamTests();
}
