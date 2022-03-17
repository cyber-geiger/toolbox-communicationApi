import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.time} ${record.level.name}: ${record.message}');
  });

  test('Register External Plugin', () async {
    flushGeigerApiCache();
    GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    await localMaster.zapState();
    SimpleEventListener masterListener = SimpleEventListener('master');
    List<MessageType> allEvents = [MessageType.allEvents];
    await localMaster.registerListener(allEvents, masterListener);
    var plugin =
        (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;
    SimpleEventListener pluginListener = SimpleEventListener('plugin');
    await plugin.registerListener(allEvents, pluginListener);
    List<Message> receivedEventsMaster = masterListener.getEvents();
    //print(receivedEventsMaster.toString());
    //print(pluginListener.toString());
    expect(receivedEventsMaster.length, 2);
    Message rcvdMessage = receivedEventsMaster[0];
    expect(rcvdMessage.type, MessageType.registerPlugin);
    expect(rcvdMessage.sourceId, 'plugin1');
    expect(rcvdMessage.action?.protocol, 'geiger');
    expect(rcvdMessage.action?.plugin, GeigerApi.masterId);
    expect(rcvdMessage.action?.path, 'registerPlugin');
    await localMaster.close();
    await plugin.close();
  });

  test('Activate Plugin', () async {
    flushGeigerApiCache();
    var localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    await localMaster.zapState();
    SimpleEventListener masterListener = SimpleEventListener('master');
    List<MessageType> allEvents = [MessageType.allEvents];
    await localMaster.registerListener(allEvents, masterListener);
    var plugin =
        (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;
    SimpleEventListener pluginListener = SimpleEventListener('plugin');
    await plugin.registerListener(allEvents, pluginListener);
    List<Message> receivedEventsMaster = masterListener.getEvents();
    //print(masterListener.toString());
    expect(receivedEventsMaster.length, 2);
    Message rcvdMessage = receivedEventsMaster[1];
    expect(rcvdMessage.type, MessageType.activatePlugin);
    expect(rcvdMessage.sourceId, 'plugin1');
    expect(rcvdMessage.action, null);
    await localMaster.close();
    await plugin.close();
  });

  test('Deactivate Plugin', () async {
    flushGeigerApiCache();
    var localMaster = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    await localMaster.zapState();
    SimpleEventListener masterListener = SimpleEventListener('master');
    List<MessageType> allEvents = [MessageType.allEvents];
    await localMaster.registerListener(allEvents, masterListener);
    var plugin =
        (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;
    SimpleEventListener pluginListener = SimpleEventListener('plugin');
    await plugin.registerListener(allEvents, pluginListener);

    //deregister Plugin
    await plugin.deregisterPlugin();

    List<Message> receivedEventsMaster = masterListener.getEvents();
    //print(masterListener);
    expect(receivedEventsMaster.length, 3);
    Message rcvdMessage = receivedEventsMaster[2];
    expect(rcvdMessage.type, MessageType.deregisterPlugin);
    expect(rcvdMessage.sourceId, 'plugin1');
    expect(rcvdMessage.action?.protocol, 'geiger');
    expect(rcvdMessage.action?.plugin, GeigerApi.masterId);
    expect(rcvdMessage.action?.path, 'deregisterPlugin');

    //print(pluginListener);
    List<Message> receivedEventsPlugin = pluginListener.getEvents();
    expect(receivedEventsPlugin.length, 1);
    rcvdMessage = receivedEventsPlugin[0];
    expect(rcvdMessage.type, MessageType.comapiSuccess);
    expect(rcvdMessage.sourceId, GeigerApi.masterId);
    expect(rcvdMessage.action?.protocol, 'geiger');
    expect(rcvdMessage.action?.plugin, 'plugin1');
    expect(rcvdMessage.action?.path, 'deregisterPlugin');
    await localMaster.close();
    await plugin.close();
  });

  group('register Menu', () {
    test('check Master', () async {
      flushGeigerApiCache();
      var localMaster = (await getGeigerApi(
          '', GeigerApi.masterId, Declaration.doNotShareData))!;
      await localMaster.zapState();
      SimpleEventListener masterListener = SimpleEventListener('master');
      List<MessageType> allEvents = [MessageType.allEvents];
      await localMaster.registerListener(allEvents, masterListener);
      var plugin =
          (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;
      SimpleEventListener pluginListener = SimpleEventListener('plugin');
      await plugin.registerListener(allEvents, pluginListener);

      //register Menu
      final MenuItem menu = MenuItem(
          await NodeImpl.fromPath(
              ':menu:1111-1111-111111-111113:testMenu', 'pid',
              nodeValues: [NodeValueImpl('name', 'Plugin2Score')]),
          GeigerUrl(null, GeigerApi.masterId, 'testMenu'),
          false);
      await plugin.registerMenu(menu);

      List<Message> receivedEventsMaster = masterListener.getEvents();
      expect(receivedEventsMaster.length, 3);
      Message rcvdMessage = receivedEventsMaster[2];
      expect(rcvdMessage.type, MessageType.registerMenu);
      expect(rcvdMessage.sourceId, 'plugin1');
      expect(rcvdMessage.action?.protocol, 'geiger');
      expect(rcvdMessage.action?.plugin, GeigerApi.masterId);
      expect(rcvdMessage.action?.path, 'registerMenu');
      expect(
          await MenuItem.fromByteArrayStream(
              ByteStream(null, rcvdMessage.payload)),
          menu,
          reason: 'deserialized MenuItem does not match');

      List<Message> receivedEventsPlugin = pluginListener.getEvents();
      expect(receivedEventsPlugin.length, 1);
      rcvdMessage = receivedEventsPlugin[0];
      expect(rcvdMessage.type, MessageType.comapiSuccess);
      expect(rcvdMessage.sourceId, GeigerApi.masterId);
      expect(rcvdMessage.action?.protocol, 'geiger');
      expect(rcvdMessage.action?.plugin, 'plugin1');
      expect(rcvdMessage.action?.path, 'registerMenu');
      await localMaster.close();
      await plugin.close();
    });
  });

  group('Disable Menu', () {
    test('check Master', () async {
      flushGeigerApiCache();
      var localMaster = (await getGeigerApi(
          '', GeigerApi.masterId, Declaration.doNotShareData))!;
      await localMaster.zapState();
      SimpleEventListener masterListener = SimpleEventListener('master');
      List<MessageType> allEvents = [MessageType.allEvents];
      await localMaster.registerListener(allEvents, masterListener);
      var plugin =
          (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;
      SimpleEventListener pluginListener = SimpleEventListener('plugin');
      await plugin.registerListener(allEvents, pluginListener);

      //register and disable Menu
      final MenuItem menu = MenuItem(
          await NodeImpl.fromPath(
              ':menu:1111-1111-111111-111113:testMenu', 'pid',
              nodeValues: [NodeValueImpl('name', 'Plugin2Score')]),
          GeigerUrl(null, GeigerApi.masterId, 'testMenu'),
          false);
      await plugin.registerMenu(menu);
      await plugin.disableMenu('testMenu');

      List<Message> receivedEventsMaster = masterListener.getEvents();
      expect(receivedEventsMaster.length, 4);
      Message rcvdMessage = receivedEventsMaster[3];
      expect(rcvdMessage.type, MessageType.disableMenu);
      expect(rcvdMessage.sourceId, 'plugin1');
      expect(rcvdMessage.action?.protocol, 'geiger');
      expect(rcvdMessage.action?.plugin, GeigerApi.masterId);
      expect(rcvdMessage.action?.path, 'disableMenu');
      expect(rcvdMessage.payloadString, 'testMenu');

      List<Message> receivedEventsPlugin = pluginListener.getEvents();
      expect(receivedEventsPlugin.length, 2);
      rcvdMessage = receivedEventsPlugin[1];
      expect(rcvdMessage.type, MessageType.comapiSuccess);
      expect(rcvdMessage.sourceId, GeigerApi.masterId);
      expect(rcvdMessage.action?.protocol, 'geiger');
      expect(rcvdMessage.action?.plugin, 'plugin1');
      expect(rcvdMessage.action?.path, 'disableMenu');
      await localMaster.close();
      await plugin.close();
    });
  });

  group('menu pressed', () {
    test('check Master', () async {
      flushGeigerApiCache();
      var localMaster = (await getGeigerApi(
          '', GeigerApi.masterId, Declaration.doNotShareData))!;
      await localMaster.zapState();
      SimpleEventListener masterListener = SimpleEventListener('master');
      List<MessageType> allEvents = [MessageType.allEvents];
      await localMaster.registerListener(allEvents, masterListener);
      var plugin =
          (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;
      SimpleEventListener pluginListener = SimpleEventListener('plugin');
      await plugin.registerListener(allEvents, pluginListener);

      //register Menu
      final MenuItem menu = MenuItem(
          await NodeImpl.fromPath(
              ':menu:1111-1111-111111-111113:testMenu', 'pid',
              nodeValues: [NodeValueImpl('name', 'Plugin2Score')]),
          GeigerUrl(null, GeigerApi.masterId, 'testMenu'),
          false);
      await plugin.registerMenu(menu);
      await localMaster.menuPressed(GeigerUrl(null, 'plugin1', 'testMenu'));
      await Future.delayed(const Duration(seconds: 1));

      List<Message> receivedEventsMaster = masterListener.getEvents();
      expect(receivedEventsMaster.length, 3);
      Message rcvdMessage = receivedEventsMaster[2];
      expect(rcvdMessage.type, MessageType.registerMenu);
      expect(rcvdMessage.sourceId, 'plugin1');
      expect(rcvdMessage.action?.protocol, 'geiger');
      expect(rcvdMessage.action?.plugin, GeigerApi.masterId);
      expect(rcvdMessage.action?.path, 'registerMenu');
      //expect(GeigerUrl.fromByteArrayStream(ByteStream(null,rcvdMessage.payload)), GeigerUrl(null,'plugin1','testMenu'));

      List<Message> receivedEventsPlugin = pluginListener.getEvents();
      expect(receivedEventsPlugin.length, 2);
      rcvdMessage = receivedEventsPlugin[1];
      expect(rcvdMessage.type, MessageType.menuPressed);
      expect(rcvdMessage.sourceId, GeigerApi.masterId);
      expect(rcvdMessage.action?.protocol, 'geiger');
      expect(rcvdMessage.action?.plugin, 'plugin1');
      expect(rcvdMessage.action?.path, 'testMenu');
      await localMaster.close();
      await plugin.close();
    });
  });

  test('plugin listener', () async {
    flushGeigerApiCache();
    final master = (await getGeigerApi(
        '', GeigerApi.masterId, Declaration.doNotShareData))!;
    await master.zapState();
    final plugin1 =
        (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;
    final plugin2 =
        (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;

    final listener = SimpleEventListener(plugin1.id);
    await plugin1.registerMasterListener([], listener);
    await plugin1.registerMasterListener(
        [MessageType.registerMenu, MessageType.customEvent], listener);

    plugin2.sendMessage(
        Message(plugin2.id, GeigerApi.masterId, MessageType.ping, null));
    await Future.delayed(const Duration(seconds: 1));
    expect(listener.events.length, 0,
        reason: "Listener received wrong number of events.");

    final action1 = GeigerUrl('geiger', GeigerApi.masterId, 'test1');
    final action2 = GeigerUrl('geiger', GeigerApi.masterId, 'test2');
    plugin2.sendMessage(Message(
        plugin2.id, GeigerApi.masterId, MessageType.customEvent, action1));
    plugin2.sendMessage(Message(
        plugin2.id, GeigerApi.masterId, MessageType.customEvent, action2));
    await Future.delayed(const Duration(seconds: 1));
    expect(listener.events.length, 2,
        reason: "Listener received wrong number of events.");
    expect(listener.events[0].action, action1,
        reason: "First event does not match up.");
    expect(listener.events[1].action, action2,
        reason: "Second event does not match up.");

    await plugin1
        .deregisterMasterListener([MessageType.registerMenu], listener);
    await plugin1.deregisterMasterListener(null, listener);

    plugin2.sendMessage(
        Message(plugin2.id, GeigerApi.masterId, MessageType.customEvent, null));
    await Future.delayed(const Duration(seconds: 1));
    expect(listener.events.length, 2,
        reason: "Listener received events after deregistration.");
  });

  group('get Menu List', () {
    //TODO(mgwerder): not implemented
  });

  group('Scan Button Pressed', () {
    //TODO(mgwerder): not implemented
  });
}

class SimpleEventListener implements PluginListener {
  List<Message> events = [];

  final String _id;

  SimpleEventListener(this._id);

  @override
  void pluginEvent(GeigerUrl? url, Message msg) {
    events.add(msg);
    //print('## SimpleEventListener "$_id" received event ${msg.type} it currently has: ${events.length.toString()} events');
  }

  List<Message> getEvents() {
    return events;
  }

  @override
  String toString() {
    String ret = '';
    ret += 'Eventlistener "$_id" contains {\r\n';
    getEvents().forEach((element) {
      ret += '  ${element.toString()}\r\n';
    });
    ret += '}\r\n';
    return ret;
  }
}
