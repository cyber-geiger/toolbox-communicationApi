package eu.cybergeiger.communication;

import ch.fhnw.geiger.localstorage.StorageController;
import ch.fhnw.geiger.localstorage.StorageException;
import ch.fhnw.geiger.localstorage.db.GenericController;
import ch.fhnw.geiger.localstorage.db.mapper.H2SqlMapper;
import ch.fhnw.geiger.totalcross.ByteArrayInputStream;
import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;
import eu.cybergeiger.totalcross.Base64;
import eu.cybergeiger.totalcross.File;
import eu.cybergeiger.totalcross.MalformedUrlException;
import eu.cybergeiger.totalcross.PluginStarter;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;


/**
 * <p>Offers an API for all plugins to access the local toolbox.</p>
 */
public class LocalApi implements CommunicatorApi {

  public static final String MASTER = "__MASTERPLUGIN__";

  private static final StorableHashMap<StorableString, PluginInformation> plugins =
      new StorableHashMap<>();
  private static final StorableHashMap<StorableString, MenuItem> menuItems =
      new StorableHashMap<>();

  //private static final Logger log = Logger.getLogger("LocalAPI");

  private final String executor;
  private final String id;
  private final boolean isMaster;
  private final Declaration declaration;

  private final Map<MessageType, List<PluginListener>> listeners
      = Collections.synchronizedMap(new HashMap<>());

  private GeigerCommunicator geigerCommunicator;

  /**
   * <p>Constructor called by LocalApiFactory.</p>
   *
   * @param executor    the executor string of the plugin
   * @param id          the id of the plugin
   * @param isMaster    true if the current API should denote a master
   * @param declaration declaration of data sharing
   * @throws StorageException if the StorageController could not be initialized
   */
  protected LocalApi(String executor, String id, boolean isMaster, Declaration declaration)
      throws StorageException {
    this.executor = executor;
    this.id = id;
    this.isMaster = isMaster;
    this.declaration = declaration;

    restoreState();

    PluginListener storageEventHandler;
    if (!isMaster) {
      // it is a plugin
      try {
        geigerCommunicator = new GeigerClient(this);
        geigerCommunicator.start();
        registerPlugin();
        activatePlugin(geigerCommunicator.getPort());
      } catch (IOException e) {
        // TODO error handling
        e.printStackTrace();
      }
      // TODO should the passtroughcontroller be listener?
      storageEventHandler = new PasstroughController(this, id);

    } else {
      // it is master
      try {
        geigerCommunicator = new GeigerServer(this);
        geigerCommunicator.start();
      } catch (IOException e) {
        // TODO error handling
        e.printStackTrace();
      }
      storageEventHandler = new StorageEventHandler(this, getStorage());
    }
    registerListener(new MessageType[]{MessageType.STORAGE_EVENT}, storageEventHandler);
  }

  /**
   * <p>Returns the declaration given upon creation.</p>
   *
   * @return the current declaration
   */
  public Declaration getDeclaration() {
    return declaration;
  }

  @Override
  public void registerPlugin() {
    // TODO share secret in a secure paired way....
    //PluginInformation pi = new PluginInformation();
    //CommunicationSecret secret = new CommunicationSecret();
    //secrets.put(id, secret);

    // request to register at Master
    PluginInformation pluginInformation = new PluginInformation(this.executor,
        geigerCommunicator.getPort());
    try {
      sendMessage(LocalApi.MASTER, new Message(id, LocalApi.MASTER,
          MessageType.REGISTER_PLUGIN, new GeigerUrl(MASTER, "registerPlugin"),
          pluginInformation.toByteArray()));
    } catch (MalformedUrlException e) {
      // TODO proper handling
      // this should never occur
    }
  }

  private void registerPlugin(String id, PluginInformation info) {
    if (!plugins.containsKey(new StorableString(id))) {
      plugins.put(new StorableString(id), info);
    }
  }

  @Override
  public void deregisterPlugin() throws IllegalArgumentException {
    // TODO getting the id of the plugin itself doesnt make sense
    if (plugins.get(new StorableString(id)) == null) {
      throw new IllegalArgumentException("no communication secret found for id \"" + id + "\"");
    }
    // first deactivate, then deregister at Master, before deleting my own entries.
    deactivatePlugin();
    try {
      sendMessage(LocalApi.MASTER, new Message(id, LocalApi.MASTER,
          MessageType.DEREGISTER_PLUGIN, new GeigerUrl(MASTER, "deregisterPlugin")));
    } catch (MalformedUrlException e) {
      // TODO proper error handling
      // this should never occur
    }
    zapState();
  }

