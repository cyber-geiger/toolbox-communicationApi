// ignore_for_file: avoid_print

library geiger_api;

import 'package:collection/collection.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'print_logger.dart';

class TestMessage {}

void main() {
  printLogger();
  test('testConstructionGetterSetter', () {
    String sourceId = 'sourceId';
    String targetId = 'targetId';
    MessageType messageType = MessageType.allEvents;
    GeigerUrl? url;
    try {
      url = GeigerUrl(null, GeigerApi.masterId, 'geiger://plugin/path');
    } catch (e) {
      print(e);
    }

    Message msg = Message(sourceId, targetId, messageType, url);
    expect(msg.sourceId == sourceId, true, reason: 'sourceId does not match');
    expect(msg.targetId == targetId, true, reason: 'targetId does not match');
    expect(msg.type == messageType, true, reason: 'messageType does not match');
    expect(msg.action == url, true, reason: 'GeigerUrl does not match');
    expect(msg.payloadString != null, true, reason: 'payloadString is empty');
    expect(msg.payload.isEmpty, true, reason: 'payload is not empty');

    List<int> payload = 'payload'.codeUnits;
    Message msg2 = Message(sourceId, targetId, messageType, url, payload);
    expect(msg2.sourceId == sourceId, true, reason: 'sourceId does not match');
    expect(msg2.targetId == targetId, true, reason: 'targetId does not match');
    expect(msg2.type == messageType, true,
        reason: 'messageType does not match');
    expect(msg2.action == url, true, reason: 'GeigerUrl does not match');
    expect(msg2.payloadString != null, true, reason: 'payloadString is empty');
    expect(msg2.payload.equals(payload), true,
        reason: 'payload does not match');

    List<int> payload2 = 'payload2'.codeUnits;
    msg2.payload = payload2;
    expect(msg2.payload.equals(payload2), true,
        reason: 'new payload does not match');
  });

  test('testEquals', () {
    String sourceId = 'sourceId';
    String targetId = 'targetId';
    MessageType messageType = MessageType.allEvents;
    String requestId = 'some-id';
    List<int> payload = 'payload'.codeUnits;
    GeigerUrl url = GeigerUrl(null, GeigerApi.masterId, 'geiger://plugin/path');

    //without payload
    Message msg =
        Message(sourceId, targetId, messageType, url, null, requestId);
    Message msg2 =
        Message(sourceId, targetId, messageType, url, null, requestId);
    expect(msg2, msg);

    //with payload
    Message msg3 =
        Message(sourceId, targetId, messageType, url, payload, requestId);
    Message msg4 =
        Message(sourceId, targetId, messageType, url, payload, requestId);
    expect(msg3, msg4);
    expect(msg, isNot(msg3));

    //negative tests
    List<int> payload2 = 'payload2'.codeUnits;
    Message msg5 = Message(sourceId, targetId, messageType, url, payload2);
    expect(msg5, isNot(msg3));

    String requestId2 = 'some-other-id';
    Message msg6 =
        Message(sourceId, targetId, messageType, url, null, requestId2);
    expect(msg6, isNot(msg));
  });

  test('testHashCode', () {
    String sourceId = 'sourceId';
    String targetId = 'targetId';
    MessageType messageType = MessageType.allEvents;
    String requestId = 'some-id';
    List<int> payload = 'payload'.codeUnits;
    GeigerUrl url = GeigerUrl(null, GeigerApi.masterId, 'geiger://plugin/path');

    //without payload
    Message msg =
        Message(sourceId, targetId, messageType, url, null, requestId);
    Message msg2 =
        Message(sourceId, targetId, messageType, url, null, requestId);
    expect(msg.hashCode == msg2.hashCode, true);

    //with payload
    Message msg3 =
        Message(sourceId, targetId, messageType, url, payload, requestId);
    Message msg4 =
        Message(sourceId, targetId, messageType, url, payload, requestId);
    expect(msg3.hashCode == msg4.hashCode, true);

    //negative tests
    expect(msg.hashCode != msg3.hashCode, true);
  });

  test('payloadEncodingTest', () {
    Message m =
        Message('src', 'target', MessageType.activatePlugin, null, null);
    final List<String?> i = [null, '', const Uuid().v4()];
    for (final String? pl in i) {
      m.payloadString = pl;
      expect(pl == m.payloadString, true);

      List<int>? blarr;
      if (pl != null) {
        blarr = pl.codeUnits;
        m.payload = blarr;
        expect(blarr.equals(m.payload), true);
      }
    }
  });
}
