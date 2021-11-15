library geiger_api;

import 'dart:convert';
import 'dart:io';

import 'package:communicationapi/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

import 'declaration.dart';
import 'geiger_api.dart';
import 'geiger_communicator.dart';
import 'geiger_url.dart';
import 'malformed_url_exception.dart';
import 'menu_item.dart';
import 'message.dart';
import 'message_type.dart';
import 'plugin_communicator.dart';
import 'plugin_information.dart';
import 'plugin_listener.dart';
import 'plugin_starter.dart';
import 'storable_hash_map.dart';
import 'storable_string.dart';
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
      StorableHashMap<StorableString, PluginInformation>();
  static final StorableHashMap<StorableString, MenuItem> menuItems =
      StorableHashMap<StorableString, MenuItem>();

  // static final Logger log = Logger.getLogger("GeigerApi");

  late String _executor;
  late String _id;
  late bool _isMaster;
  late Declaration _declaration;

  final Map<MessageType, List<PluginListener>> _listeners =
      <MessageType, List<PluginListener>>{};

  late GeigerCommunicator _geigerCommunicator;

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
          <MessageType>[MessageType.STORAGE_EVENT], storageEventHandler);
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

    try {
      await sendMessage(
          GeigerApi.MASTER_ID,
          Message(
              _id,
              GeigerApi.MASTER_ID,
              MessageType.REGISTER_PLUGIN,
              GeigerUrl(null, GeigerApi.MASTER_ID, 'registerPlugin'),
              await pluginInformation.toByteArray()));
    } on MalformedUrlException {
      // TODO(mgwerder): proper Error handling
      // this should never occur
    }
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
    try {
      await sendMessage(
          GeigerApi.MASTER_ID,
          Message(_id, GeigerApi.MASTER_ID, MessageType.DEREGISTER_PLUGIN,
              GeigerUrl(null, GeigerApi.MASTER_ID, 'deregisterPlugin')));
    } on MalformedUrlException {
      // TODO(mgwerder): proper Error handling
      // this should never occur
    }
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
      final File f = File('GeigerApi.$_id.state');
      final ByteSink out = ByteSink();
      plugins.toByteArrayStream(out);
      menuItems.toByteArrayStream(out);
      out.close();
      final IOSink file = f.openWrite();
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
    final String fname = 'GeigerApi.$_id.state';
    try {
      final File file = File(fname);
      final List<int> buff =
          file.existsSync() ? file.readAsBytesSync() : <int>[];
      final ByteStream in_ = ByteStream(null, buff);
      // restoring plugin information
      // synchronized(plugins) {
      await StorableHashMap.fromByteArrayStream(in_, plugins);
      // }

      // restoring menu information
      // synchronized(menuItems) {
      await StorableHashMap.fromByteArrayStream(in_, menuItems);
      // }
    } catch (e) {
      storeState();
    }
  }

  @override
  Future<void> activatePlugin(int port) async {
    await sendMessage(
        GeigerApi.MASTER_ID,
        Message(_id, GeigerApi.MASTER_ID, MessageType.ACTIVATE_PLUGIN, null,
            SerializerHelper.intToByteArray(port)));
  }

  @override
  Future<void> deactivatePlugin() async {
    await sendMessage(GeigerApi.MASTER_ID,
        Message(_id, GeigerApi.MASTER_ID, MessageType.DEACTIVATE_PLUGIN, null));
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
      List<MessageType> events, PluginListener listener,
      [bool internal = false]) async {
    if (internal) {
      for (final MessageType e in events) {
        // synchronized(listeners) {
        List<PluginListener>? l = _listeners[e];
        // The short form computeIfAbsent is not available in TotalCross
        if (l == null) {
          l = <PluginListener>[];
          _listeners[e] = l;
        }
        if (e.id < 10000) {
          l.add(listener);
        }
        // }
      }
      return;
    }
    if (_isMaster) {
      for (final MessageType e in events) {
        // synchronized(listeners) {
        List<PluginListener>? l = _listeners[e];
        // The short form computeIfAbsent is not available in TotalCross
        if (l == null) {
          l = <PluginListener>[];
          _listeners[e] = l;
        }
        if (e.id < 10000) {
          l.add(listener);
        }
        // }
      }
    } else {
      try {
        // formating int number of events -> events -> listener
        final ByteSink out = ByteSink();
        out.sink.add(SerializerHelper.intToByteArray(events.length));
        for (final MessageType event in events) {
          out.sink.add(SerializerHelper.intToByteArray(event.id));
        }
        // out.write(listener.toByteArray());
        await sendMessage(
            GeigerApi.MASTER_ID,
            Message(
                _id,
                GeigerApi.MASTER_ID,
                MessageType.REGISTER_LISTENER,
                GeigerUrl(null, GeigerApi.MASTER_ID, 'registerListener'),
                await out.bytes));
      } on IOException {
        // TODO(mgwerder): proper Error handling
        // this should never occur
      }
    }
  }

  @override
  void deregisterListener(List<MessageType>? events, PluginListener listener) {
    events ??= MessageType.getAllValues();
    for (final MessageType e in events) {
      // synchronized(listeners) {
      final List<PluginListener>? l = _listeners[e];
      if (l != null) {
        l.remove(listener);
      }
      // }
    }
  }

  @override
  Future<void> sendMessage(String pluginId, Message msg) async {
    if (_id == pluginId) {
      // communicate locally
      PluginInformation initplugin = PluginInformation(null, 0);
      if (plugins[StorableString(_id)] != null) {
        initplugin = plugins[StorableString(_id)]!;
      }
      await receivedMessage(initplugin, msg);
    } else {
      // communicate with foreign plugin
      PluginInformation pluginInformation =
          plugins[StorableString(pluginId)] ?? PluginInformation(null, 0);
      if (_isMaster) {
        // Check if plugin active by checking for a port greater than 0
        if (!(pluginInformation.getPort() > 0)) {
          // is inactive -> start plugin
          _geigerCommunicator.startPlugin(pluginInformation);
        }
      }
      // TODO(mgwerder): short circuited delivery as no external delivery is supported
      //await _geigerCommunicator.sendMessage(pluginInformation, msg);
      await (instances[pluginId] as CommunicationApi)
          .receivedMessage(pluginInformation, msg);
    }
  }

  /// Broadcasts a [message] to all known plugins.
  Future<void> broadcastMessage(Message message) async {
    for (var plugin in plugins.entries) {
      await sendMessage(
          plugin.key.toString(),
          Message(GeigerApi.MASTER_ID, plugin.key.toString(), message.type,
              message.action, message.payload));
    }
  }

  Future<void> receivedMessage(PluginInformation info, Message msg) async {
    // TODO(mgwerder): other messagetypes
    MenuItem? i;
    switch (msg.type) {
      case MessageType.ENABLE_MENU:
        i = menuItems[StorableString(msg.payloadString)];
        if (i != null) {
          i.enabled = true;
        }
        try {
          await sendMessage(
              msg.sourceId,
              Message(msg.targetId!, msg.sourceId, MessageType.COMAPI_SUCCESS,
                  GeigerUrl(null, msg.sourceId, 'enableMenu')));
        } on MalformedUrlException {
          // TODO(mgwerder): proper Error handling
          // this should never occur
        }
        break;
      case MessageType.DISABLE_MENU:
        i = menuItems[StorableString(msg.payloadString)];
        if (i != null) {
          i.enabled = false;
        }
        try {
          await sendMessage(
              msg.sourceId,
              Message(msg.targetId!, msg.sourceId, MessageType.COMAPI_SUCCESS,
                  GeigerUrl(null, msg.sourceId, 'disableMenu')));
        } on MalformedUrlException {
          // TODO(mgwerder): proper Error handling
          // this should never occur
        }
        break;
      case MessageType.REGISTER_MENU:
        i = await MenuItem.fromByteArrayStream(ByteStream(null, msg.payload));
        menuItems[StorableString(i.menu)] = i;
        try {
          await sendMessage(
              msg.sourceId,
              Message(msg.targetId!, msg.sourceId, MessageType.COMAPI_SUCCESS,
                  GeigerUrl(null, msg.sourceId, 'registerMenu')));
        } on MalformedUrlException {
          // TODO(mgwerder): proper Error handling
          // this should never occur
        }
        break;
      case MessageType.DEREGISTER_MENU:
        var menuString = utf8.fuse(base64).decode(msg.payloadString.toString());
        menuItems.remove(StorableString(menuString));
        try {
          await sendMessage(
              msg.sourceId,
              Message(msg.targetId!, msg.sourceId, MessageType.COMAPI_SUCCESS,
                  GeigerUrl(null, msg.sourceId, 'deregisterMenu')));
        } on MalformedUrlException {
          // TODO(mgwerder): proper Error handling
          // this should never occur
        }
        break;
      case MessageType.REGISTER_PLUGIN:
        await registerPlugin(
            msg.sourceId, await PluginInformation.fromByteArray(msg.payload));
        try {
          await sendMessage(
              msg.sourceId,
              Message(msg.targetId!, msg.sourceId, MessageType.COMAPI_SUCCESS,
                  GeigerUrl(null, msg.sourceId, 'registerPlugin')));
        } on MalformedUrlException {
          // TODO(mgwerder): proper Error handling
          // this should never occur
        }
        break;
      case MessageType.DEREGISTER_PLUGIN:
        await deregisterPlugin(msg.sourceId);
        try {
          await sendMessage(
              msg.sourceId,
              Message(msg.targetId!, msg.sourceId, MessageType.COMAPI_SUCCESS,
                  GeigerUrl(null, msg.sourceId, 'deregisterPlugin')));
        } on MalformedUrlException {
          // TODO(mgwerder): proper Error handling
          // this should never occur
        }
        break;
      case MessageType.ACTIVATE_PLUGIN:
        {
          // get and remove old info
          final PluginInformation pluginInfo =
              plugins[StorableString(msg.sourceId)]!;
          plugins.remove(StorableString(msg.sourceId));
          // put new info
          int port = SerializerHelper.byteArrayToInt(msg.payload);
          plugins[StorableString(msg.sourceId)] =
              PluginInformation(pluginInfo.getExecutable(), port);
          try {
            await sendMessage(
                msg.sourceId,
                Message(msg.targetId!, msg.sourceId, MessageType.COMAPI_SUCCESS,
                    GeigerUrl(null, msg.sourceId, 'activatePlugin')));
          } on MalformedUrlException {
            // TODO(mgwerder): proper Error handling
            // this should never occur
          }
          break;
        }
      case MessageType.DEACTIVATE_PLUGIN:
        {
          // remove port from plugin info
          // get and remove old info
          var pluginInfo = plugins[StorableString(msg.sourceId)]!;
          plugins.remove(StorableString(msg.sourceId));
          // put new info
          plugins[StorableString(msg.sourceId)] =
              PluginInformation(pluginInfo.getExecutable(), 0);
          try {
            await sendMessage(
                msg.sourceId,
                Message(msg.targetId!, msg.sourceId, MessageType.COMAPI_SUCCESS,
                    GeigerUrl(null, msg.sourceId, 'deactivatePlugin')));
          } on MalformedUrlException {
            // TODO(mgwerder): proper Error handling
            // this should never occur
          }
          break;
        }
      case MessageType.REGISTER_LISTENER:
        {
          // TODO(mgwerder): after pluginListener serialization
          List<int> payload = msg.payload;
          ByteStream in_ = ByteStream(null, payload);
          int length = await SerializerHelper.readInt(in_);
          // workaround, register for all events always until messagetype serialization is available
          //List<MessageType> events = [MessageType.ALL_EVENTS];
          List<MessageType> events = <MessageType>[];
          for (var j = 0; j < length; ++j) {
            events
                .add(MessageType.getById(await SerializerHelper.readInt(in_))!);
          }
          // TODO(mgwerder): deserialize Pluginlistener... WTF... this is most likely incorrect
          PluginListener? listener;
          for (var e in events) {
            // synchronized(listeners) {
            var l = _listeners[e];
            // short form with computeIfAbsent is not available in TotalCross
            if (l == null) {
              l = List.empty(growable: true);
              _listeners[e] = l;
            }
            if (e.id < 10000) {
              l.add(listener!);
            }
            // }
          }
          break;
        }
      case MessageType.DEREGISTER_LISTENER:
        {
          // TODO after PluginListener serialization
          // remove listener from list if it is in list
          break;
        }
      case MessageType.SCAN_PRESSED:
        if (_isMaster) {
          await scanButtonPressed();
        }
        // if its not the Master there should be a listener registered for this event
        break;
      case MessageType.PING:
        {
          // answer with PONG
          try {
            await sendMessage(
                msg.sourceId,
                Message(msg.targetId!, msg.sourceId, MessageType.PONG,
                    GeigerUrl(null, msg.sourceId, ''), msg.payload));
          } on MalformedUrlException {
            // TODO(mgwerder): proper Error handling
            // this should never occur
          }
          break;
        }
      default:
        // all other messages are not handled internally
        break;
    }
    for (var mt in [MessageType.ALL_EVENTS, msg.type]) {
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
    try {
      await sendMessage(
          GeigerApi.MASTER_ID,
          Message(
              _id,
              GeigerApi.MASTER_ID,
              MessageType.REGISTER_MENU,
              GeigerUrl(null, GeigerApi.MASTER_ID, 'registerMenu'),
              await MenuItem(menu, action).toByteArray()));
    } on MalformedUrlException {
      // TODO(mgwerder): proper Error handling
      // this should never occur
    }
  }

  @override
  Future<void> enableMenu(String menu) async {
    try {
      await sendMessage(
          GeigerApi.MASTER_ID,
          Message(
              _id,
              GeigerApi.MASTER_ID,
              MessageType.ENABLE_MENU,
              GeigerUrl(null, GeigerApi.MASTER_ID, 'enableMenu'),
              utf8.encode(menu)));
    } on MalformedUrlException {
      // TODO(mgwerder): proper Error handling
      // this should never occur
    }
  }

  @override
  Future<void> disableMenu(String menu) async {
    try {
      await sendMessage(
          GeigerApi.MASTER_ID,
          Message(
              _id,
              GeigerApi.MASTER_ID,
              MessageType.DISABLE_MENU,
              GeigerUrl(null, GeigerApi.MASTER_ID, 'disableMenu'),
              utf8.encode(menu)));
    } on MalformedUrlException {
      // TODO(mgwerder): proper Error handling
      // this should never occur
    }
  }

  @override
  Future<void> deregisterMenu(String menu) async {
    try {
      await sendMessage(
          GeigerApi.MASTER_ID,
          Message(
              _id,
              GeigerApi.MASTER_ID,
              MessageType.DEREGISTER_MENU,
              GeigerUrl(null, GeigerApi.MASTER_ID, 'deregisterMenu'),
              utf8.encode(menu)));
    } on MalformedUrlException {
      // TODO(mgwerder): proper Error handling
      // this should never occur
    }
  }

  @override
  Future<void> menuPressed(GeigerUrl url) async {
    await sendMessage(
        url.plugin,
        Message(GeigerApi.MASTER_ID, url.plugin, MessageType.MENU_PRESSED, url,
            null));
  }

  @override
  List<MenuItem> getMenuList() {
    return menuItems.values.toList();
  }

  @override
  Future<void> scanButtonPressed() async {
    // TODO
    if (!_isMaster) {
      try {
        await sendMessage(
            GeigerApi.MASTER_ID,
            Message(_id, GeigerApi.MASTER_ID, MessageType.SCAN_PRESSED,
                GeigerUrl(null, GeigerApi.MASTER_ID, 'scanPressed')));
      } on MalformedUrlException {
        // TODO(mgwerder): proper Error handling
        // this should never occur
      }
    } else {
      await broadcastMessage(
          Message(GeigerApi.MASTER_ID, null, MessageType.SCAN_PRESSED, null));
    }
  }

  /// Start a plugin of [pluginInformation] by using the stored executable String.
  void startPlugin(PluginInformation pluginInformation) {
    PluginStarter.startPlugin(pluginInformation);
  }
}