  private void deregisterPlugin(String id) {
    // remove on master all menu items
    if (isMaster) {
      synchronized (menuItems) {
        List<String> l = new Vector<>();
        for (Map.Entry<StorableString, MenuItem> i : menuItems.entrySet()) {
          if (i.getValue().getAction().getPlugin().equals(id)) {
            l.add(i.getKey().toString());
          }
        }
        for (String key : l) {
          menuItems.remove(new StorableString(key));
        }
      }
    }

    // remove plugin secret
    plugins.remove(new StorableString(id));

    storeState();
  }

  /**
   * <p>Deletes all current registered items.</p>
   */
  public void zapState() {
    synchronized (menuItems) {
      menuItems.clear();
    }
    synchronized (plugins) {
      plugins.clear();
    }
    storeState();
  }

  private void storeState() {
    // store plugin state
    try {
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      synchronized (plugins) {
        plugins.toByteArrayStream(out);
      }
      synchronized (menuItems) {
        menuItems.toByteArrayStream(out);
      }
      new File().writeAllBytes("LocalAPI." + id + ".state", out.toByteArray());
    } catch (Throwable ioe) {
      //System.out.println("===============================================U");
      //ioe.printStackTrace();
      //System.out.println("===============================================L");
    }
  }

  private void restoreState() {
    String fname = "LocalAPI." + id + ".state";
    try {
      byte[] buff = new File().readAllBytes(fname);
      if (buff == null) {
        buff = new byte[0];
      }
      ByteArrayInputStream in = new ByteArrayInputStream(buff);
      // restoring plugin information
      synchronized (plugins) {
        StorableHashMap.fromByteArrayStream(in, plugins);
      }
      // restoring menu information
      synchronized (menuItems) {
        StorableHashMap.fromByteArrayStream(in, menuItems);
      }
    } catch (Throwable e) {
      storeState();
    }
  }

  @Override
  public void activatePlugin(int port) {
    sendMessage(MASTER, new Message(id, MASTER, MessageType.ACTIVATE_PLUGIN, null,
        GeigerCommunicator.intToByteArray(port)));
  }

  @Override
  public void deactivatePlugin() {
    sendMessage(MASTER, new Message(id, MASTER, MessageType.DEACTIVATE_PLUGIN, null));
  }

  /**
   * <p>Obtain controller to access the storage.</p>
   *
   * @return a generic controller providing access to the local storage
   */
  public StorageController getStorage() throws StorageException {
    if (isMaster) {
      // TODO remove hardcoded DB information
      return new GenericController(id, new H2SqlMapper("jdbc:h2:./testdb;AUTO_SERVER=TRUE",
          "sa2", "1234"));
    } else {
      return new PasstroughController(this, id);
    }
  }

  @Override
  public void registerListener(MessageType[] events, PluginListener listener) {
    if (isMaster) {
      for (MessageType e : events) {
        synchronized (listeners) {
          List<PluginListener> l = listeners.get(e);
          // The short form computeIfAbsent is not available in TotalCross
          if (l == null) {
            l = new Vector<>();
            listeners.put(e, l);
          }
          if (e.getId() < 10000) {
            l.add(listener);
          }
        }
      }
    } else {
      // format: int number of events -> events -> listener
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      out.write(GeigerCommunicator.intToByteArray(events.length));
      for (MessageType event : events) {
        out.write(GeigerCommunicator.intToByteArray(event.ordinal()));
      }
      // out.write(listener.toByteArray());
      try {
        sendMessage(MASTER, new Message(id, MASTER, MessageType.REGISTER_LISTENER,
            new GeigerUrl(LocalApi.MASTER, "registerListener"), out.toByteArray()));
      } catch (MalformedUrlException e) {
        // TODO proper handling
        // this should never occur
      }
    }
  }

  /**
   * <p>Remove a listener waiting for Events.</p>
   *
   * @param events   the events affected or null if the listener should be removed from all events
   * @param listener the listener to be removed
   */
  public void deregisterListener(MessageType[] events, PluginListener listener) {
    if (events == null) {
      events = MessageType.values();
    }
    for (MessageType e : events) {
      synchronized (listeners) {
        List<PluginListener> l = listeners.get(e);
        if (l != null) {
          l.remove(listener);
        }
      }
    }
  }

