library geiger_api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_api/src/communication/communication_helper.dart';
import 'package:geiger_api/src/communication/geiger_communicator.dart';
import 'package:geiger_api/src/communication/passthrough_controller.dart';
import 'package:geiger_api/src/communication/storage_event_handler.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:logging/logging.dart';

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

class _StartupWaiter implements PluginListener {
  static const _events = [
    MessageType.registerListener,
    MessageType.activatePlugin
  ];
  final String pluginId;

  final CommunicationApi _api;
  final Completer _completer = Completer();

  _StartupWaiter(this._api, this.pluginId) {
    _api.registerListener(_events, this);
  }

  @override
  void pluginEvent(GeigerUrl? _, Message msg) {
    if (msg.sourceId != pluginId) return;
    _completer.complete();
  }

  Future wait([Duration timeout = const Duration(seconds: 15)]) {
    return _completer.future.timeout(timeout, onTimeout: () {
      deregister();
      throw TimeoutException('Plugin "$pluginId" did not start in time.');
    }).then((_) => deregister());
  }

  void deregister() {
    _api.deregisterListener(_events, this);
  }
}

/// Offers an API for all plugins to access the local toolbox.
class CommunicationApi implements GeigerApi {
  static const maxReachMasterRetries = 10;
  static const masterStartWaitTime = Duration(seconds: 1);

  /// Creates a [CommunicationApi] with the given [executor] and plugin [id].
  ///
  /// Whether this api [isMaster] and its privacy [_declaration] must also be provided.
  CommunicationApi(
      String executor, this.id, this.isMaster, Declaration declaration,
      {statePath}) {
    _executor = executor;
    _declaration = declaration;
    _geigerCommunicator = GeigerCommunicator(this);
  }

  static const bool persistent = false;

  static final Logger _logger = Logger('GeigerAPI');

  static const Mapper defaultMapper = Mapper.sqliteMapper;

  final StorableHashMap<StorableString, PluginInformation> plugins =
      StorableHashMap();
  final StorableHashMap<StorableString, MenuItem> menuItems = StorableHashMap();

  late String _executor;
  @override
  final String id;
  late final bool isMaster;
  late Declaration _declaration;
  Mapper? _mapper;
  StorageController? _controller;
  String? statePath;

  final Map<MessageType, List<PluginListener>> _listeners =
      <MessageType, List<PluginListener>>{};

  late GeigerCommunicator _geigerCommunicator;

