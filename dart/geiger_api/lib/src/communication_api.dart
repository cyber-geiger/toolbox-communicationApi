library geiger_api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_api/src/communication/communication_helper.dart';
import 'package:geiger_api/src/communication/geiger_communicator.dart';
import 'package:geiger_api/src/storage/passthrough_controller.dart';
import 'package:geiger_api/src/storage/storage_event_handler.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:logging/logging.dart';

import 'plugin/plugin_starter.dart';

class _StartupWaiter implements PluginListener {
  static const _events = [
    MessageType.registerPlugin,
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
class CommunicationApi extends GeigerApi {
  /// Maximum number of times a message gets resend
  /// when a newly started plugin won't respond.
  static const maxSendRetries = 10;

  /// Duration non-master plugins will wait for the master to start.
  ///
  /// Maximum total duration is [masterStartWaitTime] * [maxSendRetries].
  static const masterStartWaitTime = Duration(seconds: 1);

  /// Default [StorageMapper] generator used by the master.
  static StorageMapper defaultStorageMapper() => SqliteMapper('database');

  @override
  final String id;
  @override
  final Declaration declaration;
  final String executor;
  final bool isMaster;

  @override
  late final StorageController storage;
  String? statePath;
  late final GeigerCommunicator _communicator;

  /// [PluginInformation] of all registered plugins mapped by their id.
  final StorableHashMap<StorableString, PluginInformation> plugins =
      StorableHashMap();

  /// All registered [MenuItem]s mapped by their path.
  final StorableHashMap<StorableString, MenuItem> menuItems = StorableHashMap();

  /// All registered [PluginListener]s mapped by their [MessageType] filter.
  final Map<MessageType, List<PluginListener>> _listeners = {};

  /// Creates a [CommunicationApi] with the given [executor] and plugin [id].
  ///
  /// Whether this api [isMaster] and its privacy [declaration] must also be provided.
  CommunicationApi(this.executor, this.id, this.isMaster, this.declaration,
      {this.statePath,
      StorageMapper Function() mapper = defaultStorageMapper}) {
    _communicator = GeigerCommunicator(this);
    if (isMaster) {
      storage = GenericController(id, mapper());
      registerListener(
          [MessageType.storageEvent], StorageEventHandler(this, storage));
    } else {
      final controller = storage = PassthroughController(this);
      registerListener([MessageType.storageEvent], controller);
    }
  }

  @override
  Future<List<PluginInformation>> getRegisteredPlugins(
      [String? startId]) async {
    final selectedPlugins = startId == null
        ? plugins.values
        : plugins.values.where((info) => info.id.startsWith(id));
    return Future.wait(selectedPlugins.map((info) => info.shallowClone()));
  }

  @override
  Future<void> initialize() async {
    await restoreState();
    await _communicator.start();
    if (isMaster) return;
    await registerPlugin();
    await activatePlugin();
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
      GeigerApi.logger.info('registered Plugin $pluginId executable: '
          '${info.getExecutable() ?? 'null'} port: ${info.getPort().toString()}');
      await storeState();
      return;
    }

    final pluginInformation =
        PluginInformation(pluginId ?? id, executor, _communicator.port);
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
  Future<void> activatePlugin() async {
    await CommunicationHelper.sendAndWait(
      this,
      Message(id, GeigerApi.masterId, MessageType.activatePlugin, null,
          SerializerHelper.intToByteArray(_communicator.port)),
    );
  }

  @override
  void authorizePlugin(PluginInformation plugin) {
    // locally authorize the plugin
    plugins[StorableString(plugin.toString())] = plugin;
  }

  @override
  Future<void> deactivatePlugin() async {
    await CommunicationHelper.sendAndWait(this,
        Message(id, GeigerApi.masterId, MessageType.deactivatePlugin, null));
  }

  @override
  Future<void> deregisterPlugin([String? pluginId]) async {
    if (pluginId != null) {
      menuItems.removeWhere((_, value) => value.action.plugin == pluginId);
      plugins.remove(StorableString(pluginId));
      await storeState();
      return;
    }

    await CommunicationHelper.sendAndWait(
        this,
        Message(id, GeigerApi.masterId, MessageType.deregisterPlugin,
            GeigerUrl(null, GeigerApi.masterId, 'deregisterPlugin')));
  }

  Future<void> storeState() async {
    await StorageMapper.initDatabaseExpander();
    statePath ??= StorageMapper.expandDbFileName('');
    try {
      GeigerApi.logger.log(Level.INFO, 'storing state to $statePath');

      final ByteSink out = ByteSink();
      plugins.toByteArrayStream(out);
      menuItems.toByteArrayStream(out);
      out.close();

      final IOSink file = File('$statePath/GeigerApi.$id.state').openWrite();
      file.add(await out.bytes);
      await file.close();
    } catch (ioe) {
      GeigerApi.logger
          .log(Level.SEVERE, 'unable to write state file to $statePath', ioe);
    }
  }

  static Future<bool> _isWorkingDirectoryWriteable() async {
    try {
      final file = File('./test.tst');
      // try appending nothing
      await file.writeAsString('', mode: FileMode.append, flush: true);
      await file.delete();
      return true;
    } on FileSystemException {
      return false;
    }
  }

  Future<void> restoreState() async {
    if (await _isWorkingDirectoryWriteable()) {
      statePath = '.';
    } else {
      await StorageMapper.initDatabaseExpander();
      statePath ??= StorageMapper.expandDbFileName('');
    }

    try {
      GeigerApi.logger.log(Level.INFO, 'loading state from $statePath');

      final file = File('$statePath/GeigerApi.$id.state');
      final ByteStream stream = ByteStream(null, await file.readAsBytes());

      await StorableHashMap.fromByteArrayStream(stream, plugins);
      // set all ports to 0
      for (final entry in plugins.entries) {
        plugins[entry.key] = PluginInformation(
            entry.value.id, entry.value.executable, 0, entry.value.secret);
      }
      await StorableHashMap.fromByteArrayStream(stream, menuItems);
    } catch (e) {
      GeigerApi.logger.log(Level.WARNING,
          'unable to read state file from $statePath... rewriting', e);
      await storeState();
    }
  }

  @override
  void registerListener(
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
  void deregisterListener(
      List<MessageType>? events, PluginListener listener) async {
    for (var event in (events ?? MessageType.values)) {
      _listeners[event]?.remove(listener);
    }
  }

  @override
  Future<void> sendMessage(Message message, [String? pluginId]) async {
    pluginId ??= message.targetId;
    if (id == pluginId) {
      await receivedMessage(message);
      return;
    }

    GeigerApi.logger
        .log(Level.INFO, '## Sending message to plugin $pluginId ($message)');
    PluginInformation pluginInfo = plugins[StorableString(pluginId)] ??
        PluginInformation(pluginId!, GeigerApi.masterExecutor,
            pluginId == GeigerApi.masterId ? GeigerCommunicator.masterPort : 0);
    final inBackground = message.type != MessageType.returningControl;
    if (pluginInfo.getPort() == 0) {
      PluginStarter.startPlugin(pluginInfo, inBackground);
      await _StartupWaiter(this, pluginId!).wait();
      pluginInfo = plugins[StorableString(pluginId)]!;
    } else if (!inBackground) {
      // TODO: bring master to foreground
      // Temporary solution for android
      PluginStarter.startPlugin(pluginInfo, inBackground);
    }

    for (var retryCount = 0; retryCount < maxSendRetries; retryCount++) {
      try {
        await _communicator.sendMessage(pluginInfo.port, message);
        break;
      } on SocketException catch (e) {
        if (e.osError?.message != 'Connection refused') rethrow;
        PluginStarter.startPlugin(pluginInfo, inBackground);
        if (pluginId == GeigerApi.masterId) {
          await Future.delayed(masterStartWaitTime);
        } else {
          await _StartupWaiter(this, pluginId!).wait();
          pluginInfo = plugins[StorableString(pluginId)]!;
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
    GeigerApi.logger.info('## got message in plugin $id => $msg');
    switch (msg.type) {
      case MessageType.enableMenu:
        final item = menuItems[StorableString(msg.payloadString)];
        if (item != null) {
          item.enabled = true;
        }
        await sendMessage(Message(id, msg.sourceId, MessageType.comapiSuccess,
            GeigerUrl(null, msg.sourceId, 'enableMenu'), null, msg.requestId));
        break;
      case MessageType.disableMenu:
        final item = menuItems[StorableString(msg.payloadString)];
        if (item != null) {
          item.enabled = false;
        }
        await sendMessage(Message(id, msg.sourceId, MessageType.comapiSuccess,
            GeigerUrl(null, msg.sourceId, 'disableMenu'), null, msg.requestId));
        break;
      case MessageType.registerMenu:
        final item =
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
        final menuString = utf8.fuse(base64).decode(msg.payloadString!);
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
          final PluginInformation pluginInfo =
              plugins[StorableString(msg.sourceId)]!;
          final port = SerializerHelper.byteArrayToInt(msg.payload);
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
          var pluginInfo = plugins[StorableString(msg.sourceId)]!;
          await sendMessage(Message(
              id,
              msg.sourceId,
              MessageType.comapiSuccess,
              GeigerUrl(null, msg.sourceId, 'deactivatePlugin'),
              null,
              msg.requestId));
          plugins[StorableString(msg.sourceId)] =
              PluginInformation(msg.sourceId, pluginInfo.getExecutable(), 0);
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
          await sendMessage(Message(id, msg.sourceId, MessageType.pong,
              GeigerUrl(null, msg.sourceId, ''), msg.payload, msg.requestId));
          break;
        }
      default:
        break;
    }
    _notifyListeners(msg.type, msg);
    if (msg.type.id < MessageType.allEvents.id) {
      _notifyListeners(MessageType.allEvents, msg);
    }
  }

  void _notifyListeners(MessageType type, Message message) {
    final listeners = _listeners[type];
    if (listeners == null) return;
    for (var listener in listeners) {
      GeigerApi.logger.info(
          '## notifying PluginListener ${listener.toString()} '
          'for msg ${message.type.toString()} ${message.action.toString()}');
      listener.pluginEvent(message.action, message);
      GeigerApi.logger.info('## PluginEvent fired');
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
    Message msg = Message(id, GeigerApi.masterId, MessageType.disableMenu,
        GeigerUrl(null, GeigerApi.masterId, 'disableMenu'));
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
  Future<void> zapState() async {
    menuItems.clear();
    plugins.clear();
    await storeState();
  }

  @override
  Future<void> close() async {
    await _communicator.close();
  }
}