import 'package:communicationapi/geiger_api.dart';
import 'package:communicationapi/src/communication/geiger_api.dart';
import 'package:communicationapi/src/communication/geiger_url.dart';
import 'package:communicationapi/src/communication/menu_item.dart';
import 'package:communicationapi/src/communication/plugin_listener.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:test/test.dart';

void main() {
  flushPluginCache() {
    instances.clear();
  }

  test('Register External Plugin', () async {
    flushPluginCache();
    GeigerApi localMaster = (await getGeigerApi(
        '', GeigerApi.MASTER_ID, Declaration.doNotShareData))!;
    SimpleEventListener masterListener = SimpleEventListener('master');
    List<MessageType> allEvents = [MessageType.ALL_EVENTS];
    await localMaster.registerListener(allEvents, masterListener);
    var plugin =
        (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;
    SimpleEventListener pluginListener = SimpleEventListener('plugin');
    await plugin.registerListener(allEvents, pluginListener);
    List<Message> receivedEventsMaster = masterListener.getEvents();
    print(receivedEventsMaster.toString());
    print(pluginListener.toString());
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
    SimpleEventListener masterListener = SimpleEventListener('master');
    List<MessageType> allEvents = [MessageType.ALL_EVENTS];
    await localMaster.registerListener(allEvents, masterListener);
    var plugin =
        (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;
    SimpleEventListener pluginListener = SimpleEventListener('plugin');
    await plugin.registerListener(allEvents, pluginListener);
    List<Message> receivedEventsMaster = masterListener.getEvents();
    print(masterListener.toString());
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
    SimpleEventListener masterListener = SimpleEventListener('master');
    List<MessageType> allEvents = [MessageType.ALL_EVENTS];
    await localMaster.registerListener(allEvents, masterListener);
    var plugin =
        (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;
    SimpleEventListener pluginListener = SimpleEventListener('plugin');
    await plugin.registerListener(allEvents, pluginListener);

    //deregister Plugin
    await plugin.deregisterPlugin();

    List<Message> receivedEventsMaster = masterListener.getEvents();
    print(masterListener);
    expect(receivedEventsMaster.length, 4);
    Message rcvdMessage = receivedEventsMaster[1];
    expect(rcvdMessage.type, MessageType.ACTIVATE_PLUGIN);
    expect(rcvdMessage.sourceId, 'plugin1');
    expect(rcvdMessage.action, null);

    rcvdMessage = receivedEventsMaster[3];
    expect(rcvdMessage.type, MessageType.DEREGISTER_PLUGIN);
    expect(rcvdMessage.sourceId, 'plugin1');
    expect(rcvdMessage.action?.protocol, 'geiger');
    expect(rcvdMessage.action?.plugin, GeigerApi.MASTER_ID);
    expect(rcvdMessage.action?.path, 'deregisterPlugin');

    print(pluginListener);
    List<Message> receivedEventsPlugin = pluginListener.getEvents();
    expect(receivedEventsPlugin.length, 2);
    rcvdMessage = receivedEventsPlugin[0];
    expect(rcvdMessage.type, MessageType.COMAPI_SUCCESS);
    expect(rcvdMessage.sourceId, GeigerApi.MASTER_ID);
    expect(rcvdMessage.action?.protocol, 'geiger');
    expect(rcvdMessage.action?.plugin, 'plugin1');
    expect(rcvdMessage.action?.path, 'deactivatePlugin');
  });
  group('register Menu', () {
    test('check Master', () async {
      flushPluginCache();
      var localMaster = (await getGeigerApi(
          '', GeigerApi.MASTER_ID, Declaration.doNotShareData))!;
      SimpleEventListener masterListener = SimpleEventListener('master');
      List<MessageType> allEvents = [MessageType.ALL_EVENTS];
      await localMaster.registerListener(allEvents, masterListener);
      var plugin =
          (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;
      SimpleEventListener pluginListener = SimpleEventListener('plugin');
      await plugin.registerListener(allEvents, pluginListener);

      //register Menu
      await plugin.registerMenu(
          'testMenu', GeigerUrl(null, GeigerApi.MASTER_ID, 'testMenu'));

      List<Message> receivedEventsMaster = masterListener.getEvents();
      expect(receivedEventsMaster.length, 3);
      Message rcvdMessage = receivedEventsMaster[2];
      expect(rcvdMessage.type, MessageType.REGISTER_MENU);
      expect(rcvdMessage.sourceId, 'plugin1');
      expect(rcvdMessage.action?.protocol, 'geiger');
      expect(rcvdMessage.action?.plugin, GeigerApi.MASTER_ID);
      expect(rcvdMessage.action?.path, 'registerMenu');
      expect(
          await MenuItem.fromByteArray(rcvdMessage.payload),
          MenuItem(
              'testMenu', GeigerUrl(null, GeigerApi.MASTER_ID, 'testMenu')));

      List<Message> receivedEventsPlugin = pluginListener.getEvents();
      expect(receivedEventsPlugin.length, 1);
      rcvdMessage = receivedEventsPlugin[0];
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
      SimpleEventListener masterListener = SimpleEventListener('master');
      List<MessageType> allEvents = [MessageType.ALL_EVENTS];
      await localMaster.registerListener(allEvents, masterListener);
      var plugin =
          (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;
      SimpleEventListener pluginListener = SimpleEventListener('plugin');
      await plugin.registerListener(allEvents, pluginListener);

      //register and disable Menu
      await plugin.registerMenu(
          'testMenu', GeigerUrl(null, GeigerApi.MASTER_ID, 'testMenu'));
      await plugin.disableMenu('testMenu');

      List<Message> receivedEventsMaster = masterListener.getEvents();
      expect(receivedEventsMaster.length, 4);
      Message rcvdMessage = receivedEventsMaster[3];
      expect(rcvdMessage.type, MessageType.DISABLE_MENU);
      expect(rcvdMessage.sourceId, 'plugin1');
      expect(rcvdMessage.action?.protocol, 'geiger');
      expect(rcvdMessage.action?.plugin, GeigerApi.MASTER_ID);
      expect(rcvdMessage.action?.path, 'disableMenu');
      expect(rcvdMessage.payloadString, 'testMenu');

      List<Message> receivedEventsPlugin = pluginListener.getEvents();
      expect(receivedEventsPlugin.length, 2);
      rcvdMessage = receivedEventsPlugin[1];
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
      SimpleEventListener masterListener = SimpleEventListener('master');
      List<MessageType> allEvents = [MessageType.ALL_EVENTS];
      await localMaster.registerListener(allEvents, masterListener);
      var plugin =
          (await getGeigerApi('', 'plugin1', Declaration.doNotShareData))!;
      SimpleEventListener pluginListener = SimpleEventListener('plugin');
      await plugin.registerListener(allEvents, pluginListener);

      //register Menu
      await plugin.registerMenu(
          'testMenu', GeigerUrl(null, 'plugin1', 'testMenu'));
      await localMaster.menuPressed(GeigerUrl(null, 'plugin1', 'testMenu'));

      List<Message> receivedEventsMaster = masterListener.getEvents();
      expect(receivedEventsMaster.length, 3);
      Message rcvdMessage = receivedEventsMaster[2];
      expect(rcvdMessage.type, MessageType.REGISTER_MENU);
      expect(rcvdMessage.sourceId, 'plugin1');
      expect(rcvdMessage.action?.protocol, 'geiger');
      expect(rcvdMessage.action?.plugin, GeigerApi.MASTER_ID);
      expect(rcvdMessage.action?.path, 'registerMenu');
      //expect(GeigerUrl.fromByteArrayStream(ByteStream(null,rcvdMessage.payload)), GeigerUrl(null,'plugin1','testMenu'));

      List<Message> receivedEventsPlugin = pluginListener.getEvents();
      expect(receivedEventsPlugin.length, 2);
      rcvdMessage = receivedEventsPlugin[1];
      expect(rcvdMessage.type, MessageType.MENU_PRESSED);
      expect(rcvdMessage.sourceId, GeigerApi.MASTER_ID);
      expect(rcvdMessage.action?.protocol, 'geiger');
      expect(rcvdMessage.action?.plugin, 'plugin1');
      expect(rcvdMessage.action?.path, 'testMenu');

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

  String _id;

  SimpleEventListener(this._id);

  @override
  void pluginEvent(GeigerUrl? url, Message msg) {
    events.add(msg);
    print('## SimpleEventListener "$_id" received event ${msg.type} it currently has: ${events.length.toString()} events');
  }

  List<Message> getEvents() {
    return events;
  }

  @override
  String toString() {
    String ret ='';
    ret+='Eventlistener "$_id" contains {\r\n';
    getEvents().forEach((element) {ret+='  ${element.toString()}\r\n';});
    ret+='}\r\n';
    return ret;
  }
}
