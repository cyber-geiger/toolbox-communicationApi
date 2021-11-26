library geiger_api;

import 'dart:convert';
import 'dart:io';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:logging/logging.dart';

import 'geiger_communicator.dart';
import 'menu_item.dart';
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
    StorageMapper ret;
    switch (this) {
      case Mapper.dummyMapper:
        ret = DummyMapper('anyUser');
        break;
      case Mapper.sqliteMapper:
        ret = SqliteMapper('database');
        break;
    }
    return ret;
  }
}

/// Offers an API for all plugins to access the local toolbox.
class CommunicationApi implements GeigerApi {
  /// Creates a [CommunicationApi] with the given [executor] and plugin [id].
  ///
  /// Whether this api [isMaster] and its privacy [_declaration] must also be provided.
  CommunicationApi(
      String executor, this.id, this.isMaster, Declaration declaration) {
    _executor = executor;
    _declaration = declaration;
    _geigerCommunicator = GeigerCommunicator(this);

    restoreState();
  }

  static const bool persistent = false;

  static final Logger _logger = Logger('GeigerAPI');

  static Mapper? _mapper;
  static const Mapper defaultMapper = Mapper.sqliteMapper;

  static final StorableHashMap<StorableString, PluginInformation> plugins =
      StorableHashMap();
  static final StorableHashMap<StorableString, MenuItem> menuItems =
      StorableHashMap();

  static final Logger log = Logger("GeigerApi");

  late String _executor;
  final String id;
  late final bool isMaster;
  late Declaration _declaration;

  final Map<MessageType, List<PluginListener>> _listeners =
      <MessageType, List<PluginListener>>{};

  late GeigerCommunicator _geigerCommunicator;

