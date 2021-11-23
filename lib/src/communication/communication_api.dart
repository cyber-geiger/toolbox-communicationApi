library geiger_api;

import 'dart:convert';
import 'dart:io';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:logging/logging.dart';

import 'geiger_communicator.dart';
import 'malformed_url_exception.dart';
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

  static final Logger _logger = Logger('GeigerAPI');

  static Mapper? _mapper;
  static const Mapper defaultMapper = Mapper.sqliteMapper;

  static final StorableHashMap<StorableString, PluginInformation> plugins =
      StorableHashMap<StorableString, PluginInformation>();
  static final StorableHashMap<StorableString, MenuItem> menuItems =
      StorableHashMap<StorableString, MenuItem>();

  static final Logger log = Logger("GeigerApi");

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
        _logger.info(
            'registered Plugin $id executable: ${info.getExecutable() ?? 'null'} port: ${info.getPort().toString()}');
      }
      return;
    }

    // request to register at Master
    final PluginInformation pluginInformation =
        PluginInformation(_executor, _geigerCommunicator.getPort());

    try {
      await sendMessage(Message(
          _id,
          GeigerApi.masterId,
          MessageType.registerPlugin,
          GeigerUrl(null, GeigerApi.masterId, 'registerPlugin'),
          await pluginInformation.toByteArray()));
    } on MalformedUrlException catch (e, st) {
      _logger.severe('got unexpected MalformedUrlException', e, st);
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
      await sendMessage(Message(
          _id,
          GeigerApi.masterId,
          MessageType.deregisterPlugin,
          GeigerUrl(null, GeigerApi.masterId, 'deregisterPlugin')));
    } on MalformedUrlException catch (e, st) {
      _logger.severe('got unexpected MalformedUrlException', e, st);
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
    StorageController? ret;
    if (_isMaster) {
      ret = GenericController(_id, _mapper!.getMapper());
    } else {
      // local only
      ret = GenericController(_id, _mapper!.getMapper());
      // TODO: Add support for remote storage
      //return PasstroughController(this, _id);
    }
    ExtendedTimestamp.initializeTimestamp(ret);
    return ret;
  }

  @override
  Future<void> registerListener(
      List<MessageType> events, PluginListener listener,
      [bool internal = false]) async {
    if (internal) {
      for (final MessageType e in events) {
        List<PluginListener>? l = _listeners[e];
        // The short form computeIfAbsent is not available in TotalCross
        if (l == null) {
          l = <PluginListener>[];
          _listeners[e] = l;
        }
        if (e.id < 10000) {
          l.add(listener);
        }
      }
      return;
    }
    for (final MessageType e in events) {
      List<PluginListener>? l = _listeners[e];
      // The short form computeIfAbsent is not available in TotalCross
      if (l == null) {
        l = <PluginListener>[];
        _listeners[e] = l;
      }
      if (e.id < 10000) {
        l.add(listener);
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
  Future<void> sendMessage(Message msg, [String? pluginId]) async {
    pluginId ??= msg.targetId;
    // Messgae to myself?
    if (_id == pluginId) {
      // communicate locally
      PluginInformation initplugin = PluginInformation(null, 0);
      if (plugins[StorableString(_id)] != null) {
        initplugin = plugins[StorableString(_id)]!;
      }
      await receivedMessage(initplugin, msg);
      // Message to a local (internal) plugin?
    } else if (instances[pluginId] != null) {
      _logger.info('Sending message to internal plugin $pluginId ($msg)');
      await (instances[pluginId] as CommunicationApi)
          .receivedMessage(PluginInformation(null, 0), msg);
      // Message to an external plugin
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
    _logger.info('## got message in plugin $_id => $msg');
    MenuItem? i;
    switch (msg.type) {
      case MessageType.enableMenu:
        i = menuItems[StorableString(msg.payloadString)];
        if (i != null) {
          i.enabled = true;
        }
        try {
          await sendMessage(Message(
              _id,
              msg.sourceId,
              MessageType.comapiSuccess,
              GeigerUrl(null, msg.sourceId, 'enableMenu')));
        } on MalformedUrlException catch (e, st) {
          _logger.severe('got unexpected MalformedUrlException', e, st);
        }
        break;
      case MessageType.disableMenu:
        i = menuItems[StorableString(msg.payloadString)];
        if (i != null) {
          i.enabled = false;
        }
        try {
          await sendMessage(Message(
              _id,
              msg.sourceId,
              MessageType.comapiSuccess,
              GeigerUrl(null, msg.sourceId, 'disableMenu')));
        } on MalformedUrlException catch (e, st) {
          _logger.severe('got unexpected MalformedUrlException', e, st);
        }
        break;
      case MessageType.registerMenu:
        i = await MenuItem.fromByteArrayStream(ByteStream(null, msg.payload));
        menuItems[StorableString(i.menu)] = i;
        try {
          await sendMessage(Message(
              _id,
              msg.sourceId,
              MessageType.comapiSuccess,
              GeigerUrl(null, msg.sourceId, 'registerMenu')));
        } on MalformedUrlException catch (e, st) {
          _logger.severe('got unexpected MalformedUrlException', e, st);
        }
        break;
      case MessageType.deregisterMenu:
        var menuString = utf8.fuse(base64).decode(msg.payloadString.toString());
        menuItems.remove(StorableString(menuString));
        try {
          await sendMessage(Message(
              _id,
              msg.sourceId,
              MessageType.comapiSuccess,
              GeigerUrl(null, msg.sourceId, 'deregisterMenu')));
        } on MalformedUrlException catch (e, st) {
          _logger.severe('got unexpected MalformedUrlException', e, st);
        }
        break;
      case MessageType.registerPlugin:
        await registerPlugin(
            msg.sourceId, await PluginInformation.fromByteArray(msg.payload));
        try {
          await sendMessage(Message(
              _id,
              msg.sourceId,
              MessageType.comapiSuccess,
              GeigerUrl(null, msg.sourceId, 'registerPlugin')));
        } on MalformedUrlException catch (e, st) {
          _logger.severe('got unexpected MalformedUrlException', e, st);
        }
        break;
      case MessageType.deregisterPlugin:
        await deregisterPlugin(msg.sourceId);
        try {
          await sendMessage(Message(
              _id,
              msg.sourceId,
              MessageType.comapiSuccess,
              GeigerUrl(null, msg.sourceId, 'deregisterPlugin')));
        } on MalformedUrlException catch (e, st) {
          _logger.severe('got unexpected MalformedUrlException', e, st);
        }
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
          try {
            await sendMessage(Message(
                _id,
                msg.sourceId,
                MessageType.comapiSuccess,
                GeigerUrl(null, msg.sourceId, 'activatePlugin')));
          } on MalformedUrlException catch (e, st) {
            _logger.severe('got unexpected MalformedUrlException', e, st);
          }
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
          try {
            await sendMessage(Message(
                _id,
                msg.sourceId,
                MessageType.comapiSuccess,
                GeigerUrl(null, msg.sourceId, 'deactivatePlugin')));
          } on MalformedUrlException catch (e, st) {
            _logger.severe('got unexpected MalformedUrlException', e, st);
          }
          break;
        }
      case MessageType.registerListener:
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
            if (e.id < 10000 && listener != null) {
              l.add(listener);
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
          try {
            await sendMessage(Message(_id, msg.sourceId, MessageType.pong,
                GeigerUrl(null, msg.sourceId, ''), msg.payload));
          } on MalformedUrlException catch (e, st) {
            _logger.severe('got unexpected MalformedUrlException', e, st);
          }
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
    try {
      await sendMessage(Message(
          _id,
          GeigerApi.masterId,
          MessageType.registerMenu,
          GeigerUrl(null, GeigerApi.masterId, 'registerMenu'),
          await MenuItem(menu, action).toByteArray()));
    } on MalformedUrlException catch (e, st) {
      _logger.severe('got unexpected MalformedUrlException', e, st);
    }
  }

  @override
  Future<void> enableMenu(String menu) async {
    try {
      await sendMessage(Message(
          _id,
          GeigerApi.masterId,
          MessageType.enableMenu,
          GeigerUrl(null, GeigerApi.masterId, 'enableMenu'),
          utf8.encode(menu)));
    } on MalformedUrlException catch (e, st) {
      _logger.severe('got unexpected MalformedUrlException', e, st);
    }
  }

  @override
  Future<void> disableMenu(String menu) async {
    try {
      Message msg = Message(
        _id,
        GeigerApi.masterId,
        MessageType.disableMenu,
        GeigerUrl(null, GeigerApi.masterId, 'disableMenu'),
      );
      msg.payloadString = menu;
      await sendMessage(msg);
    } on MalformedUrlException catch (e, st) {
      _logger.severe('got unexpected MalformedUrlException', e, st);
    }
  }

  @override
  Future<void> deregisterMenu(String menu) async {
    try {
      await sendMessage(Message(
          _id,
          GeigerApi.masterId,
          MessageType.deregisterMenu,
          GeigerUrl(null, GeigerApi.masterId, 'deregisterMenu'),
          utf8.encode(menu)));
    } on MalformedUrlException catch (e, st) {
      _logger.severe('got unexpected MalformedUrlException', e, st);
    }
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
      try {
        await sendMessage(Message(
            _id,
            GeigerApi.masterId,
            MessageType.scanPressed,
            GeigerUrl(null, GeigerApi.masterId, 'scanPressed')));
      } on MalformedUrlException catch (e, st) {
        _logger.severe('got unexpected MalformedUrlException', e, st);
      }
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
