// ignore_for_file: avoid_print

import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

import 'change_listener.dart';

class NodeListener implements StorageListener {
  final List<EventChange> events = [];
  late final StorageController storageController;

  NodeListener(this.storageController);

  @override
  Future<void> gotStorageChange(
      EventType event, Node? oldNode, Node? newNode) async {
    print("**********************************************************");
    print(oldNode);
    print(newNode);
    print(event);
    events.add(EventChange(event, oldNode, newNode));
  }
}

class EventChange {
  final EventType type;
  final Node? oldNode;
  final Node? newNode;

  EventChange(this.type, this.oldNode, this.newNode);

  @override
  String toString() {
    return 'EventChange{type: $type, oldNode: $oldNode, newNode: $newNode}';
  }
}

Future<void> algarclamTests() async {
  group('algarclam tests', () {
    test('STORAGE LISTENER - LAST NODE UPDATED', () async {
      print("LISTENER TEST - CHECKS DELETE BEHAVIOUR");
      Future<GeigerApi?> f =
          getGeigerApi("", GeigerApi.masterId, Declaration.doNotShareData);
      GeigerApi localMaster = (await f)!;
      expect(f, completes);
      StorageController storageController = localMaster.storage;
      await storageController.zap();
      SearchCriteria sc = SearchCriteria(searchPath: ':Local');
      CollectingListener stListener = CollectingListener();
      await storageController.registerChangeListener(stListener, sc);
      print("UPDATE A NODE UNDER :LOCAL");
      Node demoExample1 = NodeImpl(':Local:DemoExample', 'CloudAdapter');
      await storageController.addOrUpdate(demoExample1);
      print("UPDATE A NODE NOT UNDER :LOCAL");
      Node demoExample11 = NodeImpl(':Devices:DemoExampleTest', 'CloudAdapter');
      await storageController.addOrUpdate(demoExample11);
      stListener.awaitCount(1);
      await storageController.deregisterChangeListener(stListener);
      expect(stListener.events.length, 1,
          reason: 'unexpected number of events');
      expect(await storageController.get(':Local:DemoExample'), demoExample1,
          reason: 'difference in DemoExample');
      expect(await storageController.delete(':Local:DemoExample'), demoExample1,
          reason: 'difference in DemoExample1');
      expect(await storageController.delete(':Devices:DemoExampleTest'),
          demoExample11,
          reason: 'difference in DemoExample11');
      await localMaster.close();
    });
    test('STORAGE LISTENER - LAST NODE DELETED', () async {
      print("LISTENER TEST - CHECKS DELETE BEHAVIOUR");
      GeigerApi localMaster = (await getGeigerApi(
          "", GeigerApi.masterId, Declaration.doNotShareData))!;
      // ignore: unused_local_variable
      StorageController storageController = localMaster.storage;
      await storageController.zap();
      SearchCriteria sc = SearchCriteria(searchPath: ':');
      Node demoExample11 = NodeImpl(':Local:DemoExampleTest', 'CloudAdapter');
      await storageController.addOrUpdate(demoExample11);
      NodeListener stListener = NodeListener(storageController);
      storageController.registerChangeListener(stListener, sc);
      print("UPDATE A NODE UNDER :LOCAL");
      Node demoExample1 = NodeImpl(':Local:DemoExample', 'CloudAdapter');
      await storageController.addOrUpdate(demoExample1);
      print(stListener.events);
      print("DELETE A NODE UNDER :LOCAL");
      await storageController.delete(':Local:DemoExampleTest');
      print(stListener.events);
      await storageController.deregisterChangeListener(stListener);
      await localMaster.close();
    });
    test('STORAGE LISTENER - DELETE AND ADD A NODE', () async {
      print("LISTENER TEST - CHECKS DELETE BEHAVIOUR");
      GeigerApi localMaster = (await getGeigerApi(
          "", GeigerApi.masterId, Declaration.doNotShareData))!;
      // ignore: unused_local_variable
      StorageController storageController = localMaster.storage;
      await storageController.zap();
      SearchCriteria sc = SearchCriteria(searchPath: ':');
      Node demoExample11 = NodeImpl(':Local:DemoExampleTest', 'CloudAdapter');
      await storageController.addOrUpdate(demoExample11);
      NodeListener stListener = NodeListener(storageController);
      storageController.registerChangeListener(stListener, sc);
      print("UPDATE A NODE UNDER :LOCAL");
      Node demoExample1 = NodeImpl(':Local:DemoExample', 'CloudAdapter');
      await storageController.addOrUpdate(demoExample1);
      print(stListener.events);
      print("DELETE A NODE UNDER :LOCAL");
      await storageController.delete(':Local:DemoExampleTest');
      print(stListener.events);
      print("UPDATE A NODE UNDER :LOCAL");
      Node demoExample12 = NodeImpl(':Local:NewTest', 'CloudAdapter');
      await storageController.addOrUpdate(demoExample12);
      print(stListener.events);
      await storageController.deregisterChangeListener(stListener);
      await localMaster.close();
    });
  });
}