  @override
  Future<void> initialize() async {
    await _geigerCommunicator.start();
    await StorageMapper.initDatabaseExpander();
    if (!isMaster) {
      try {
        // setup listener
        await registerPlugin();
        await activatePlugin(_geigerCommunicator.port);
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
  Future<void> registerPlugin(
      [String? pluginId, PluginInformation? info]) async {
    // TODO(mgwerder): share secret in a secure paired way....
    //PluginInformation pi = new PluginInformation();
    //CommunicationSecret secret = new CommunicationSecret();
    //secrets.put(id, secret);

    if (pluginId != null) {
      if (info == null) {
        throw NullThrownError();
      }
      if (!plugins.containsKey(StorableString(id))) {
        plugins[StorableString(id)] = info;
        _logger.info(
            'registered Plugin $id executable: ${info.getExecutable() ?? 'null'} port: ${info.getPort().toString()}');
      }
      return;
    }

    // request to register at Master
    final PluginInformation pluginInformation =
        PluginInformation(_executor, _geigerCommunicator.port);

    await sendMessage(Message(
        id,
        GeigerApi.masterId,
        MessageType.registerPlugin,
        GeigerUrl(null, GeigerApi.masterId, 'registerPlugin'),
        await pluginInformation.toByteArray()));
  }

  @override
  Future<void> deregisterPlugin([String? pluginId]) async {
    if (pluginId != null) {
      // remove on master all menu items
      if (isMaster) {
        final List<String> l = <String>[];
        for (final MapEntry<StorableString, MenuItem> i in menuItems.entries) {
          if (i.value.action.plugin == pluginId) {
            l.add(i.key.toString());
          }
        }
        for (final String key in l) {
          menuItems.remove(StorableString(key));
        }
      }

      // remove plugin secret
      plugins.remove(StorableString(pluginId));

      storeState();
      return;
    }

    // TODO(mgwerder): getting the id of the plugin itself doesnt make sense
    if (plugins[StorableString(id)] == null) {
      throw ArgumentError('no communication secret found for id "$id"');
    }
    // first deactivate, then deregister at Master, before deleting my own entries.
    await deactivatePlugin();
    await sendMessage(Message(
        id,
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
      final IOSink file = File('GeigerApi.$id.state').openWrite();
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
      final File file = File('GeigerApi.$id.state');
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
    await sendMessage(
      Message(id, GeigerApi.masterId, MessageType.activatePlugin, null,
          SerializerHelper.intToByteArray(port)),
    );
  }

  @override
  Future<void> deactivatePlugin() async {
    await sendMessage(
        Message(id, GeigerApi.masterId, MessageType.deactivatePlugin, null));
  }

  /// Obtain [StorageController] to access the storage.
  @override
  StorageController? getStorage() {
    _mapper ??= defaultMapper;
    StorageController? ret;
    if (isMaster) {
      ret = GenericController(id, _mapper!.getMapper());
    } else {
      // local only
      ret = GenericController(id, _mapper!.getMapper());
      // TODO: Add support for remote storage
      //return PasstroughController(this, _id);
    }
    ExtendedTimestamp.initializeTimestamp(ret);
    return ret;
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
    if (id == pluginId) {
      // Message to this plugin
      await receivedMessage(msg);
    } else {
      print('## Sending message to plugin $pluginId ($msg)');
      // Message to external plugin
      PluginInformation pluginInfo = plugins[StorableString(pluginId)] ??
          PluginInformation(
              null,
              pluginId == GeigerApi.masterId
                  ? GeigerCommunicator.masterPort
                  : 0);
      if (isMaster) {
        // Check if plugin active by checking for a port greater than 0
        if (!(pluginInfo.getPort() > 0)) {
          // is inactive -> start plugin
          // TODO: add plugin startup
          throw UnimplementedError();
          // _geigerCommunicator.startPlugin(pluginInfo);
        }
      }
      await _geigerCommunicator.sendMessage(pluginInfo.port, msg);
    }
  }

  /// Broadcasts a [message] to all known plugins.
  Future<void> broadcastMessage(Message message) async {
    for (var plugin in plugins.entries) {
      await sendMessage(Message(GeigerApi.masterId, plugin.key.toString(),
          message.type, message.action, message.payload));
    }
  }

  Future<void> receivedMessage(Message msg) async {
    // TODO(mgwerder): other messagetypes
    _logger.info('## got message in plugin $id => $msg');
    switch (msg.type) {
      case MessageType.enableMenu:
        var item = menuItems[StorableString(msg.payloadString)];
        if (item != null) {
          item.enabled = true;
        }
        await sendMessage(Message(id, msg.sourceId, MessageType.comapiSuccess,
            GeigerUrl(null, msg.sourceId, 'enableMenu'), null, msg.requestId));
        break;
      case MessageType.disableMenu:
        var item = menuItems[StorableString(msg.payloadString)];
        if (item != null) {
          item.enabled = false;
        }
        await sendMessage(Message(id, msg.sourceId, MessageType.comapiSuccess,
            GeigerUrl(null, msg.sourceId, 'disableMenu'), null, msg.requestId));
        break;
      case MessageType.registerMenu:
        var item =
            await MenuItem.fromByteArrayStream(ByteStream(null, msg.payload));
        menuItems[StorableString(item.menu)] = item;
        await sendMessage(Message(
            id,
            msg.sourceId,
            MessageType.comapiSuccess,
            GeigerUrl(null, msg.sourceId, 'registerMenu'),
            null,
            msg.requestId));
        break;
      case MessageType.deregisterMenu:
        var menuString = utf8.fuse(base64).decode(msg.payloadString.toString());
        menuItems.remove(StorableString(menuString));
        await sendMessage(Message(
            id,
            msg.sourceId,
            MessageType.comapiSuccess,
            GeigerUrl(null, msg.sourceId, 'deregisterMenu'),
            null,
            msg.requestId));
        break;
      case MessageType.registerPlugin:
        await registerPlugin(
            msg.sourceId, await PluginInformation.fromByteArray(msg.payload));
        await sendMessage(Message(
            id,
            msg.sourceId,
            MessageType.comapiSuccess,
            GeigerUrl(null, msg.sourceId, 'registerPlugin'),
            null,
            msg.requestId));
        break;
      case MessageType.deregisterPlugin:
        await deregisterPlugin(msg.sourceId);
        await sendMessage(Message(
            id,
            msg.sourceId,
            MessageType.comapiSuccess,
            GeigerUrl(null, msg.sourceId, 'deregisterPlugin'),
            null,
            msg.requestId));
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
              id,
              msg.sourceId,
              MessageType.comapiSuccess,
              GeigerUrl(null, msg.sourceId, 'activatePlugin'),
              null,
              msg.requestId));
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
              id,
              msg.sourceId,
              MessageType.comapiSuccess,
              GeigerUrl(null, msg.sourceId, 'deactivatePlugin'),
              null,
              msg.requestId));
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
        if (isMaster) {
          await scanButtonPressed();
        }
        // if its not the Master there should be a listener registered for this event
        break;
      case MessageType.ping:
        {
          // answer with PONG
          await sendMessage(Message(id, msg.sourceId, MessageType.pong,
              GeigerUrl(null, msg.sourceId, ''), msg.payload, msg.requestId));
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
        id,
        GeigerApi.masterId,
        MessageType.registerMenu,
        GeigerUrl(null, GeigerApi.masterId, 'registerMenu'),
        await MenuItem(menu, action).toByteArray()));
  }

  @override
  Future<void> enableMenu(String menu) async {
    await sendMessage(Message(id, GeigerApi.masterId, MessageType.enableMenu,
        GeigerUrl(null, GeigerApi.masterId, 'enableMenu'), utf8.encode(menu)));
  }

  @override
  Future<void> disableMenu(String menu) async {
    Message msg = Message(
      id,
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
        id,
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
    if (!isMaster) {
      await sendMessage(Message(id, GeigerApi.masterId, MessageType.scanPressed,
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

  @override
  Future<void> close() async {
    await _geigerCommunicator.close();
  }
}
