import 'package:geiger_api/geiger_api.dart';
import 'package:test/test.dart';

import 'message_collector.dart';

const defaultExitWait = const Duration(seconds: 2);

Future<GeigerApi> createMaster() async {
  final master =
      (await getGeigerApi('', GeigerApi.masterId, Declaration.doNotShareData))!;
  await master.zapState();
  await master.storage.zap();
  return master;
}

void testMaster(String name,
    Future Function(GeigerApi master, MessageCollector collector) body,
    [Duration exitWait = defaultExitWait]) {
  test(name, () async {
    final master = await createMaster();
    try {
      await body(master, MessageCollector(master));
    } finally {
      await master.close();
    }
    // Wait for unawaited futures in message listeners to complete.
    await Future.delayed(exitWait);
  });
}

void testMasterBasic(String name, int messageCount,
    {Future Function(GeigerApi master)? setup,
    Duration exitWait = defaultExitWait}) {
  testMaster(name, (master, collector) async {
    await setup?.call(master);
    await collector.awaitCount(
        messageCount, Duration(seconds: 3 * messageCount));
  }, exitWait);
}