Future<void> isolatePluginTest1(SendPort ext) async {
  print('## Initializing expander');
  await StorageMapper.initDatabaseExpander();
  print('## Getting storage');
  GeigerApi api =
      (await getGeigerApi('', "testplugin", Declaration.doNotShareData))!;
  await api.zapState();
  StorageController geigerToolboxStorageController = api.storage;
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
    test('20220131 - Testing event propagation from external plugin to Master',
        () async {
      await StorageMapper.initDatabaseExpander();
      GeigerApi api = (await getGeigerApi(
          "", GeigerApi.masterId, Declaration.doNotShareData))!;
      StorageController geigerToolboxStorageController = api.storage;
      await geigerToolboxStorageController.zap();
      CollectingListener l = CollectingListener();
      await geigerToolboxStorageController.registerChangeListener(
          l, SearchCriteria(searchPath: ':Users:test'));
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
      await l.awaitCount(3);
      expect(l.events.length, 3);
      print("## dumping master events");
      for (ChangeEvent evt in l.events) {
        print(evt);
      }
      print('## dumping on MASTER');
      print(await geigerToolboxStorageController.dump(':Users'));
      await geigerToolboxStorageController.deregisterChangeListener(l);
      print('## deleting values');
      await geigerToolboxStorageController.delete(':Users:test:test1');
      await geigerToolboxStorageController.delete(':Users:test:test2');
      await geigerToolboxStorageController.delete(':Users:test');
      await api.close();
    });
  });
}

Future<String> isolatePluginTest2(SendPort ext) async {
  // setup tes scenario
  print('## Initializing expander');
  await StorageMapper.initDatabaseExpander();
  print('## Getting storage');
  StorageController geigerToolboxStorageController =
      (await getGeigerApi('', "testplugin", Declaration.doNotShareData))!
          .storage;

  // create huge String by exponenting and truncating
  print('## creating huge value');
  int size = 10 * 1024 * 1024 - 20000;
  String s = "abcdefghijklmnopqrstuvwxyz";
  for (; s.length < size;) {
    s = s + s;
  }
  s = s.substring(0, size);

  // write data
  print('## adding value');
  await geigerToolboxStorageController.addOrUpdate(await NodeImpl.fromPath(
      ':Users:hugetest', 'testowner',
      nodeValues: [NodeValueImpl('key', s)]));

  // fetch data
  print('## getting value');
  await geigerToolboxStorageController.get(':Users:hugetest');

  print('## done');
  Isolate.exit(ext, 'end');
}

