library geiger_api;

import 'dart:convert';
import 'dart:io';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

import 'geiger_communicator.dart';
import 'menu_item.dart';
import 'plugin_communicator.dart';
import 'plugin_information.dart';
import 'plugin_listener.dart';
import 'plugin_starter.dart';
import 'storage_event_handler.dart';

enum Mapper {
  dummyMapper,
  sqliteMapper,
}

extension MapperExtension on Mapper {
  StorageMapper getMapper() {
    switch (this) {
      case Mapper.dummyMapper:
        return DummyMapper('anyUser');
      case Mapper.sqliteMapper:
        return SqliteMapper('./testdb');
    }
  }
}

/// Offers an API for all plugins to access the local toolbox.
class CommunicationApi implements GeigerApi {
  /// Creates a [CommunicationApi] with the given [executor] and plugin [_id].
  ///
  /// Whether this api [_isMaster] and its privacy [_declaration] must also be provided.
  CommunicationApi(
      String executor, String id, bool isMaster, Declaration declaration) {
    _executor = executor;
    _id = id;
    _isMaster = isMaster;
    _declaration = declaration;
    _geigerCommunicator = PluginCommunicator(this, _isMaster);

    restoreState();
    _geigerCommunicator.start();
  }

  static const bool persistent = false;

  static Mapper? _mapper;
  static const Mapper defaultMapper = Mapper.sqliteMapper;

  static final StorableHashMap<StorableString, PluginInformation> plugins =
      StorableHashMap();
  static final StorableHashMap<StorableString, MenuItem> menuItems =
      StorableHashMap();

  // static final Logger log = Logger.getLogger("GeigerApi");

  late String _executor;
  late String _id;
  late bool _isMaster;
  late Declaration _declaration;

  final Map<MessageType, List<PluginListener>> _listeners =
      <MessageType, List<PluginListener>>{};

  late GeigerCommunicator _geigerCommunicator;

  @override
  Future<void> initialize() async {
    if (!_isMaster) {
      try {
        // setup listener
        await registerPlugin();
        await activatePlugin(_geigerCommunicator.getPort());
      } on IOException {
        rethrow;
      }
      // TODO(mgwerder): should the passtroughcontroller be listener?
      //storageEventHandler = PasstroughController(this, _id);
      // this code is duplicate from registerListener method
      // it is currently not possible to determin between register internally and register on Master
      // therefore this duplicate is necessary
      //registerListener([MessageType.STORAGE_EVENT], storageEventHandler, true);
    } else {
      // it is master
      final StorageEventHandler storageEventHandler =
          StorageEventHandler(this, getStorage()!);
      await registerListener(
          <MessageType>[MessageType.storageEvent], storageEventHandler);
    }
  }

  set mapper(Mapper m) {
    if (_mapper == null) {
      _mapper = m;
    } else {
      throw StorageException('Mapper is already set');
    }
  }

  /// Returns the [Declaration] given upon creation.
  @override
  Declaration get declaration {
    return _declaration;
  }

  @override
  Future<void> registerPlugin([String? id, PluginInformation? info]) async {
    // TODO(mgwerder): share secret in a secure paired way....
    //PluginInformation pi = new PluginInformation();
    //CommunicationSecret secret = new CommunicationSecret();
    //secrets.put(id, secret);

    if (id != null) {
      if (info == null) {
        throw NullThrownError();
      }
      if (!plugins.containsKey(StorableString(id))) {
        plugins[StorableString(id)] = info;
        // ignore: avoid_print
        print(
            '## registered Plugin $id executable: ${info.getExecutable() ?? 'null'} port: ${info.getPort().toString()}');
      }
      return;
    }

    // request to register at Master
    final PluginInformation pluginInformation =
        PluginInformation(_executor, _geigerCommunicator.getPort());

    await sendMessage(Message(
        _id,
        GeigerApi.masterId,
        MessageType.registerPlugin,
        GeigerUrl(null, GeigerApi.masterId, 'registerPlugin'),
        await pluginInformation.toByteArray()));
  }

