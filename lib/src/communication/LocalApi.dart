import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'MalformedUrlException.dart';
import 'package:localstorage/localstorage.dart';

import 'CommunicatorApi.dart';
import 'Declaration.dart';
import 'GeigerClient.dart';
import 'GeigerCommunicator.dart';
import 'GeigerServer.dart';
import 'GeigerUrl.dart';
import 'MenuItem.dart';
import 'Message.dart';
import 'MessageType.dart';
import 'PasstroughController.dart';
import 'PluginInformation.dart';
import 'PluginListener.dart';
import 'PluginStarter.dart';
import 'StorableHashMap.dart';
import 'StorableString.dart';
import 'StorageEventHandler.dart';

enum Mapper {
  DUMMY_MAPPER,
  SQLITE_MAPPER,
}

extension MapperExtension on Mapper {
  StorageMapper getMapper() {
    switch (this) {
      case Mapper.DUMMY_MAPPER:
        return DummyMapper();
      case Mapper.SQLITE_MAPPER:
        return SqliteMapper('./testdb');
    }
  }
}

/// Offers an API for all plugins to access the local toolbox.
class LocalApi implements CommunicatorApi {
  static final bool PERSISTENT = false;

  static Mapper? mapper;
  static final Mapper DEFAULT_MAPPER = Mapper.SQLITE_MAPPER;

  static final String MASTER = '__MASTERPLUGIN__';

  static final StorableHashMap<StorableString, PluginInformation> plugins =
      StorableHashMap();
  static final StorableHashMap<StorableString, MenuItem> menuItems =
      StorableHashMap();

  // static final Logger log = Logger.getLogger("LocalAPI");

  final String executor;
  final String id;
  final bool isMaster;
  final Declaration? declaration;

  final Map<MessageType, List<PluginListener>> listeners = HashMap();

  // TODO: continue translating from here

  late GeigerCommunicator geigerCommunicator;

  /// Creates a [LocalApi] with the given [executor] and plugin [id].
  ///
  /// Whether this api [isMaster] and its privacy [declaration] must also be provided.
  LocalApi(this.executor, this.id, this.isMaster, this.declaration) {
    restoreState();

    PluginListener storageEventHandler;
    if (!isMaster) {
      // it is a plugin
      try {
        geigerCommunicator = GeigerClient(this);
        geigerCommunicator.start();
        registerPlugin();
        activatePlugin(geigerCommunicator.getPort());
      } on IOException catch (e) {
        // TODO error handling
        print(e);
      }
      // TODO should the passtroughcontroller be listener?
      storageEventHandler = PasstroughController(this, id);
      // this code is duplicate from registerListener method
      // it is currently not possible to determin between register internally and register on Master
      // therefore this duplicate is necessary
      registerListener([MessageType.STORAGE_EVENT], storageEventHandler, true);
    } else {
      // it is master
      try {
        geigerCommunicator = GeigerServer(this);
        geigerCommunicator.start();
      } on IOException catch (e) {
        // TODO error handling
        print(e);
      }
      storageEventHandler = StorageEventHandler(this, getStorage()!);
      registerListener([MessageType.STORAGE_EVENT], storageEventHandler);
    }
  }

  void setMapper(Mapper m) {
    if (mapper == null) {
      mapper = m;
    } else {
      throw StorageException('Mapper is already set');
    }
  }

  /// Returns the [Declaration] given upon creation.
  Declaration? getDeclaration() {
    return declaration;
  }

