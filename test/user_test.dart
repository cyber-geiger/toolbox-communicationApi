// ignore_for_file: avoid_print

import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

import 'change_listener.dart';
import 'print_logger.dart';

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
    test('storage listener - last node updated', () async {
      print("testing delete behaviour in listener");
      Future<GeigerApi?> f =
          getGeigerApi("", GeigerApi.masterId, Declaration.doNotShareData);
      GeigerApi localMaster = (await f)!;
      expect(f, completes);
      StorageController storageController = localMaster.storage;
      await storageController.zap();
      SearchCriteria sc = SearchCriteria(searchPath: ':Local');
      CollectingListener stListener = CollectingListener();
      await storageController.registerChangeListener(stListener, sc);
      print("updating node in :Local");
      Node demoExample1 = NodeImpl(':Local:DemoExample', 'CloudAdapter');
      await storageController.addOrUpdate(demoExample1);
      print("updating node outside :Local");
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
    test('storage node - last node deleted', () async {
      print("check listener when deleting");
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
      print("update a node under :LOCAL");
      Node demoExample1 = NodeImpl(':Local:DemoExample', 'CloudAdapter');
      await storageController.addOrUpdate(demoExample1);
      print(stListener.events);
      print("delete node under :Local");
      await storageController.delete(':Local:DemoExampleTest');
      print(stListener.events);
      await storageController.deregisterChangeListener(stListener);
      await localMaster.close();
    });
    test('storage listener - delete and add a node', () async {
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
  StorageController geigerToolboxStorageController = api.storage;

  print('## dumping on plugin');
  print(await geigerToolboxStorageController.dump(':Users'));

  CollectingListener l = CollectingListener();
  await geigerToolboxStorageController.registerChangeListener(
      l, SearchCriteria(searchPath: ':Users:test'));

  await l.awaitCount(2, const Duration(seconds: 10));

  print('## done');
  Isolate.exit(ext, 'end');
}

Future<void> isolatePluginTest1a(SendPort ext) async {
  print('## Initializing expander');
  await StorageMapper.initDatabaseExpander();

  print('## Getting storage');
  GeigerApi api =
      (await getGeigerApi('', "testplugin", Declaration.doNotShareData))!;
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
      Isolate i = await Isolate.spawn(isolatePluginTest1a, ext.sendPort,
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
    // test(
    //     '20220131 - Testing event propagation from external plugin to other plugin',
    //     () async {
    //   // init
    //   await StorageMapper.initDatabaseExpander();
    //
    //   // get master storage
    //   GeigerApi api = (await getGeigerApi(
    //       "", GeigerApi.masterId, Declaration.doNotShareData))!;
    //   StorageController geigerToolboxStorageController = api.storage;
    //   await geigerToolboxStorageController.zap();
    //
    //   // setup master listener
    //   CollectingListener l = CollectingListener();
    //   await geigerToolboxStorageController.registerChangeListener(
    //       l, SearchCriteria(searchPath: ':Users:test'));
    //
    //   // setup isolate for plugin 1
    //   ReceivePort recv = ReceivePort();
    //   ReceivePort err = ReceivePort();
    //   recv.listen((e) {
    //     print('P: $e');
    //   });
    //   err.listen((e) {
    //     print('Exception occurred');
    //     print("P: $e");
    //     throw e;
    //   });
    //   ReceivePort ext = ReceivePort();
    //   Isolate i = await Isolate.spawn(isolatePluginTest1, ext.sendPort,
    //       onError: err.sendPort, onExit: ext.sendPort, paused: true);
    //   i.addOnExitListener(ext.sendPort, response: 'ended');
    //   i.resume(i.pauseCapability!);
    //
    //   // setup isolate for plugin 2
    //   ReceivePort recv2 = ReceivePort();
    //   ReceivePort err2 = ReceivePort();
    //   recv2.listen((e) {
    //     print('P: $e');
    //   });
    //   err2.listen((e) {
    //     print('Exception occurred');
    //     print("P: $e");
    //     throw e;
    //   });
    //   ReceivePort ext2 = ReceivePort();
    //   Isolate i2 = await Isolate.spawn(isolatePluginTest1a, ext2.sendPort,
    //       onError: err2.sendPort, onExit: ext2.sendPort, paused: true);
    //   i2.addOnExitListener(ext2.sendPort, response: 'ended');
    //   i2.resume(i2.pauseCapability!);
    //
    //   // wait for isolates to terminate
    //   await ext.elementAt(1);
    //   await ext2.elementAt(1);
    //
    //   // getting all event
    //   await l.awaitCount(3);
    //   expect(l.events.length, 3);
    //   print("## dumping master events");
    //   for (ChangeEvent evt in l.events) {
    //     print(evt);
    //   }
    //
    //   print('## dumping on MASTER');
    //   print(await geigerToolboxStorageController.dump(':Users'));
    //   await geigerToolboxStorageController.deregisterChangeListener(l);
    //
    //   print('## deleting values');
    //   await geigerToolboxStorageController.delete(':Users:test:test1');
    //   await geigerToolboxStorageController.delete(':Users:test:test2');
    //   await geigerToolboxStorageController.delete(':Users:test');
    //   await api.close();
    // });
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
  const int size = 10 * 1024 * 1024 - 20000;
  group('reuven test', () {
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
      m2.hash = null;
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
      await api!.storage.delete(':Users:hugetest');

      await api.close();
    }, timeout: const Timeout(Duration(seconds: 120)));
    test('20220412 - Plugin event propagation (issue #22)', () async {
      await StorageMapper.initDatabaseExpander();

      //setup endpoints
      GeigerApi api = (await getGeigerApi(
          "", GeigerApi.masterId, Declaration.doNotShareData))!;
      await api.storage.zap();
      GeigerApi papi1 =
          (await getGeigerApi("", "plugin1", Declaration.doNotShareData))!;
      GeigerApi papi2 =
          (await getGeigerApi("", "plugin2", Declaration.doNotShareData))!;

      // setup listeners
      CollectingListener l = CollectingListener();
      await api.storage
          .registerChangeListener(l, SearchCriteria(searchPath: ':Users:test'));
      CollectingListener l1 = CollectingListener();
      await papi1.storage.registerChangeListener(
          l1, SearchCriteria(searchPath: ':Users:test'));
      CollectingListener l2 = CollectingListener();
      await papi2.storage.registerChangeListener(
          l2, SearchCriteria(searchPath: ':Users:test'));

      // insert data in plugin 1
      papi1.storage.add(NodeImpl(":Users:test", "testowner"));
      print("waiting for event in plugin 1");
      await l1.awaitCount(1);
      print(l1.events);
      print("waiting for event in master");
      await l.awaitCount(1);
      print(l.events);
      print("waiting for event in plugin 2");
      await l2.awaitCount(1);
      print(l2.events);

      // remove data
      print('## deleting value');
      await api.storage.delete(':Users:test');

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
      WidgetsFlutterBinding.ensureInitialized();
      expect(await rootBundle.loadString('store.data'), isNotNull);
      expect((await sc.get(":Global:threats")).path, ':Global:threats');
    });
  });
}

Future<void> main() async {
  printLogger();
  setUp(() => flushGeigerApiCache());
  await algarclamTests();
  await luongTests();
  await reuvenTests();
  // await cftnTests();
}