  @override
  Future<void> deregisterPlugin([String? id]) async {
    if (id != null) {
      // remove on master all menu items
      if (_isMaster) {
        final List<String> l = <String>[];
        for (final MapEntry<StorableString, MenuItem> i in menuItems.entries) {
          if (i.value.action.plugin == id) {
            l.add(i.key.toString());
          }
        }
        for (final String key in l) {
          menuItems.remove(StorableString(key));
        }
      }

      // remove plugin secret
      plugins.remove(StorableString(id));

      storeState();
      return;
    }

    // TODO(mgwerder): getting the id of the plugin itself doesnt make sense
    if (plugins[StorableString(_id)] == null) {
      throw ArgumentError('no communication secret found for id "$_id"');
    }
    // first deactivate, then deregister at Master, before deleting my own entries.
    await deactivatePlugin();

    await sendMessage(Message(
        _id,
        GeigerApi.masterId,
        MessageType.deregisterPlugin,
        GeigerUrl(null, GeigerApi.masterId, 'deregisterPlugin')));

    zapState();
  }

  /// Deletes all current registered items.
  void zapState() {
    menuItems.clear();
    plugins.clear();
    storeState();
  }

  Future<void> storeState() async {
    // store plugin state
    try {
      final ByteSink out = ByteSink();
      plugins.toByteArrayStream(out);
      menuItems.toByteArrayStream(out);
      out.close();
      final IOSink file = File('GeigerApi.$_id.state').openWrite();
      file.add(await out.bytes);
      file.close();
    } catch (ioe) {
      // FIXME
      //System.out.println("===============================================U");
      //ioe.printStackTrace();
      //System.out.println("===============================================L");
    }
  }

  Future<void> restoreState() async {
    try {
      final File file = File('GeigerApi.$_id.state');
      final List<int> buff =
          await file.exists() ? await file.readAsBytes() : [];
      final ByteStream in_ = ByteStream(null, buff);
      // restoring plugin information
      await StorableHashMap.fromByteArrayStream(in_, plugins);

      // restoring menu information
      await StorableHashMap.fromByteArrayStream(in_, menuItems);
    } catch (e) {
      storeState();
    }
  }

  @override
  Future<void> activatePlugin(int port) async {
    await sendMessage(Message(
        _id,
        GeigerApi.masterId,
        MessageType.activatePlugin,
        null,
        SerializerHelper.intToByteArray(port)));
  }

  @override
  Future<void> deactivatePlugin() async {
    await sendMessage(
        Message(_id, GeigerApi.masterId, MessageType.deactivatePlugin, null));
  }

  /// Obtain [StorageController] to access the storage.
  @override
  StorageController? getStorage() {
    _mapper ??= defaultMapper;
    if (_isMaster) {
      return GenericController(_id, _mapper!.getMapper());
    } else {
      // local only
      return GenericController(_id, _mapper!.getMapper());
      // TODO: Add support for remote storage
      //return PasstroughController(this, _id);
    }
  }

  @override
  Future<void> registerListener(
      List<MessageType> events, PluginListener listener) async {
    events.where((event) => event.id < 10000).map((event) {
      var listeners = _listeners[event];
      if (listeners == null) {
        listeners = [];
        _listeners[event] = listeners;
      }
      return listeners;
    }).forEach((listeners) => listeners.add(listener));
  }

  @override
  void deregisterListener(List<MessageType>? events, PluginListener listener) {
    for (var event in (events ?? MessageType.getAllValues())) {
      _listeners[event]?.remove(listener);
    }
  }

  @override
  Future<void> sendMessage(Message msg, [String? pluginId]) async {
    pluginId ??= msg.targetId;
    if (_id == pluginId) {
      // Message to this plugin
      await receivedMessage(
          plugins[StorableString(_id)] ?? PluginInformation(null, 0), msg);
    } else if (instances[pluginId] != null) {
      // Message to plugin in same isolate
      // ignore: avoid_print
      print('## Sending message to internal plugin $pluginId ($msg)');
      // TODO: refactor so this cast is no longer needed
      await (instances[pluginId] as CommunicationApi)
          .receivedMessage(PluginInformation(null, 0), msg);
    } else {
      // Message to external plugin
      PluginInformation pluginInfo =
          plugins[StorableString(pluginId)] ?? PluginInformation(null, 0);
      if (_isMaster) {
        // Check if plugin active by checking for a port greater than 0
        if (!(pluginInfo.getPort() > 0)) {
          // is inactive -> start plugin
          _geigerCommunicator.startPlugin(pluginInfo);
        }
      }
      // TODO(mgwerder): short circuited delivery as no external delivery is supported
      //await _geigerCommunicator.sendMessage(pluginInformation, msg);
    }
  }