  @override
  void registerPlugin([String? id, PluginInformation? info]) {
    // TODO share secret in a secure paired way....
    //PluginInformation pi = new PluginInformation();
    //CommunicationSecret secret = new CommunicationSecret();
    //secrets.put(id, secret);

    if (id != null) {
      if (info == null) throw NullThrownError();
      if (!plugins.containsKey(StorableString(id))) {
        plugins[StorableString(id)] = info;
        print('## registered Plugin ' +
            id +
            ' executable: ' +
            (info.getExecutable() ?? 'null') +
            ' port: ' +
            info.getPort().toString());
      }
      return;
    }

    // request to register at Master
    var pluginInformation =
        PluginInformation(executor, geigerCommunicator.getPort());
    try {
      sendMessage(
          LocalApi.MASTER,
          Message(
              id,
              LocalApi.MASTER,
              MessageType.REGISTER_PLUGIN,
              GeigerUrl(MASTER, 'registerPlugin'),
              pluginInformation.toByteArray()));
    } on MalformedUrlException {
      // TODO proper Error handling
      // this should never occur
    }
  }

  @override
  void deregisterPlugin([String? id]) {
    if (id != null) {
      // remove on master all menu items
      if (isMaster) {
        // synchronized(menuItems) {
        var l = List<String>.empty(growable: true);
        for (var i in menuItems.entries) {
          if (i.value.getAction().getPlugin().equals(id)) {
            l.add(i.key.toString());
          }
        }
        for (var key in l) {
          menuItems.remove(StorableString(key));
        }
        // }
      }

      // remove plugin secret
      plugins.remove(StorableString(id));

      storeState();
      return;
    }

    // TODO getting the id of the plugin itself doesnt make sense
    if (plugins[StorableString(this.id)] == null) {
      throw ArgumentError(
          'no communication secret found for id \"' + this.id + '\"');
    }
    // first deactivate, then deregister at Master, before deleting my own entries.
    deactivatePlugin();
    try {
      sendMessage(
          LocalApi.MASTER,
          Message(this.id, LocalApi.MASTER, MessageType.DEREGISTER_PLUGIN,
              GeigerUrl(MASTER, 'deregisterPlugin')));
    } on MalformedUrlException {
      // TODO proper Error handling
      // this should never occur
    }
    zapState();
  }

  /// Deletes all current registered items.
  void zapState() {
    // synchronized(menuItems) {
    menuItems.clear();
    // }
    // synchronized(plugins) {
    plugins.clear();
    // }
    storeState();
  }

  void storeState() {
    // store plugin state
    try {
      ByteArrayOutputStream out = ByteArrayOutputStream();
      // synchronized(plugins) {
      plugins.toByteArrayStream(out);
      //
      // synchronized(menuItems) {
      menuItems.toByteArrayStream(out);
      // }
      File('LocalAPI.' + id + '.state').writeAsBytesSync(out.toByteArray());
    } catch (ioe) {
      //System.out.println("===============================================U");
      //ioe.printStackTrace();
      //System.out.println("===============================================L");
    }
  }

  void restoreState() {
    var fname = 'LocalAPI.' + id + '.state';
    try {
      var file = File(fname);
      var buff = file.existsSync() ? file.readAsBytesSync() : [];
      ByteArrayInputStream in_ = ByteArrayInputStream(buff);
      // restoring plugin information
      // synchronized(plugins) {
      StorableHashMap.fromByteArrayStream(in_, plugins);
      // }

      // restoring menu information
      // synchronized(menuItems) {
      StorableHashMap.fromByteArrayStream(in_, menuItems);
      // }
    } catch (e) {
      storeState();
    }
  }

  @override
  void activatePlugin(int port) {
    sendMessage(
        MASTER,
        Message(id, MASTER, MessageType.ACTIVATE_PLUGIN, null,
            GeigerCommunicator.intToByteArray(port)));
  }

  @override
  void deactivatePlugin() {
    sendMessage(
        MASTER, Message(id, MASTER, MessageType.DEACTIVATE_PLUGIN, null));
  }

  /// Obtain [StorageController] to access the storage.
  @override
  StorageController? getStorage() {
    mapper ??= DEFAULT_MAPPER;
    if (isMaster) {
      return GenericController(id, mapper!.getMapper());
    } else {
      return PasstroughController(this, id);
    }
  }

