library geiger_api;

import 'dart:async';

import 'package:communicationapi/geiger_api.dart';
import 'package:communicationapi/src/communication/communication_secret.dart';
import 'package:communicationapi/src/communication/geiger_url.dart';
import 'package:communicationapi/src/communication/menu_item.dart';
import 'package:communicationapi/src/communication/parameter_list.dart';
import 'package:communicationapi/src/communication/plugin_information.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:uuid/uuid.dart';


class TestSerialization {}

/**
 * <p>Unit testing of serializable objects.</p>
 */
void main() {

  /**
   * <p>Tests the serialization of the ParameterList object.</p>
   */
  test('parameterListSerializationTest', () async {
    ParameterList p = ParameterList(['test', '', 'Test', 'null']);
    ByteSink bout = ByteSink();
    p.toByteArrayStream(bout);
    ByteStream tempStream = ByteStream(Stream.value(await bout.bytes));
    ParameterList? p2 = await ParameterList.fromByteArrayStream(tempStream);
    expect(p.toString() == p2.toString(), 'Cloned Parameter lists are not equal');
  });

  /**
   * <p>Tests the serialization of the GeigerUrl object.</p>
   */
  test('geigerUrlSerializationTest', () async {
    GeigerUrl p = GeigerUrl(null, GeigerApi.MASTER, "path");
    ByteSink bout = ByteSink();
    p.toByteArrayStream(bout);
    ByteStream bin = ByteStream(Stream.value(await bout.bytes));
    GeigerUrl p2 = await GeigerUrl.fromByteArrayStream(bin);

    expect(p.toString() == p.toString(), true, reason: 'Cloned GeigerUrls are unequal');
  });

  /**
   * <p>Tests the serialization of the MenuItem object.</p>
   */
  test('menuItemSerializationTest', () async {
    MenuItem p = MenuItem("test", GeigerUrl(null, GeigerApi.MASTER, 'path'), false);

    ByteSink bout = ByteSink();
    p.toByteArrayStream(bout);
    ByteStream bin = ByteStream(Stream.value(await bout.bytes));
    MenuItem p2 = await MenuItem.fromByteArrayStream(bin);
    expect(p.toString() == p.toString(), true, reason: 'Cloned MenuItems are unequal');
  });

  /**
   * <p>Tests the serialization of the ParameterList object.</p>
   */
  test('pluginInformationSerializationTest', () async {
      PluginInformation p = PluginInformation("exec", 1234);
      ByteSink bout = ByteSink();
      p.toByteArrayStream(bout);
      ByteStream bin = ByteStream(Stream.value(await bout.bytes));
      PluginInformation p2 = await PluginInformation.fromByteArrayStream(bin);
      PluginInformation p3 = await PluginInformation.fromByteArray(await p.toByteArray() as List<int>);
      expect(p != null, true, reason: 'PluginInformation p equals null');
      expect(p2 != null, true, reason: 'PluginInformation p2 equals null');
      expect(p3 != null, true, reason: 'PluginInformation p3 equals null');
      expect(p.hashCode == p2.hashCode, true, reason: 'Cloned Plugininformation using stream are not equal');
      expect(p.hashCode == p3.hashCode, true, reason: 'Cloned Plugininformation using array are not equal');

  });

  test('communcationSecretSerialization', () async {
    List<CommunicationSecret> comsec = [
      CommunicationSecret('Hello'.codeUnits),
      CommunicationSecret([]),
      new CommunicationSecret([1024])];

    for (CommunicationSecret p in comsec)
      {
        ByteSink bout = ByteSink();
        p.toByteArrayStream(bout);
        ByteStream bin = ByteStream(Stream.value(await bout.bytes));
        CommunicationSecret p2 = await CommunicationSecret.fromByteArrayStream(bin);
        expect(p != null, true);
        expect(p2 != null, true, reason: "deserialized object (stream) is null");
        expect(p.toString() == p2.toString(), "Cloned Plugininformation using stream are not equal");
      }
  });

  test('storableMapSerializationTest', () async {
    StorableHashMap hm = StorableHashMap();
    ByteSink bout = ByteSink();
    hm.toByteArrayStream(bout);
    ByteStream bin = ByteStream(Stream.value(await bout.bytes));
    StorableHashMap hm2 = StorableHashMap();
    StorableHashMap.fromByteArrayStream(bin, hm2);
    expect(hm2 != null, true, reason: 'deserialized object (stream) is null');
    expect(hm2.toString() == hm.toString(), true, reason: "Cloned Plugininformation using stream are not equal");
  });

  test('messageSerializationTest', () async {
    List<Message> messageList = [
      Message("src", "target", MessageType.DEACTIVATE_PLUGIN,
          GeigerUrl(null, GeigerApi.MASTER,"geiger://id1/path1"), null),
      Message("src", "target", MessageType.DEACTIVATE_PLUGIN,
          null, []),
      Message("src", "target", MessageType.DEACTIVATE_PLUGIN,
          GeigerUrl(null, GeigerApi.MASTER, "path2"), []),
      Message("src", "target", MessageType.DEACTIVATE_PLUGIN,
          GeigerUrl(null, GeigerApi.MASTER, ""), []),
      Message("src", "target", MessageType.DEACTIVATE_PLUGIN,
          GeigerUrl(null, GeigerApi.MASTER, ""), []),
      Message("src", "target", MessageType.ALL_EVENTS, null, []),
      Message("src", "target", MessageType.ALL_EVENTS, null,
          Uuid().v4().codeUnits)];

    for(Message m in messageList)
      {
        ByteSink bout = ByteSink();
        m.toByteArrayStream(bout);
        ByteStream bin = ByteStream(Stream.value(await bout.bytes));
        Message m2 = await Message.fromByteArray(bin);
        expect(m2 != null, true, reason: 'deserialized object (stream) is null');
        expect(m == m2, true, reason: 'Cloned Plugininformation using stream are not equal');
      }
  });
}

