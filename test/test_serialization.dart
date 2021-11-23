library geiger_api;

import 'dart:async';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_api/src/communication/communication_secret.dart';
import 'package:geiger_api/src/communication/geiger_url.dart';
import 'package:geiger_api/src/communication/menu_item.dart';
import 'package:geiger_api/src/communication/parameter_list.dart';
import 'package:geiger_api/src/communication/plugin_information.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:uuid/uuid.dart';

class TestSerialization {}

/// Unit testing of serializable objects.
void main() {
  /**
   * <p>Tests the serialization of the ParameterList object.</p>
   */
  test('parameterListSerializationTest', () async {
    ParameterList p = ParameterList(['test', '', 'Test', 'null']);
    ByteSink bout = ByteSink();
    p.toByteArrayStream(bout);
    bout.close();
    ByteStream tempStream =
        ByteStream(Stream<List<int>>.value(await bout.bytes));
    ParameterList? p2 = await ParameterList.fromByteArrayStream(tempStream);
    expect(p.toString() == p2.toString(), true,
        reason: 'Cloned Parameter lists are not equal');
  });

  /**
   * <p>Tests the serialization of the GeigerUrl object.</p>
   */
  test('geigerUrlSerializationTest', () async {
    GeigerUrl p = GeigerUrl(null, GeigerApi.masterId, 'path');
    ByteSink bout = ByteSink();
    p.toByteArrayStream(bout);
    bout.close();
    ByteStream bin = ByteStream(Stream<List<int>>.value(await bout.bytes));

    /// TODO(unassigned): What is that below?
    await GeigerUrl.fromByteArrayStream(bin);

    expect(p.toString() == p.toString(), true,
        reason: 'Cloned GeigerUrls are unequal');
  });

  /**
   * <p>Tests the serialization of the MenuItem object.</p>
   */
  test('menuItemSerializationTest', () async {
    MenuItem p =
        MenuItem('test', GeigerUrl(null, GeigerApi.masterId, 'path'), false);

    ByteSink bout = ByteSink();
    p.toByteArrayStream(bout);
    bout.close();
    ByteStream bin = ByteStream(null, await bout.bytes);
    MenuItem p2 = await MenuItem.fromByteArrayStream(bin);
    expect(p.toString() == p2.toString(), true,
        reason: 'Cloned MenuItems are unequal');
  });

  /**
   * <p>Tests the serialization of the ParameterList object.</p>
   */
  test('pluginInformationSerializationTest', () async {
    PluginInformation p =
        PluginInformation('exec', 1234, CommunicationSecret('Hello'.codeUnits));
    ByteSink bout = ByteSink();
    p.toByteArrayStream(bout);
    bout.close();
    ByteStream bin = ByteStream(Stream<List<int>>.value(await bout.bytes));
    PluginInformation p2 = await PluginInformation.fromByteArrayStream(bin);
    PluginInformation p3 =
        await PluginInformation.fromByteArray(await p.toByteArray()!);
    expect(p.hashCode == p2.hashCode, true,
        reason: 'Cloned Plugininformation using stream are not equal');
    expect(p.hashCode == p3.hashCode, true,
        reason: 'Cloned Plugininformation using array are not equal');
  });

  /**
   * <p>Tests the serialization of the ParameterList object.</p>
   */
  test('communcationSecretSerialization', () async {
    List<CommunicationSecret> comsec = [
      CommunicationSecret('hello'.codeUnits),
      CommunicationSecret('a'.codeUnits),
      CommunicationSecret([35])
    ];

    for (CommunicationSecret p in comsec) {
      ByteSink bout = ByteSink();
      p.toByteArrayStream(bout);
      bout.close();
      ByteStream bin = ByteStream(null, await bout.bytes);
      CommunicationSecret p2 =
          await CommunicationSecret.fromByteArrayStream(bin);
      expect(p.toString() == p2.toString(), true,
          reason: 'Cloned Plugininformation using stream are not equal');
    }
  });

  /**
   * <p>Tests the serialization of the a serializable Hashmap object.</p>
   */
  test('storableMapSerializationTest', () async {
    StorableHashMap<GeigerUrl, GeigerUrl> hm =
        StorableHashMap<GeigerUrl, GeigerUrl>();
    Map<GeigerUrl, GeigerUrl> it = <GeigerUrl, GeigerUrl>{
      GeigerUrl(null, GeigerApi.masterId, 'path'):
          GeigerUrl(null, GeigerApi.masterId, 'path')
    };
    hm.addAll(it);
    ByteSink bout = ByteSink();
    hm.toByteArrayStream(bout);
    bout.close();
    ByteStream bin = ByteStream(Stream<List<int>>.value(await bout.bytes));
    StorableHashMap hm2 = StorableHashMap();
    await StorableHashMap.fromByteArrayStream(bin, hm2);
    expect(hm2.toString() == hm.toString(), true,
        reason: 'Cloned Plugininformation using stream are not equal');
  });

  /**
   * <p>Tests the serialization of the a serializable Hashmap object.</p>
   */
  test('messageSerializationTest', () async {
    List<Message> messageList = [
      Message('src', 'target', MessageType.deactivatePlugin,
          GeigerUrl(null, GeigerApi.masterId, 'geiger://id1/path1'), null),
      Message('src', 'target', MessageType.deactivatePlugin, null, []),
      Message('src', 'target', MessageType.deactivatePlugin,
          GeigerUrl(null, GeigerApi.masterId, 'path2'), []),
      Message('src', 'target', MessageType.deactivatePlugin,
          GeigerUrl(null, GeigerApi.masterId, ''), <int>[]),
      Message('src', 'target', MessageType.deactivatePlugin,
          GeigerUrl(null, GeigerApi.masterId, ''), <int>[]),
      Message('src', 'target', MessageType.allEvents, null, <int>[]),
      Message('src', 'target', MessageType.allEvents, null,
          const Uuid().v4().codeUnits)
    ];

    for (Message m in messageList) {
      ByteSink bout = ByteSink();
      m.toByteArrayStream(bout);
      bout.close();
      ByteStream bin = ByteStream(Stream<List<int>>.value(await bout.bytes));
      Message m2 = await Message.fromByteArray(bin);
      expect(m == m2, true,
          reason: 'Cloned Plugininformation using stream are not equal');
    }
  });
}