  @override
  void registerListener(List<MessageType> events, PluginListener listener,
      [bool internal = false]) {
    if (internal) {
      for (var e in events) {
        // synchronized(listeners) {
        var l = listeners[e];
        // The short form computeIfAbsent is not available in TotalCross
        if (l == null) {
          l = List.empty(growable: true);
          listeners[e] = l;
        }
        if (e.getId() < 10000) {
          l.add(listener);
        }
        // }
      }
      return;
    }
    if (isMaster) {
      for (var e in events) {
        // synchronized(listeners) {
        var l = listeners[e];
        // The short form computeIfAbsent is not available in TotalCross
        if (l == null) {
          l = List.empty(growable: true);
          listeners[e] = l;
        }
        if (e.getId() < 10000) {
          l.add(listener);
        }
        // }
      }
    } else {
      try {
        // formatin int number of events -> events -> listener
        ByteArrayOutputStream out = ByteArrayOutputStream();
        out.write(GeigerCommunicator.intToByteArray(events.length));
        for (var event in events) {
          out.write(GeigerCommunicator.intToByteArray(event.ordinal()));
        }
        // out.write(listener.toByteArray());
        sendMessage(
            MASTER,
            Message(
                id,
                MASTER,
                MessageType.REGISTER_LISTENER,
                GeigerUrl(LocalApi.MASTER, 'registerListener'),
                out.toByteArray()));
      } on IOException {
        // TODO proper Error handling
        // this should never occur
      }
    }
  }

  @override
  void deregisterListener(List<MessageType>? events, PluginListener listener) {
    events ??= MessageType.values;
    for (var e in events) {
      // synchronized(listeners) {
      var l = listeners[e];
      if (l != null) {
        l.remove(listener);
      }
      // }
    }
  }

  @override
  void sendMessage(String pluginId, Message msg) {
    if (id == pluginId) {
      // communicate locally
      receivedMessage(plugins[StorableString(id)]!, msg);
    } else {
      // communicate with foreign plugin
      var pluginInformation = plugins[StorableString(pluginId)]!;
      if (isMaster) {
        // Check if plugin active by checking for a port greater than 0
        if (!(pluginInformation.getPort() > 0)) {
          // is inactive -> start plugin
          geigerCommunicator.startPlugin(pluginInformation);
        }
      }
      geigerCommunicator.sendMessage(pluginInformation, msg);
    }
  }

  /// Broadcasts a [message] to all known plugins.
  void broadcastMessage(Message message) {
    for (var plugin in plugins.entries) {
      sendMessage(
          plugin.key.toString(),
          Message(MASTER, plugin.key.toString(), message.getType(),
              message.getAction(), message.getPayload()));
    }
  }

