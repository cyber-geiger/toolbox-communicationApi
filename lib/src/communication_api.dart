library geiger_api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

import 'package:cryptography/cryptography.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_api/src/communication/communication_helper.dart';
import 'package:geiger_api/src/communication/geiger_communicator.dart';
import 'package:geiger_api/src/plugin/communication_secret.dart';
import 'package:geiger_api/src/storage/passthrough_controller.dart';
import 'package:geiger_api/src/storage/storage_event_handler.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:logging/logging.dart';

import 'plugin/plugin_starter.dart';

class _StartupWaiter implements PluginListener {
  static const _events = [
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

class _RegisterResultWaiter implements PluginListener {
  static const _events = [MessageType.authSuccess, MessageType.authError];
  final Completer<bool> _completer = Completer();
  final GeigerApi _api;

  _RegisterResultWaiter(this._api) {
    _api.registerListener(_events, this);
  }

  @override
  void pluginEvent(GeigerUrl? _, Message msg) {
    if (msg.action?.path != 'registerPlugin') return;
    _completer.complete(msg.type == MessageType.authSuccess);
  }

  Future<bool> wait() {
    return _completer.future.then((val) {
      deregister();
      return val;
    });
  }

  void deregister() {
    _api.deregisterListener(_events, this);
  }
}

/// Offers an API for all plugins to access the local toolbox.
class CommunicationApi extends GeigerApi {
  static final _keyExchangeAlgorithm = X25519();

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
  final bool autoAcceptRegistration;
  final bool ignoreMessageSignature;

  final platform = const MethodChannel('geiger.fhnw.ch/messages');
  
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
      StorageMapper Function() mapper = defaultStorageMapper,
      this.autoAcceptRegistration = true,
      this.ignoreMessageSignature = false}) {
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
  }

  Future<void> _registerPlugin(PluginInformation plugin) async {
    plugins[StorableString(plugin.id)] = plugin;
    GeigerApi.logger.info('registered Plugin ${plugin.id} executable: '
        '${plugin.getExecutable() ?? 'null'} port: ${plugin.port}');
    await storeState();
  }

