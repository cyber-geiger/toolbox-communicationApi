import 'package:flutter_test/flutter_test.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

import '../../../utils/api.dart';
import '../../../utils/logger.dart';

const pluginId = "plugin";

const rootPath = GenericController.pathDelimiter;
const nodePath = GenericController.pathDelimiter + "test";
const otherNodePath = GenericController.pathDelimiter + "otherTest";

const valueKey = "test";
const valueValue = "test";
const hugeValueLength = 10 * (1 << 20);

String generateHugeValue() {
  return ' ' * hugeValueLength;
}

Future<Node> createNode([String path = nodePath]) {
  return NodeImpl.fromPath(path, pluginId);
}

Future addNode(GeigerApi plugin, [String path = nodePath]) async {
  await plugin.storage.add(await createNode(path));
}

Future addTombstone(GeigerApi plugin, [String path = nodePath]) async {
  await addNode(plugin, path);
  await plugin.storage.delete(path);
}

void testNodeExistence(
  String namePrefix, {
  int existentMessageCount = 3,
  int nonExistentMessageCount = 3,
  int tombstoneMessageCount = 3,
}) {
  testMasterBasic('${namePrefix}_Existent', existentMessageCount,
      setup: addNode);
  testMasterBasic('${namePrefix}_NonExistent', nonExistentMessageCount);
  testMasterBasic('${namePrefix}_Tombstone', tombstoneMessageCount,
      setup: addTombstone);
}

void testOtherNodeExistence(
  String namePrefix, {
  int existentMessageCount = 3,
  int nonExistentMessageCount = 3,
  int tombstoneMessageCount = 3,
}) {
  testMasterBasic('${namePrefix}_Existent', existentMessageCount,
      setup: (master) =>
          Future.wait([addNode(master), addNode(master, otherNodePath)]));
  testMasterBasic('${namePrefix}_NonExistent', nonExistentMessageCount,
      setup: addNode);
  testMasterBasic('${namePrefix}_Tombstone', tombstoneMessageCount,
      setup: (master) =>
          Future.wait([addNode(master), addTombstone(master, otherNodePath)]));
}

NodeValue createValue([String value = valueValue]) {
  return NodeValueImpl(valueKey, value, "test", "test", 0);
}

Future addValue(GeigerApi plugin, [String value = valueValue]) async {
  await addNode(plugin);
  await plugin.storage.addValue(nodePath, createValue(value));
}

void testValueExistence(
  String namePrefix, {
  int existentMessageCount = 3,
  int nonExistentMessageCount = 3,
  int noNodeMessageCount = 3,
}) {
  testMasterBasic('${namePrefix}_Existent', existentMessageCount,
      setup: addValue);
  testMasterBasic('${namePrefix}_NonExistent', nonExistentMessageCount,
      setup: addNode);
  testMasterBasic('${namePrefix}_NoNode', noNodeMessageCount);
}

void main() {
  printLogger();

  group('TestGet', () {
    testNodeExistence('testGet');
  });
  group('TestGetNodeOrTombstone', () {
    testNodeExistence('testGetNodeOrTombstone');
  });
  group('TestAdd', () {
    testNodeExistence('testAdd',
        nonExistentMessageCount: 4, tombstoneMessageCount: 4);
  });
  group('TestUpdate', () {
    testNodeExistence('testUpdate', existentMessageCount: 5);
  });
  group('TestDelete', () {
    testNodeExistence('testDelete',
        existentMessageCount: 4, tombstoneMessageCount: 4);
  });
  group('TestAddOrUpdate', () {
    testNodeExistence('testAddOrUpdate',
        existentMessageCount: 5,
        nonExistentMessageCount: 4,
        tombstoneMessageCount: 4);
  });
  group('TestRename', () {
    testNodeExistence('testRenameByPath', existentMessageCount: 5);
    testMasterBasic('testRenameByName', 5, setup: addNode);
    testOtherNodeExistence('testRenameTo', tombstoneMessageCount: 5);
    testOtherNodeExistence('testRenameWithParent',
        existentMessageCount: 5, tombstoneMessageCount: 5);
  });
  group('TestGetValue', () {
    testValueExistence('testGetValue');
    testMasterBasic('testGetValueHugeValue', 3,
        setup: (master) => addValue(master, generateHugeValue()),
        exitWait: const Duration(seconds: 20));
  });
  group('TestAddValue', () {
    testValueExistence('testAddValue', nonExistentMessageCount: 4);
    testMasterBasic('testAddValueHugeValue', 4,
        setup: addNode, exitWait: const Duration(seconds: 20));
  });
  group('TestAddOrUpdateValue', () {
    testValueExistence('testAddOrUpdateValue',
        nonExistentMessageCount: 4, existentMessageCount: 5);
  });
  group('TestUpdateValue', () {
    testValueExistence('testUpdateValue', existentMessageCount: 5);
  });
  group('TestDeleteValue', () {
    testValueExistence('testDeleteValue');
  });
  group('TestSearch', () {
    testMasterBasic('testSearch', 3, setup: addNode);
  });
  group('TestClose', () {
    testMasterBasic('testClose', 3);
  });
  group('TestFlush', () {
    testMasterBasic('testFlush', 2);
  });
  group('TestZap', () {
    testMasterBasic('testZap', 3);
  });
  group('TestDump', () {
    testNodeExistence('testDump');
    testMasterBasic('testDumpPrefix', 3, setup: addNode);
  });
}