  void receivedMessage(PluginInformation info, Message msg) {
    // TODO other messagetypes
    MenuItem? i;
    switch (msg.getType()) {
      case MessageType.ENABLE_MENU:
        i = menuItems[StorableString(msg.getPayloadString()!)];
        if (i != null) {
          i.setEnabled(true);
        }
        try {
          sendMessage(
              msg.getSourceId()!,
              Message(
                  msg.getTargetId(),
                  msg.getSourceId(),
                  MessageType.COMAPI_SUCCESS,
                  GeigerUrl(msg.getSourceId()!, 'enableMenu')));
        } on MalformedUrlException {
          // TODO proper Error handling
          // this should never occur
        }
        break;
      case MessageType.DISABLE_MENU:
        i = menuItems[StorableString(msg.getPayloadString()!)];
        if (i != null) {
          i.setEnabled(false);
        }
        try {
          sendMessage(
              msg.getSourceId()!,
              Message(
                  msg.getTargetId(),
                  msg.getSourceId(),
                  MessageType.COMAPI_SUCCESS,
                  GeigerUrl(msg.getSourceId()!, 'disableMenu')));
        } on MalformedUrlException {
          // TODO proper Error handling
          // this should never occur
        }
        break;
      case MessageType.REGISTER_MENU:
        i = MenuItem.fromByteArray(msg.getPayload()!);
        menuItems[StorableString(i.getMenu())] = i;
        try {
          sendMessage(
              msg.getSourceId()!,
              Message(
                  msg.getTargetId(),
                  msg.getSourceId(),
                  MessageType.COMAPI_SUCCESS,
                  GeigerUrl(msg.getSourceId()!, 'registerMenu')));
        } on MalformedUrlException {
          // TODO proper Error handling
          // this should never occur
        }
        break;
      case MessageType.DEREGISTER_MENU:
        var menuString =
            utf8.fuse(base64).decode(msg.getPayloadString()!.toString());
        menuItems.remove(StorableString(menuString));
        try {
          sendMessage(
              msg.getSourceId()!,
              Message(
                  msg.getTargetId(),
                  msg.getSourceId(),
                  MessageType.COMAPI_SUCCESS,
                  GeigerUrl(msg.getSourceId()!, 'deregisterMenu')));
        } on MalformedUrlException {
          // TODO proper Error handling
          // this should never occur
        }
        break;
      case MessageType.REGISTER_PLUGIN:
        registerPlugin(msg.getSourceId(),
            PluginInformation.fromByteArray(msg.getPayload()!));
        try {
          sendMessage(
              msg.getSourceId()!,
              Message(
                  msg.getTargetId(),
                  msg.getSourceId(),
                  MessageType.COMAPI_SUCCESS,
                  GeigerUrl(msg.getSourceId()!, 'registerPlugin')));
        } on MalformedUrlException {
          // TODO proper Error handling
          // this should never occur
        }
        break;
      case MessageType.DEREGISTER_PLUGIN:
        deregisterPlugin(msg.getSourceId());
        try {
          sendMessage(
              msg.getSourceId()!,
              Message(
                  msg.getTargetId(),
                  msg.getSourceId(),
                  MessageType.COMAPI_SUCCESS,
                  GeigerUrl(msg.getSourceId()!, 'deregisterPlugin')));
        } on MalformedUrlException {
          // TODO proper Error handling
          // this should never occur
        }
        break;
      case MessageType.ACTIVATE_PLUGIN:
        {
          // get and remove old info
          var pluginInfo = plugins[StorableString(msg.getSourceId()!)]!;
          plugins.remove(StorableString(msg.getSourceId()!));
          // put new info
          var port = GeigerCommunicator.byteArrayToInt(msg.getPayload()!);
          plugins[StorableString(msg.getSourceId()!)] =
              PluginInformation(pluginInfo.getExecutable(), port);
          try {
            sendMessage(
                msg.getSourceId()!,
                Message(
                    msg.getTargetId(),
                    msg.getSourceId(),
                    MessageType.COMAPI_SUCCESS,
                    GeigerUrl(msg.getSourceId()!, 'activatePlugin')));
          } on MalformedUrlException {
            // TODO proper Error handling
            // this should never occur
          }
          break;
        }
      case MessageType.DEACTIVATE_PLUGIN:
        {
          // remove port from plugin info
          // get and remove old info
          var pluginInfo = plugins[StorableString(msg.getSourceId()!)]!;
          plugins.remove(StorableString(msg.getSourceId()!));
          // put new info
          plugins[StorableString(msg.getSourceId()!)] =
              PluginInformation(pluginInfo.getExecutable(), 0);
          try {
            sendMessage(
                msg.getSourceId()!,
                Message(
                    msg.getTargetId(),
                    msg.getSourceId(),
                    MessageType.COMAPI_SUCCESS,
                    GeigerUrl(msg.getSourceId()!, 'deactivatePlugin')));
          } on MalformedUrlException {
            // TODO proper Error handling
            // this should never occur
          }
          break;
        }
      case MessageType.REGISTER_LISTENER:
        {
          // TODO after pluginListener serialization
          var payload = msg.getPayload()!;
          var intRange = payload.sublist(0, 4);
          var inputRange = payload.sublist(4, payload.length);
          var length = GeigerCommunicator.byteArrayToInt(intRange);
          // workaround, register for all events always until messagetype serialization is available
          var events = [MessageType.ALL_EVENTS];
          ByteArrayInputStream in_ = ByteArrayInputStream(inputRange);
          // var events = List<MessageType>.empty(growable: true);
          for (var j = 0; j < length; ++j) {
            // TODO deserialize messagetypes

          }
          // TODO deserialize Pluginlistener
          PluginListener? listener;
          for (var e in events) {
            // synchronized(listeners) {
            var l = listeners[e];
            // short form with computeIfAbsent is not available in TotalCross
            if (l == null) {
              l = List.empty(growable: true);
              listeners[e] = l;
            }
            if (e.getId() < 10000) {
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
        if (isMaster) {
          scanButtonPressed();
        }
        // if its not the Master there should be a listener registered for this event
        break;
      case MessageType.PING:
        {
          // answer with PONG
          try {
            sendMessage(
                msg.getSourceId()!,
                Message(msg.getTargetId(), msg.getSourceId(), MessageType.PONG,
                    GeigerUrl(msg.getSourceId()!, ''), msg.getPayload()));
          } on MalformedUrlException {
            // TODO proper Error handling
            // this should never occur
          }
          break;
        }
      default:
        // all other messages are not handled internally
        break;
    }
    for (var mt in [MessageType.ALL_EVENTS, msg.getType()]) {
      var l = listeners[mt];
      if (l != null) {
        for (var pl in l) {
          print('## notifying PluginListener ' +
              pl.toString() +
              ' for msg ' +
              msg.getType().toString() +
              ' ' +
              msg.getAction().toString());
          pl.pluginEvent(msg.getAction()!, msg);

          print('## PluginEvent fired');
        }
      }
    }
  }

  @override
  void registerMenu(String menu, GeigerUrl action) {
    try {
      sendMessage(
          MASTER,
          Message(
              id,
              MASTER,
              MessageType.REGISTER_MENU,
              GeigerUrl(MASTER, 'registerMenu'),
              MenuItem(menu, action).toByteArray()));
    } on MalformedUrlException {
      // TODO proper Error handling
      // this should never occur
    }
  }

  @override
  void enableMenu(String menu) {
    try {
      sendMessage(
          MASTER,
          Message(id, MASTER, MessageType.ENABLE_MENU,
              GeigerUrl(MASTER, 'enableMenu'), utf8.encode(menu)));
    } on MalformedUrlException {
      // TODO proper Error handling
      // this should never occur
    }
  }

  @override
  void disableMenu(String menu) {
    try {
      sendMessage(
          MASTER,
          Message(id, MASTER, MessageType.DISABLE_MENU,
              GeigerUrl(MASTER, 'disableMenu'), utf8.encode(menu)));
    } on MalformedUrlException {
      // TODO proper Error handling
      // this should never occur
    }
  }

  @override
  void deregisterMenu(String menu) {
    try {
      sendMessage(
          MASTER,
          Message(id, MASTER, MessageType.DEREGISTER_MENU,
              GeigerUrl(MASTER, 'deregisterMenu'), utf8.encode(menu)));
    } on MalformedUrlException {
      // TODO proper Error handling
      // this should never occur
    }
  }

  @override
  void menuPressed(GeigerUrl url) {
    sendMessage(url.getPlugin(),
        Message(MASTER, url.getPlugin(), MessageType.MENU_PRESSED, url, null));
  }

  @override
  List<MenuItem> getMenuList() {
    return menuItems.values.toList();
  }

  @override
  void scanButtonPressed() {
    // TODO
    if (!isMaster) {
      try {
        sendMessage(
            MASTER,
            Message(id, MASTER, MessageType.SCAN_PRESSED,
                GeigerUrl(MASTER, 'scanPressed')));
      } on MalformedUrlException {
        // TODO proper Error handling
        // this should never occur
      }
    } else {
      broadcastMessage(Message(MASTER, null, MessageType.SCAN_PRESSED, null));
    }
  }

  /// Start a plugin of [pluginInformation] by using the stored executable String.
  void startPlugin(PluginInformation pluginInformation) {
    PluginStarter.startPlugin(pluginInformation);
  }
}