  @override
  Future<void> initialize() async {
    await restoreState();
    await _geigerCommunicator.start();
    await StorageMapper.initDatabaseExpander();
    if (!isMaster) {
      try {
        // setup listener
        await registerPlugin();
        await activatePlugin();
      } on IOException {
        rethrow;
      }
    } else {
      // it is master
      final StorageEventHandler storageEventHandler =
          StorageEventHandler(this, getStorage()!);
      await registerListener([MessageType.storageEvent], storageEventHandler);
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
      plugins[StorableString(pluginId)] = info;
      _logger.info(
          'registered Plugin $pluginId executable: ${info.getExecutable() ?? 'null'} port: ${info.getPort().toString()}');
      await storeState();
      return;
    }

    // request to register at Master
    final PluginInformation pluginInformation =
        PluginInformation(pluginId ?? id, _executor, _geigerCommunicator.port);

    await CommunicationHelper.sendAndWait(
        this,
        Message(
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

      await storeState();
      return;
    }
    await CommunicationHelper.sendAndWait(
        this,
        Message(id, GeigerApi.masterId, MessageType.deregisterPlugin,
            GeigerUrl(null, GeigerApi.masterId, 'deregisterPlugin')));
    //await zapState();
  }

  /// Deletes all current registered items.
  @override
  Future<void> zapState() async {
    menuItems.clear();
    plugins.clear();
    await storeState();
  }

  Future<void> storeState() async {
    await StorageMapper.initDatabaseExpander();
    statePath ??= StorageMapper.expandDbFileName('');
    // store plugin state
    try {
      _logger.log(Level.INFO, 'storing state to $statePath');
      final ByteSink out = ByteSink();
      plugins.toByteArrayStream(out);
      menuItems.toByteArrayStream(out);
      out.close();
      final IOSink file = File('$statePath/GeigerApi.$id.state').openWrite();
      file.add(await out.bytes);
      file.close();
    } catch (ioe) {
      _logger.log(
          Level.SEVERE, 'unable to write state file to $statePath', ioe);
    }
  }

  static bool isWriteable([String path = "."]) {
    bool res;
    final f = File('$path${Platform.pathSeparator}test.tst');
    final didExist = f.existsSync();
    try {
      // try appending nothing
      f.writeAsStringSync('', mode: FileMode.append, flush: true);
      res = true;
      if (didExist) {
        f.deleteSync();
      }
    } on FileSystemException {
      res = false;
    }
    return res;
  }

  Future<void> restoreState() async {
    if (!isWriteable()) {
      await StorageMapper.initDatabaseExpander();
      statePath ??= StorageMapper.expandDbFileName('');
    } else {
      statePath = '.';
    }
    try {
      _logger.log(Level.INFO, 'loading state from $statePath');
      final File file = File('$statePath/GeigerApi.$id.state');
      final List<int> buff =
          await file.exists() ? await file.readAsBytes() : [];
      final ByteStream in_ = ByteStream(null, buff);
      // restoring plugin information
      await StorableHashMap.fromByteArrayStream(in_, plugins);
      for (final entry in plugins.entries) {
        plugins[entry.key] = PluginInformation(
            entry.value.id, entry.value.executable, 0, entry.value.secret);
      }
      // restoring menu information
      await StorableHashMap.fromByteArrayStream(in_, menuItems);
    } catch (e) {
      _logger.log(Level.WARNING,
          'unable to read state file from $statePath... rewriting', e);
      await storeState();
    }
  }

  @override
  Future<void> activatePlugin() async {
    await CommunicationHelper.sendAndWait(
      this,
      Message(id, GeigerApi.masterId, MessageType.activatePlugin, null,
          SerializerHelper.intToByteArray(_geigerCommunicator.port)),
    );
  }

  @override
  Future<void> deactivatePlugin() async {
    await CommunicationHelper.sendAndWait(this,
        Message(id, GeigerApi.masterId, MessageType.deactivatePlugin, null));
  }

  /// Obtain [StorageController] to access the storage.
  @override
  StorageController? getStorage() {
    if (_controller == null) {
      _mapper ??= defaultMapper;
      if (isMaster) {
        _controller = GenericController(id, _mapper!.getMapper());
      } else {
        final passthrough = _controller = PassthroughController(this);
        registerListener([MessageType.storageEvent], passthrough);
      }
    }
    return _controller;
  }

  @override
  Future<void> registerListener(
      List<MessageType> events, PluginListener listener) async {
    events.map((event) {
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
      _logger.log(Level.INFO, '## Sending message to plugin $pluginId ($msg)');
      // Message to external plugin
      PluginInformation pluginInfo = plugins[StorableString(pluginId)] ??
          PluginInformation(
              pluginId!,
              PluginStarter.masterExecutor,
              pluginId == GeigerApi.masterId
                  ? GeigerCommunicator.masterPort
                  : 0);
      final inBackground = msg.type != MessageType.returningControl;
      if (pluginInfo.getPort() == 0) {
        PluginStarter.startPlugin(pluginInfo, inBackground);
        await _StartupWaiter(this, pluginId!).wait();
        pluginInfo = plugins[StorableString(pluginId)]!;
      } else if (!inBackground) {
        // TODO: bring master to foreground
        // Temporary solution for android
        PluginStarter.startPlugin(pluginInfo, inBackground);
      }
      for (var retryCount = 0;
          retryCount < maxReachMasterRetries;
          retryCount++) {
        try {
          await _geigerCommunicator.sendMessage(pluginInfo.port, msg);
          break;
        } on SocketException catch (e) {
          if (pluginId != GeigerApi.masterId ||
              e.osError?.message != 'Connection refused') rethrow;
          PluginStarter.startPlugin(pluginInfo, inBackground);
          await Future.delayed(masterStartWaitTime);
        }
      }
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
        menuItems[StorableString(item.menu.path)] = item;
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
        await sendMessage(Message(
            id,
            msg.sourceId,
            MessageType.comapiSuccess,
            GeigerUrl(null, msg.sourceId, 'deregisterPlugin'),
            null,
            msg.requestId));
        await deregisterPlugin(msg.sourceId);
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
              PluginInformation(msg.sourceId, pluginInfo.getExecutable(), port);
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
          await sendMessage(Message(
              id,
              msg.sourceId,
              MessageType.comapiSuccess,
              GeigerUrl(null, msg.sourceId, 'deactivatePlugin'),
              null,
              msg.requestId));
          plugins.remove(StorableString(msg.sourceId));
          // put new info
          plugins[StorableString(msg.sourceId)] =
              PluginInformation(msg.sourceId, pluginInfo.getExecutable(), 0);
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
  Future<void> registerMenu(MenuItem menu) async {
    ByteSink bout = ByteSink();
    menu.toByteArrayStream(bout);
    bout.close();
    await CommunicationHelper.sendAndWait(
        this,
        Message(
            id,
            GeigerApi.masterId,
            MessageType.registerMenu,
            GeigerUrl(null, GeigerApi.masterId, 'registerMenu'),
            await bout.bytes));
  }

  @override
  Future<void> enableMenu(String menu) async {
    await CommunicationHelper.sendAndWait(
        this,
        Message(
            id,
            GeigerApi.masterId,
            MessageType.enableMenu,
            GeigerUrl(null, GeigerApi.masterId, 'enableMenu'),
            utf8.encode(menu)));
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
    await CommunicationHelper.sendAndWait(this, msg);
  }

  @override
  Future<void> deregisterMenu(String menu) async {
    await CommunicationHelper.sendAndWait(
        this,
        Message(
            id,
            GeigerApi.masterId,
            MessageType.deregisterPlugin,
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
    if (!isMaster) {
      await CommunicationHelper.sendAndWait(
          this,
          Message(id, GeigerApi.masterId, MessageType.scanPressed,
              GeigerUrl(null, GeigerApi.masterId, 'scanPressed')));
    } else {
      await broadcastMessage(
          Message(GeigerApi.masterId, null, MessageType.scanPressed, null));
    }
  }

  @override
  Future<void> close() async {
    await _geigerCommunicator.close();
  }

  @override
  void authorizePlugin(PluginInformation plugin) {
    // locally authorize the plugin
    plugins[StorableString(plugin.toString())] = plugin;
  }

  @override
  Future<List<PluginInformation>> getRegisteredPlugins([String? id]) async {
    List<PluginInformation> ret = [];
    for (PluginInformation pi in plugins.values) {
      if (id == null || pi.toString().startsWith(id)) {
        ret.add(await pi.shallowClone());
      }
    }
    return ret;
  }
}
