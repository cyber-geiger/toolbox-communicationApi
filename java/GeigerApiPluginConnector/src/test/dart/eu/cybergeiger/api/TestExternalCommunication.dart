import 'package:flutter_test/flutter_test.dart';
import 'package:geiger_api/geiger_api.dart';

import '../../../utils/message_collector.dart';

void main() {
  test('testRegisterExternalPlugin', () async {
    final master = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    final collector = MessageCollector();
    master.registerListener([
      MessageType.registerPlugin,
      MessageType.activatePlugin
    ], collector);
    await collector.awaitCount(1);
    final message = collector.messages[0];
    expect(message.type, MessageType.registerPlugin);
    expect(message.sourceId, 'plugin');
    expect(message.action?.protocol, 'geiger');
    expect(message.action?.plugin, GeigerApi.masterId);
    expect(message.action?.path, 'registerPlugin');
    await collector.awaitCount(2);
  });
}
