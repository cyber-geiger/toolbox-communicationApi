import 'package:communicationapi/geiger_api.dart';
import 'package:communicationapi/src/communication/geiger_url.dart';
import 'package:communicationapi/src/communication/menu_item.dart';
import 'package:communicationapi/src/communication/plugin_listener.dart';
import 'package:test/test.dart';

void main() {
  flushPluginCache() {
    instances.clear();
  }

  test('Register External Plugin', () async {
    flushPluginCache();
    GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.MASTER_ID, Declaration.doNotShareData))!;
    SimpleEventListener masterListener = SimpleEventListener();
    List<MessageType> allEvents = [MessageType.ALL_EVENTS];
    await localMaster.registerListener(allEvents, masterListener);
    var plugin =
        (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;
    SimpleEventListener pluginListener = SimpleEventListener();
    await plugin.registerListener(allEvents, pluginListener);
    List<Message> receivedEventsMaster = masterListener.getEvents();
    expect(receivedEventsMaster.length, 2);
    Message rcvdMessage = receivedEventsMaster[0];
    expect(rcvdMessage.type, MessageType.REGISTER_PLUGIN);
    expect(rcvdMessage.sourceId, 'plugin1');
    expect(rcvdMessage.action?.protocol, 'geiger');
    expect(rcvdMessage.action?.plugin, GeigerApi.MASTER_ID);
    expect(rcvdMessage.action?.path, 'registerPlugin');
  });

  test('Activate Plugin', () async {
    flushPluginCache();
    var localMaster = (await getGeigerApi(
        '', GeigerApi.MASTER_ID, Declaration.doNotShareData))!;
    SimpleEventListener masterListener = SimpleEventListener();
    List<MessageType> allEvents = [MessageType.ALL_EVENTS];
    await localMaster.registerListener(allEvents, masterListener);
    var plugin =
        (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;
    SimpleEventListener pluginListener = SimpleEventListener();
    await plugin.registerListener(allEvents, pluginListener);
    List<Message> receivedEventsMaster = masterListener.getEvents();
    expect(receivedEventsMaster.length, 2);
    Message rcvdMessage = receivedEventsMaster[1];
    expect(rcvdMessage.type, MessageType.ACTIVATE_PLUGIN);
    expect(rcvdMessage.sourceId, 'plugin1');
    expect(rcvdMessage.action, null);
  });
  test('Deactivate Plugin', () async {
    flushPluginCache();
    var localMaster = (await getGeigerApi(
        '', GeigerApi.MASTER_ID, Declaration.doNotShareData))!;
    SimpleEventListener masterListener = SimpleEventListener();
    List<MessageType> allEvents = [MessageType.ALL_EVENTS];
    await localMaster.registerListener(allEvents, masterListener);
    var plugin =
        (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;
    SimpleEventListener pluginListener = SimpleEventListener();
    await plugin.registerListener(allEvents, pluginListener);

    //deregister Plugin
    await plugin.deregisterPlugin();

    List<Message> receivedEventsMaster = masterListener.getEvents();
    expect(receivedEventsMaster.length, 2);
    Message rcvdMessage = receivedEventsMaster[1];
    expect(rcvdMessage.type, MessageType.ACTIVATE_PLUGIN);
    expect(rcvdMessage.sourceId, 'plugin1');
    expect(rcvdMessage.action, null);

    List<Message> receivedEventsPlugin = pluginListener.getEvents();
    expect(receivedEventsPlugin.length, 2);
    rcvdMessage = receivedEventsPlugin[1];
    expect(rcvdMessage.type, MessageType.COMAPI_SUCCESS);
    expect(rcvdMessage.sourceId, GeigerApi.MASTER_ID);
    expect(rcvdMessage.action?.protocol, 'geiger');
    expect(rcvdMessage.action?.plugin, 'plugin1');
    expect(rcvdMessage.action?.path, 'activatePlugin');
  });
  group('register Menu', () {
    test('check Master', () async {
      flushPluginCache();
      var localMaster = (await getGeigerApi(
          '', GeigerApi.MASTER_ID, Declaration.doNotShareData))!;
      SimpleEventListener masterListener = SimpleEventListener();
      List<MessageType> allEvents = [MessageType.ALL_EVENTS];
      await localMaster.registerListener(allEvents, masterListener);
      var plugin =
          (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;
      SimpleEventListener pluginListener = SimpleEventListener();
      await plugin.registerListener(allEvents, pluginListener);

      //register Menu
      plugin.registerMenu(
          'testMenu', GeigerUrl(null, GeigerApi.MASTER_ID, 'testMenu'));

      List<Message> receivedEventsMaster = pluginListener.getEvents();
      expect(receivedEventsMaster.length, 3);
      Message rcvdMessage = receivedEventsMaster[2];
      expect(rcvdMessage.type, MessageType.REGISTER_MENU);
      expect(rcvdMessage.sourceId, 'plugin1');
      expect(rcvdMessage.action?.protocol, 'geiger');
      expect(rcvdMessage.action?.plugin, GeigerApi.MASTER_ID);
      expect(rcvdMessage.action?.path, 'registerMenu');
      expect(
          MenuItem.fromByteArray(rcvdMessage.payload),
          MenuItem(
              'testMenu', GeigerUrl(null, GeigerApi.MASTER_ID, 'testMenu')));
    });
    test('check Plugin', () async {
      flushPluginCache();
      var localMaster = (await getGeigerApi(
          '', GeigerApi.MASTER_ID, Declaration.doNotShareData))!;
      SimpleEventListener masterListener = SimpleEventListener();
      List<MessageType> allEvents = [MessageType.ALL_EVENTS];
      await localMaster.registerListener(allEvents, masterListener);
      var plugin =
          (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;
      SimpleEventListener pluginListener = SimpleEventListener();
      await plugin.registerListener(allEvents, pluginListener);

      //register Menu
      plugin.registerMenu(
          'testMenu', GeigerUrl(null, GeigerApi.MASTER_ID, 'testMenu'));

      List<Message> receivedEventsMaster = pluginListener.getEvents();
      expect(receivedEventsMaster.length, 3);
      Message rcvdMessage = receivedEventsMaster[2];
      expect(rcvdMessage.type, MessageType.COMAPI_SUCCESS);
      expect(rcvdMessage.sourceId, GeigerApi.MASTER_ID);
      expect(rcvdMessage.action?.protocol, 'geiger');
      expect(rcvdMessage.action?.plugin, 'plugin1');
      expect(rcvdMessage.action?.path, 'registerMenu');
    });
  });
  group('Disable Menu', () {
    test('check Master', () async {
      flushPluginCache();
      var localMaster = (await getGeigerApi(
          '', GeigerApi.MASTER_ID, Declaration.doNotShareData))!;
      SimpleEventListener masterListener = SimpleEventListener();
      List<MessageType> allEvents = [MessageType.ALL_EVENTS];
      await localMaster.registerListener(allEvents, masterListener);
      var plugin =
          (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;
      SimpleEventListener pluginListener = SimpleEventListener();
      await plugin.registerListener(allEvents, pluginListener);

      //register and disable Menu
      plugin.registerMenu(
          'testMenu', GeigerUrl(null, GeigerApi.MASTER_ID, 'testMenu'));
      plugin.disableMenu('testMenu');

      List<Message> receivedEventsMaster = pluginListener.getEvents();
      expect(receivedEventsMaster.length, 4);
      Message rcvdMessage = receivedEventsMaster[3];
      expect(rcvdMessage.type, MessageType.DISABLE_MENU);
      expect(rcvdMessage.sourceId, 'plugin1');
      expect(rcvdMessage.action?.protocol, 'geiger');
      expect(rcvdMessage.action?.plugin, GeigerApi.MASTER_ID);
      expect(rcvdMessage.action?.path, 'disabelMenu');
      expect(rcvdMessage.payload.toString(), 'testMenu');
    });
    test('check Plugin', () async {
      flushPluginCache();
      var localMaster = (await getGeigerApi(
          '', GeigerApi.MASTER_ID, Declaration.doNotShareData))!;
      SimpleEventListener masterListener = SimpleEventListener();
      List<MessageType> allEvents = [MessageType.ALL_EVENTS];
      await localMaster.registerListener(allEvents, masterListener);
      var plugin =
          (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;
      SimpleEventListener pluginListener = SimpleEventListener();
      await plugin.registerListener(allEvents, pluginListener);

      //register and disable Menu
      plugin.registerMenu(
          'testMenu', GeigerUrl(null, GeigerApi.MASTER_ID, 'testMenu'));
      plugin.disableMenu('testMenu');

      List<Message> receivedEventsMaster = pluginListener.getEvents();
      expect(receivedEventsMaster.length, 4);
      Message rcvdMessage = receivedEventsMaster[3];
      expect(rcvdMessage.type, MessageType.COMAPI_SUCCESS);
      expect(rcvdMessage.sourceId, GeigerApi.MASTER_ID);
      expect(rcvdMessage.action?.protocol, 'geiger');
      expect(rcvdMessage.action?.plugin, 'plugin1');
      expect(rcvdMessage.action?.path, 'disableMenu');
    });
  });
  group('menu pressed', () {
    test('check Master', () async {
      flushPluginCache();
      var localMaster = (await getGeigerApi(
          '', GeigerApi.MASTER_ID, Declaration.doNotShareData))!;
      SimpleEventListener masterListener = SimpleEventListener();
      List<MessageType> allEvents = [MessageType.ALL_EVENTS];
      await localMaster.registerListener(allEvents, masterListener);
      var plugin =
          (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;
      SimpleEventListener pluginListener = SimpleEventListener();
      await plugin.registerListener(allEvents, pluginListener);

      //register Menu
      plugin.registerMenu(
          'testMenu', GeigerUrl(null, GeigerApi.MASTER_ID, 'testMenu'));
      plugin.menuPressed(GeigerUrl(null, GeigerApi.MASTER_ID, 'testMenu'));

      List<Message> receivedEventsMaster = pluginListener.getEvents();
      expect(receivedEventsMaster.length, 4);
      Message rcvdMessage = receivedEventsMaster[3];
      expect(rcvdMessage.type, MessageType.MENU_PRESSED);
      expect(rcvdMessage.sourceId, 'plugin1');
      expect(rcvdMessage.action?.protocol, 'geiger');
      expect(rcvdMessage.action?.plugin, 'plugin1');
      expect(rcvdMessage.action?.path, 'testMenu');

      fail('not implemented');
    });
  });
  group('register Listener', () {
    //TODO(mgwerder): not implemented
  });
  group('Deregister Listener', () {
    //TODO(mgwerder): not implemented
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

  @override
  void pluginEvent(GeigerUrl? url, Message msg) {
    events.add(msg);
    print('## SimpleEventListener received event ' +
        msg.type.toString() +
        ' it currently has: ' +
        events.length.toString() +
        ' events');
  }

  List<Message> getEvents() {
    return events;
  }
}