  @override
  Future<void> registerPlugin() async {
    final keyPair = await _keyExchangeAlgorithm.newKeyPair();
    final pluginInformation = PluginInformation(
        id,
        executor,
        _communicator.port,
        declaration,
        CommunicationSecret((await keyPair.extractPublicKey()).bytes));
    // Needs to be registered before sending the registration request
    // incase the master responds too fast
    final resultWaiter = _RegisterResultWaiter(this);
    final result = await CommunicationHelper.sendAndWait(
        this,
        Message(
            id,
            GeigerApi.masterId,
            MessageType.registerPlugin,
            GeigerUrl(null, GeigerApi.masterId, 'registerPlugin'),
            await pluginInformation.toByteArray()));
    if (result.type == MessageType.comapiError) {
      throw CommunicationException("Plugin registration failed");
    }
    final secret = await _keyExchangeAlgorithm.sharedSecretKey(
        keyPair: keyPair,
        remotePublicKey: SimplePublicKey(result.payload,
            type: _keyExchangeAlgorithm.keyPairType));
    final info = PluginInformation(
        GeigerApi.masterId,
        GeigerApi.masterExecutor,
        GeigerCommunicator.masterPort,
        Declaration.doNotShareData,
        CommunicationSecret(await secret.extractBytes()));
    // TODO: call listener to display fingerprint
    final didSucceed = await resultWaiter.wait();
    if (!didSucceed) {
      throw CommunicationException("Plugin registration was denied.");
    }
    plugins[const StorableString(GeigerApi.masterId)] = info;
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
            entry.value.id,
            entry.value.executable,
            0,
            entry.value.declaration,
            entry.value.secret);
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
  Future<void> sendMessage(Message message,
      [String? pluginId, PluginInformation? plugin]) async {
    pluginId ??= message.targetId;
    plugin ??= plugins[StorableString(pluginId)] ??
        PluginInformation(
            pluginId!,
            GeigerApi.masterExecutor,
            pluginId == GeigerApi.masterId ? GeigerCommunicator.masterPort : 0,
            Declaration.doNotShareData);
    if (id == plugin.id) {
      await receivedMessage(message, skipAuth: true);
      return;
    }

    print('## Sending message to plugin ${plugin.id} ($message)');
    GeigerApi.logger.log(
        Level.INFO, '## Sending message to plugin ${plugin.id} ($message)');

    final inBackground = message.type != MessageType.returningControl;
    print(plugin.port);
    print(message.type);
    if (plugin.port == 0) {
      print("port == 0");
      if (Platform.isAndroid){
        PluginStarter.startPlugin(plugin, inBackground);
      } else if(Platform.isIOS){
        if(inBackground){
          if(pluginId == GeigerApi.masterId){
              await platform.invokeMethod('url', 'geiger://launchandreturn?redirect=testclient://returningcontrol');
            }else{  
              await platform.invokeMethod('url', 'testclient://launchandreturn?redirect=geiger://returningcontrol');
            }
        }else{
          if(pluginId == GeigerApi.masterId){
            print("geiger://returningcontrol");
            await platform.invokeMethod('url', 'geiger://returningcontrol');
            print("after invoke");
          }else{
            print('testclient://returningcontrol');
            await platform.invokeMethod('url', 'testclient://returningcontrol');
            print("after invoke");
          }
        }
        await Future.delayed(masterStartWaitTime);
      }
      print("wating for activation");
      await _StartupWaiter(this, plugin.id).wait();
      plugin = plugins[StorableString(plugin.id)]!;
      print("app activated");
    } else if (!inBackground) {
      print("Foreground");
      // TODO: bring master to foreground
      if (Platform.isAndroid) {
      // Temporary solution for android 
        PluginStarter.startPlugin(plugin, inBackground);
      } else if (Platform.isIOS) {
        if(pluginId == GeigerApi.masterId){
          await platform.invokeMethod('url', 'geiger://returningcontrol');
        }else{  
          await platform.invokeMethod('url', 'testclient://returningcontrol');
        }
      }
    }

    print('--------------------------------- DONE STARTING UP THE PLUGIN ---------------------------------');

    for (var retryCount = 0; retryCount < maxSendRetries; retryCount++) {
      print("retry");
      try {
        await _communicator.sendMessage(plugin!, message);
        break;
      } on SocketException catch (e) {
        if (e.osError?.message != 'Connection refused') rethrow;
          if (Platform.isAndroid) {
        // Temporary solution for android
          PluginStarter.startPlugin(plugin!, inBackground);
        } else if (Platform.isIOS) {
          if(inBackground){
            if(pluginId == GeigerApi.masterId){
              await platform.invokeMethod('url', 'geiger://launchandreturn?redirect=testclient://returningcontrol');
            }else{  
              await platform.invokeMethod('url', 'testclient://launchandreturn?redirect=geiger://returningcontrol');
            }
          }else{
            if(pluginId == GeigerApi.masterId){
              await platform.invokeMethod('url', 'geiger://returningcontrol');
            }else{  
              await platform.invokeMethod('url', 'testclient://returningcontrol');
            }
          }
        }
        if (plugin!.id == GeigerApi.masterId) {
          await Future.delayed(masterStartWaitTime);
        } else {
          await _StartupWaiter(this, plugin.id).wait();
          plugin = plugins[StorableString(plugin.id)]!;
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

  Future<void> receivedMessage(Message msg, {bool skipAuth = false}) async {
    GeigerApi.logger.info('## got message in plugin $id => $msg');
    if (!isMaster && msg.sourceId != GeigerApi.masterId) return;
    final pluginInfo = plugins[StorableString(msg.sourceId)];
    if (!ignoreMessageSignature &&
        !skipAuth &&
        msg.type != MessageType.authError &&
        msg.type != MessageType.registerPlugin &&
        ((isMaster &&
                (pluginInfo == null ||
                    msg.hash != msg.integrityHash(pluginInfo.secret))) ||
            (!isMaster &&
                pluginInfo != null &&
                msg.hash != msg.integrityHash(pluginInfo.secret)))) {
      await sendMessage(Message(
          id, msg.sourceId, MessageType.authError, null, null, msg.requestId));
      return;
    }

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
        PluginInformation info =
            await PluginInformation.fromByteArray(msg.payload);
        final keyPair = await _keyExchangeAlgorithm.newKeyPair();
        final secret = await _keyExchangeAlgorithm.sharedSecretKey(
            keyPair: keyPair,
            remotePublicKey: SimplePublicKey(info.secret.secret,
                type: _keyExchangeAlgorithm.keyPairType));
        info.secret = CommunicationSecret(await secret.extractBytes());
        ByteSink sink = ByteSink();
        info.toByteArrayStream(sink);
        sink.close();
        msg.payload = await sink.bytes;
        await sendMessage(
            Message(
                id,
                msg.sourceId,
                MessageType.comapiSuccess,
                GeigerUrl(null, msg.sourceId, 'registerPlugin'),
                (await keyPair.extractPublicKey()).bytes,
                msg.requestId),
            null,
            info);
        if (autoAcceptRegistration) {
          await _registerPlugin(info);
          await sendMessage(Message(id, info.id, MessageType.authSuccess,
              GeigerUrl(null, info.id, 'registerPlugin')));
        }
        break;
      case MessageType.authorizePlugin:
        if (autoAcceptRegistration) break;
        final stream = ByteStream(null, msg.payload);
        final isAccepted = await SerializerHelper.readInt(stream) == 1;
        final info = await PluginInformation.fromByteArrayStream(stream);
        MessageType type = MessageType.authError;
        if (isAccepted) {
          await _registerPlugin(info);
          type = MessageType.authSuccess;
        }
        await sendMessage(Message(
            id, info.id, type, GeigerUrl(null, info.id, 'registerPlugin')));
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
          plugins[StorableString(msg.sourceId)] = PluginInformation(
              msg.sourceId,
              pluginInfo.getExecutable(),
              port,
              pluginInfo.declaration,
              pluginInfo.secret);
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
          plugins[StorableString(msg.sourceId)] = PluginInformation(
              msg.sourceId,
              pluginInfo.getExecutable(),
              0,
              pluginInfo.declaration,
              pluginInfo.secret);
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
    //if (msg.type.id < MessageType.allEvents.id) {
      _notifyListeners(MessageType.allEvents, msg);
    //}
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