  /// Broadcasts a [message] to all known plugins.
  Future<void> broadcastMessage(Message message) async {
    for (var plugin in plugins.entries) {
      await sendMessage(Message(GeigerApi.masterId, plugin.key.toString(),
          message.type, message.action, message.payload));
    }
  }

  Future<void> receivedMessage(PluginInformation info, Message msg) async {
    // TODO(mgwerder): other messagetypes
    // ignore: avoid_print
    print('## got message in plugin $_id => $msg');
    switch (msg.type) {
      case MessageType.enableMenu:
        var item = menuItems[StorableString(msg.payloadString)];
        if (item != null) {
          item.enabled = true;
        }
        await sendMessage(Message(_id, msg.sourceId, MessageType.comapiSuccess,
            GeigerUrl(null, msg.sourceId, 'enableMenu')));
        break;
      case MessageType.disableMenu:
        var item = menuItems[StorableString(msg.payloadString)];
        if (item != null) {
          item.enabled = false;
        }
        await sendMessage(Message(_id, msg.sourceId, MessageType.comapiSuccess,
            GeigerUrl(null, msg.sourceId, 'disableMenu')));
        break;
      case MessageType.registerMenu:
        var item =
            await MenuItem.fromByteArrayStream(ByteStream(null, msg.payload));
        menuItems[StorableString(item.menu)] = item;
        await sendMessage(Message(_id, msg.sourceId, MessageType.comapiSuccess,
            GeigerUrl(null, msg.sourceId, 'registerMenu')));
        break;
      case MessageType.deregisterMenu:
        var menuString = utf8.fuse(base64).decode(msg.payloadString.toString());
        menuItems.remove(StorableString(menuString));
        await sendMessage(Message(_id, msg.sourceId, MessageType.comapiSuccess,
            GeigerUrl(null, msg.sourceId, 'deregisterMenu')));
        break;
      case MessageType.registerPlugin:
        await registerPlugin(
            msg.sourceId, await PluginInformation.fromByteArray(msg.payload));
        await sendMessage(Message(_id, msg.sourceId, MessageType.comapiSuccess,
            GeigerUrl(null, msg.sourceId, 'registerPlugin')));
        break;
      case MessageType.deregisterPlugin:
        await deregisterPlugin(msg.sourceId);
        await sendMessage(Message(_id, msg.sourceId, MessageType.comapiSuccess,
            GeigerUrl(null, msg.sourceId, 'deregisterPlugin')));
        break;
      case MessageType.activatePlugin:
        {
          // get and remove old info
          final PluginInformation pluginInfo =
              plugins[StorableString(msg.sourceId)]!;
          plugins.remove(StorableString(msg.sourceId));
          // put new info
          int port = SerializerHelper.byteArrayToInt(msg.payload);
          plugins[StorableString(msg.sourceId)] =
              PluginInformation(pluginInfo.getExecutable(), port);
          await sendMessage(Message(
              _id,
              msg.sourceId,
              MessageType.comapiSuccess,
              GeigerUrl(null, msg.sourceId, 'activatePlugin')));
          break;
        }
      case MessageType.deactivatePlugin:
        {
          // remove port from plugin info
          // get and remove old info
          var pluginInfo = plugins[StorableString(msg.sourceId)]!;
          plugins.remove(StorableString(msg.sourceId));
          // put new info
          plugins[StorableString(msg.sourceId)] =
              PluginInformation(pluginInfo.getExecutable(), 0);
          await sendMessage(Message(
              _id,
              msg.sourceId,
              MessageType.comapiSuccess,
              GeigerUrl(null, msg.sourceId, 'deactivatePlugin')));
          break;
        }
      case MessageType.registerListener:
        {
          // TODO(mgwerder): after pluginListener serialization
          ByteStream in_ = ByteStream(null, msg.payload);
          int length = await SerializerHelper.readInt(in_);
          List<MessageType> events = [
            for (var i = 0; i < length; ++i)
              MessageType.getById(await SerializerHelper.readInt(in_))!
          ];
          // TODO(mgwerder): deserialize Pluginlistener... WTF... this is most likely incorrect
          PluginListener? listener;
          for (var event in events) {
            // synchronized(listeners) {
            var listeners = _listeners[event];
            // short form with computeIfAbsent is not available in TotalCross
            if (listeners == null) {
              listeners = [];
              _listeners[event] = listeners;
            }
            if (event.id < 10000 && listener != null) {
              listeners.add(listener);
            }
            // }
          }
          break;
        }
      case MessageType.deregisterListener:
        {
          // TODO after PluginListener serialization
          // remove listener from list if it is in list
          break;
        }
      case MessageType.scanPressed:
        if (_isMaster) {
          await scanButtonPressed();
        }
        // if its not the Master there should be a listener registered for this event
        break;
      case MessageType.ping:
        {
          // answer with PONG
          await sendMessage(Message(_id, msg.sourceId, MessageType.pong,
              GeigerUrl(null, msg.sourceId, ''), msg.payload));
          break;
        }
      default:
        // all other messages are not handled internally
        break;
    }
    for (var mt in [MessageType.allEvents, msg.type]) {
      var l = _listeners[mt];
      if (l != null) {
        for (var pl in l) {
          // ignore: avoid_print
          print(
              '## notifying PluginListener ${pl.toString()} for msg ${msg.type.toString()} ${msg.action.toString()}');
          pl.pluginEvent(msg.action, msg);

          // ignore: avoid_print
          print('## PluginEvent fired');
        }
      }
    }
  }