Future<void> reuvenTests() async {
  group('reuven test', () {
    int size = 10 * 1024 * 1024 - 20000;
    test('20220222 - huge values test 1 (on master)', () async {
      await StorageMapper.initDatabaseExpander();
      GeigerApi api = (await getGeigerApi(
          "", GeigerApi.masterId, Declaration.doNotShareData))!;
      StorageController geigerToolboxStorageController = api.storage;
      print('## creating huge value on master');
      String s = "abcdefghijklmnopqrstuvwxyz";
      for (; s.length < size;) {
        s = s + s;
      }
      s = s.substring(0, size);
      int start = DateTime.now().millisecondsSinceEpoch;
      print('## adding value on master');
      try {
        await geigerToolboxStorageController.addOrUpdate(
            await NodeImpl.fromPath(':Users:hugetest2', 'testowner',
                nodeValues: [NodeValueImpl('key', s)]));
      } catch (e) {
        // Original exception is too big and
        // makes IntelliJ mark the test as passed
        print(e);
        fail("Unexpected exception");
      }
      Node n = await geigerToolboxStorageController.get(':Users:hugetest2');
      expect(
          (await n.getValue('key'))!.toSimpleString()!.length > 9 * 1024 * 1024,
          isTrue,
          reason: "stored value is too small");
      int time = DateTime.now().millisecondsSinceEpoch - start;
      print("## sucessful exxecution in $time ms");
      print('## deleting values');
      await geigerToolboxStorageController.delete(':Users:hugetest2');
      await api.close();
    });
    test('huge message serialization', () async {
      print('## creating huge');
      String s = "abcdefghijklmnopqrstuvwxyz";
      for (; s.length < size;) {
        s = s + s;
      }
      s = s.substring(0, size);
      int start = DateTime.now().millisecondsSinceEpoch;
      print('## assembling message');
      Message m =
          Message('hi', 'ha', MessageType.storageEvent, null, s.codeUnits);
      int i = DateTime.now().millisecondsSinceEpoch;
      print(
          '## assembly done in ${DateTime.now().millisecondsSinceEpoch - start} ms');
      print('## serializing message');
      ByteSink bout = ByteSink();
      m.toByteArrayStream(bout);
      print(
          '## serialization done in ${DateTime.now().millisecondsSinceEpoch - i} ms');
      i = DateTime.now().millisecondsSinceEpoch;
      print('## deserializing message');
      bout.close();
      ByteStream bin = ByteStream(null, await bout.bytes);
      Message m2 = await Message.fromByteArray(bin);
      print(
          '## deserialization done in ${DateTime.now().millisecondsSinceEpoch - i} ms');
      int time = DateTime.now().millisecondsSinceEpoch - start;
      expect(m, m2);
      print("## done in $time ms (Total)");
    });
    test('20220222 - huge values test 2 (on plugin)', () async {
      await StorageMapper.initDatabaseExpander();
      GeigerApi? api = (await getGeigerApi(
          "", GeigerApi.masterId, Declaration.doNotShareData));

      ReceivePort recv = ReceivePort();
      ReceivePort err = ReceivePort();
      recv.listen((e) {
        print('P: $e');
      });
      err.listen((e) {
        print('Exception occurred');
        print("P: $e");
        // Don't throw because error is too large
        fail('Unexpected exception');
      });
      ReceivePort ext = ReceivePort();
      Isolate i = await Isolate.spawn(isolatePluginTest2, ext.sendPort,
          onError: err.sendPort, onExit: ext.sendPort, paused: true);
      i.addOnExitListener(ext.sendPort, response: 'ended');
      i.resume(i.pauseCapability!);
      await ext.elementAt(0);

      // remove data
      print('## deleting value');
      api!.storage.delete(':Users:hugetest');

      await api.close();
    }, timeout: const Timeout(Duration(seconds: 120)));
  });
}

Future<void> cftnTests() async {
  group("cftn tests", () {
    test("initial data not found", () async {
      GeigerApi localMaster = (await getGeigerApi(
          "", GeigerApi.masterId, Declaration.doNotShareData))!;
      StorageController sc = localMaster.storage;
      expect((await sc.get(":Global:threats")).path, ':Global:threats');
    });
  });
}

Future<void> main() async {
  setUp(() => flushGeigerApiCache());
  await algarclamTests();
  await luongTests();
  await reuvenTests();
  await cftnTests();
}
