import 'package:flutter_test/flutter_test.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

import '../../../utils/api.dart';
import '../../../utils/logger.dart';

const pluginId = "plugin";

const rootPath = GenericController.pathDelimiter;
const nodePath = GenericController.pathDelimiter + "test";
const otherNodePath = GenericController.pathDelimiter + "otherTest";

const valueKey = "test";
const valueSmallValue = "test";
const hugeValueLength = 10 * (1 << 20);

String generateHugeValue() {
  return ' ' * hugeValueLength;
}

Future<Node> createNode([String path = nodePath]) {
  return NodeImpl.fromPath(path, pluginId);
}

NodeValue createValue(String value) {
  return NodeValueImpl(valueKey, value, "test", "test", 0);
}

void testExistenceTriplet(
  String namePrefix, {
  int existentMessageCount = 3,
  int nonExistentMessageCount = 3,
  int tombstoneMessageCount = 3,
}) {
  testMasterBasic('${namePrefix}_Existent', existentMessageCount,
      setup: (master) async {
    await master.storage.add(await createNode());
  });
  testMasterBasic('${namePrefix}_NonExistent', nonExistentMessageCount);
  testMasterBasic('${namePrefix}_Tombstone', tombstoneMessageCount,
      setup: (master) async {
    await master.storage.add(await createNode());
    await master.storage.delete(nodePath);
  });
}

void main() {
  printLogger();
  testExistenceTriplet('testGet');
  testExistenceTriplet('testGetNodeOrTombstone');
  testExistenceTriplet('testAdd',
      nonExistentMessageCount: 4, tombstoneMessageCount: 4);
  testExistenceTriplet('testUpdate', existentMessageCount: 5);
  testExistenceTriplet('testDelete',
      existentMessageCount: 4, tombstoneMessageCount: 4);
  testExistenceTriplet('testAddOrUpdate',
      existentMessageCount: 5,
      nonExistentMessageCount: 4,
      tombstoneMessageCount: 4);
  testExistenceTriplet('testRenameByPath', existentMessageCount: 5);
  testMasterBasic('testRenameByName', 5, setup: (master) async {
    await master.storage.add(await createNode());
  });
  testMasterBasic('testGetValue_SmallValue', 3, setup: (master) async {
    await master.storage.addValue(rootPath, createValue(valueSmallValue));
  });
  testMasterBasic('testGetValue_HugeValue', 3, setup: (master) async {
    await master.storage.addValue(rootPath, createValue(generateHugeValue()));
  }, exitWait: const Duration(seconds: 20));
  testMasterBasic('testGetValue_NoValue', 3);
  testMasterBasic('testGetValue_NoNode', 3);
}