  @Override
  public void sendMessage(String pluginId, Message msg) {
    if (id.equals(pluginId)) {
      // communicate locally
      receivedMessage(plugins.get(new StorableString(this.id)), msg);
    } else {
      // communicate with foreign plugin
      PluginInformation pluginInformation = plugins.get(new StorableString(pluginId));
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

  /**
   * <p>broadcasts a message to all known plugins.</p>
   *
   * @param msg the message to be broadcast
   */
  private void broadcastMessage(Message msg) {
    for (Map.Entry<StorableString, PluginInformation> plugin : plugins.entrySet()) {
      sendMessage(plugin.getKey().toString(),
          new Message(MASTER, plugin.getKey().toString(), msg.getType(), msg.getAction(),
              msg.getPayload()));
    }
  }

  void receivedMessage(PluginInformation info, Message msg) {
    // TODO other messagetypes
    MenuItem i;
    switch (msg.getType()) {
      case ENABLE_MENU:
        i = menuItems.get(new StorableString(msg.getPayloadString()));
        if (i != null) {
          i.setEnabled(true);
        }
        try {
          sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
              MessageType.COMAPI_SUCCESS, new GeigerUrl(msg.getSourceId(), "enableMenu")));
        } catch (MalformedUrlException e) {
          // TODO proper Error handling
          // this should never occur
        }
        break;
      case DISABLE_MENU:
        i = menuItems.get(new StorableString(msg.getPayloadString()));
        if (i != null) {
          i.setEnabled(false);
        }
        try {
          sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
              MessageType.COMAPI_SUCCESS, new GeigerUrl(msg.getSourceId(), "disableMenu")));
        } catch (MalformedUrlException e) {
          // TODO proper Error handling
          // this should never occur
        }
        break;
      case REGISTER_MENU:
        i = MenuItem.fromByteArray(msg.getPayload());
        menuItems.put(new StorableString(i.getMenu()), i);
        try {
          sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
              MessageType.COMAPI_SUCCESS, new GeigerUrl(msg.getSourceId(), "registerMenu")));
        } catch (MalformedUrlException e) {
          // TODO proper Error handling
          // this should never occur
        }
        break;
      case DEREGISTER_MENU:
        String menuString = new String(Base64.decode(msg.getPayloadString()));
        menuItems.remove(new StorableString(menuString));
        try {
          sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
              MessageType.COMAPI_SUCCESS, new GeigerUrl(msg.getSourceId(), "deregisterMenu")));
        } catch (MalformedUrlException e) {
          // TODO proper Error handling
          // this should never occur
        }
        break;
      case REGISTER_PLUGIN:
        registerPlugin(msg.getSourceId(), PluginInformation.fromByteArray(msg.getPayload()));
        try {
          sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
              MessageType.COMAPI_SUCCESS, new GeigerUrl(msg.getSourceId(), "registerPlugin")));
        } catch (MalformedUrlException e) {
          // TODO proper Error handling
          // this should never occur
        }
        break;
      case DEREGISTER_PLUGIN:
        deregisterPlugin(msg.getSourceId());
        try {
          sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
              MessageType.COMAPI_SUCCESS, new GeigerUrl(msg.getSourceId(), "deregisterPlugin")));
        } catch (MalformedUrlException e) {
          // TODO proper Error handling
          // this should never occur
        }
        break;
      case ACTIVATE_PLUGIN: {
        // get and remove old info
        PluginInformation pluginInfo = plugins.get(new StorableString(msg.getSourceId()));
        plugins.remove(new StorableString(msg.getSourceId()));
        // put new info
        int port = GeigerCommunicator.byteArrayToInt(msg.getPayload());
        plugins.put(new StorableString(msg.getSourceId()),
            new PluginInformation(pluginInfo.getExecutable(), port));
        try {
          sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
              MessageType.COMAPI_SUCCESS, new GeigerUrl(msg.getSourceId(), "activatePlugin")));
        } catch (MalformedUrlException e) {
          // TODO proper Error handling
          // this should never occur
        }
        break;
      }
      case DEACTIVATE_PLUGIN: {
        // remove port from plugin info
        // get and remove old info
        PluginInformation pluginInfo = plugins.get(new StorableString(msg.getSourceId()));
        plugins.remove(new StorableString(msg.getSourceId()));
        // put new info
        plugins.put(new StorableString(msg.getSourceId()),
            new PluginInformation(pluginInfo.getExecutable(), 0));
        try {
          sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
              MessageType.COMAPI_SUCCESS,
              new GeigerUrl(msg.getSourceId(), "deactivatePlugin")));
        } catch (MalformedUrlException e) {
          // TODO proper Error handling
          // this should never occur
        }
        break;
      }
      case REGISTER_LISTENER: {
        // TODO after pluginListener serialization
        byte[] payload = msg.getPayload();
        byte[] intRange = Arrays.copyOfRange(payload, 0, 4);
        byte[] inputRange = Arrays.copyOfRange(payload, 4, payload.length);
        int length = GeigerCommunicator.byteArrayToInt(intRange);
        ByteArrayInputStream in = new ByteArrayInputStream(inputRange);
        MessageType[] events = new MessageType[length];
        for (int j = 0; j < length; ++j) {
          // TODO deserialize messagetypes

        }
        // TODO deserialize Pluginlistener
        PluginListener listener = null;
        for (MessageType e : events) {
          synchronized (listeners) {
            List<PluginListener> l = listeners.get(e);
            // short form with computeIfAbsent is not available in TotalCross
            if (l == null) {
              l = new Vector<>();
              listeners.put(e, l);
            }
            if (e.getId() < 10000) {
              l.add(listener);
            }
          }
        }
        break;
      }
      case DEREGISTER_LISTENER: {
        // TODO after PluginListener serialization
        // remove listener from list if it is in list
        break;
      }
      case SCAN_PRESSED:
        if (isMaster) {
          scanButtonPressed();
        }
        // if its not the Master there should be a listener registered for this event
        break;
      case PING: {
        // answer with PONG
        try {
          sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
              MessageType.PONG, new GeigerUrl(msg.getSourceId(), ""), msg.getPayload()));
        } catch (MalformedUrlException e) {
          // TODO proper Error handling
          // this should never occur
        }
        break;
      }
      default:
        // all other messages are not handled internally
        break;
    }
    for (MessageType mt : new MessageType[]{MessageType.ALL_EVENTS, msg.getType()}) {
      List<PluginListener> l = listeners.get(mt);
      if (l != null) {
        for (PluginListener pl : l) {
          pl.pluginEvent(msg.getAction(), msg);
        }
      }
    }
  }

  @Override
  public void registerMenu(String menu, GeigerUrl action) {
    try {
      sendMessage(MASTER, new Message(id, MASTER, MessageType.REGISTER_MENU,
          new GeigerUrl(MASTER, "registerMenu"), new MenuItem(menu, action).toByteArray()));
    } catch (MalformedUrlException e) {
      // TODO proper Error handling
      // this should never occur
    }
  }

  @Override
  public void enableMenu(String menu) {
    try {
      sendMessage(MASTER, new Message(id, MASTER, MessageType.ENABLE_MENU,
          new GeigerUrl(MASTER, "enableMenu"), menu.getBytes(StandardCharsets.UTF_8)));
    } catch (MalformedUrlException e) {
      // TODO proper Error handling
      // this should never occur
    }
  }

  @Override
  public void disableMenu(String menu) {
    try {
      sendMessage(MASTER, new Message(id, MASTER, MessageType.DISABLE_MENU,
          new GeigerUrl(MASTER, "disableMenu"), menu.getBytes(StandardCharsets.UTF_8)));
    } catch (MalformedUrlException e) {
      // TODO proper Error handling
      // this should never occur
    }
  }

  @Override
  public void deregisterMenu(String menu) {
    try {
      sendMessage(MASTER, new Message(id, MASTER, MessageType.DEREGISTER_MENU,
          new GeigerUrl(MASTER, "deregisterMenu"), menu.getBytes(StandardCharsets.UTF_8)));
    } catch (MalformedUrlException e) {
      // TODO proper Error handling
      // this should never occur
    }
  }

  @Override
  public void menuPressed(GeigerUrl url) {
    sendMessage(url.getPlugin(), new Message(MASTER, url.getPlugin(),
        MessageType.MENU_PRESSED, url, null));
  }

  @Override
  public List<MenuItem> getMenuList() {
    return new Vector<>(menuItems.values());
  }

  @Override
  public void scanButtonPressed() {
    // TODO
    if (!isMaster) {
      try {
        sendMessage(MASTER, new Message(id, MASTER, MessageType.SCAN_PRESSED,
            new GeigerUrl(MASTER, "scanPressed")));
      } catch (MalformedUrlException e) {
        // TODO proper Error handling
        // this should never occur
      }
    } else {
      broadcastMessage(new Message(MASTER, null, MessageType.SCAN_PRESSED, null));
    }
  }

  /**
   * <p>Start a plugin by using the stored executable String.</p>
   *
   * @param pluginInformation the Information of the plugin to start
   */
  private void startPlugin(PluginInformation pluginInformation) {
    PluginStarter.startPlugin(pluginInformation);
  }
}