  @override
  Future<void> registerMenu(String menu, GeigerUrl action) async {
    await sendMessage(Message(
        _id,
        GeigerApi.masterId,
        MessageType.registerMenu,
        GeigerUrl(null, GeigerApi.masterId, 'registerMenu'),
        await MenuItem(menu, action).toByteArray()));
  }

  @override
  Future<void> enableMenu(String menu) async {
    await sendMessage(Message(_id, GeigerApi.masterId, MessageType.enableMenu,
        GeigerUrl(null, GeigerApi.masterId, 'enableMenu'), utf8.encode(menu)));
  }

  @override
  Future<void> disableMenu(String menu) async {
    Message msg = Message(
      _id,
      GeigerApi.masterId,
      MessageType.disableMenu,
      GeigerUrl(null, GeigerApi.masterId, 'disableMenu'),
    );
    msg.payloadString = menu;
    await sendMessage(msg);
  }

  @override
  Future<void> deregisterMenu(String menu) async {
    await sendMessage(Message(
        _id,
        GeigerApi.masterId,
        MessageType.deregisterMenu,
        GeigerUrl(null, GeigerApi.masterId, 'deregisterMenu'),
        utf8.encode(menu)));
  }

  @override
  Future<void> menuPressed(GeigerUrl url) async {
    await sendMessage(Message(
        GeigerApi.masterId, url.plugin, MessageType.menuPressed, url, null));
  }

  @override
  List<MenuItem> getMenuList() {
    return menuItems.values.toList();
  }

  @override
  Future<void> scanButtonPressed() async {
    // TODO
    if (!_isMaster) {
      await sendMessage(Message(
          _id,
          GeigerApi.masterId,
          MessageType.scanPressed,
          GeigerUrl(null, GeigerApi.masterId, 'scanPressed')));
    } else {
      await broadcastMessage(
          Message(GeigerApi.masterId, null, MessageType.scanPressed, null));
    }
  }

  /// Start a plugin of [pluginInformation] by using the stored executable String.
  void startPlugin(PluginInformation pluginInformation) {
    PluginStarter.startPlugin(pluginInformation);
  }
}
