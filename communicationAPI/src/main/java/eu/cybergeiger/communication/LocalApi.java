package eu.cybergeiger.communication;

import ch.fhnw.geiger.localstorage.StorageController;
import ch.fhnw.geiger.localstorage.db.GenericController;
import ch.fhnw.geiger.localstorage.db.mapper.H2SqlMapper;
import ch.fhnw.geiger.totalcross.ByteArrayInputStream;
import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;
import eu.cybergeiger.totalcross.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;
import totalcross.util.Logger;


/**
 * <p>Offers an API for all plugins to access the local toolbox.</p>
 */
public class LocalApi implements PluginRegistrar, MenuRegistrar {

  public static final String MASTER = "__MASTERPLUGIN__";

  private static final StorableHashMap<StorableString, PluginInformation> plugins =
      new StorableHashMap<>();
  private static final StorableHashMap<StorableString, MenuItem> menuItems =
      new StorableHashMap<>();

  private static final Logger log = Logger.getLogger("LocalAPI");

  private final String executor;
  private final String id;
  private final boolean isMaster;
  private Declaration declaration;

  private final Map<MessageType, List<PluginListener>> listeners
      = Collections.synchronizedMap(new HashMap<>());

  private GeigerCommunicator geigerCommunicator;
  private final PluginListener storageEventHandler;

  /**
   * <p>Constructor called by LocalApiFactory.</p>
   *
   * @param executor    the executor string of the plugin
   * @param id          the id of the plugin
   * @param isMaster    true if the current API should denote a master
   * @param declaration declaration of data sharing
   */
  protected LocalApi(String executor, String id, boolean isMaster, Declaration declaration) {
    this.executor = executor;
    this.id = id;
    this.isMaster = isMaster;
    this.declaration = declaration;

    restoreState();

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
  }

  private void registerPlugin(String id, PluginInformation info) {
    if (!plugins.containsKey(id)) {
      plugins.put(new StorableString(id), info);
    }
  }

  @Override
  public void deregisterPlugin() throws IllegalArgumentException {
    if (plugins.get(id) == null) {
      throw new IllegalArgumentException("no communication secret found for id \"" + id + "\"");
    }
    deactivatePlugin();
    zapState();
  }

  private void deregisterPlugin(String id) {
    // remove on master all menu items
    if (isMaster) {
      synchronized (menuItems) {
        List<String> l = new Vector<>();
        for (Map.Entry<StorableString, MenuItem> i : menuItems.entrySet()) {
          if (i.getValue().getAction().equals(id)) {
            l.add(i.getKey().toString());
          }
        }
        for (String key : l) {
          menuItems.remove(key);
        }
      }
    }

    // remove plugin secret
    plugins.remove(id);

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
    } catch (IOException ioe) {
      ioe.printStackTrace();
    }
  }

  private void restoreState() {
    try {
      ByteArrayInputStream in = new ByteArrayInputStream(
          new File().readAllBytes("LocalAPI." + id + ".state")
      );
      // restoring plugin information
      synchronized (plugins) {
        StorableHashMap.fromByteArrayStream(in, plugins);
      }
      // restoring menu information
      synchronized (menuItems) {
        StorableHashMap.fromByteArrayStream(in, menuItems);
      }
    } catch (IOException e) {
      e.printStackTrace();
    }
  }

  /**
   * <p>Activates the plugin and sets up communication.</p>
   */
  public void activatePlugin(int port) {
    sendMessage(MASTER, new Message(id, MASTER, MessageType.ACTIVATE_PLUGIN, null,
        String.valueOf(port).getBytes(StandardCharsets.UTF_8)));
  }

  /**
   * <p>deactivates the plugin and makes sure that a plugin is started immediately if contacted.</p>
   *
   * <p>If a plugin is properly deactivated no timeout is reached before contacting a plugin.</p>
   */
  public void deactivatePlugin() {
    sendMessage(MASTER, new Message(id, MASTER, MessageType.DEACTIVATE_PLUGIN, null));
  }

  /**
   * <p>Obtain controller to access the storage.</p>
   *
   * @return a generic controller providing access to the local storage
   */
  public StorageController getStorage() {
    if (isMaster) {
      // TODO remove hardcoded DB information
      return new GenericController(id, new H2SqlMapper("jdbc:h2:./testdb;AUTO_SERVER=TRUE",
          "sa2", "1234"));
    } else {
      return new PasstroughController(this, id);
    }
  }

  /**
   * <p>Register an event listener for specific events.</p>
   *
   * @param events   list of events for which messages should be received. Use MessageType.
   *                 ALL_EVENTS to register for all messages.
   * @param listener the listener to be registered
   */
  public void registerListener(MessageType[] events, PluginListener listener) {
    for (MessageType e : events) {
      synchronized (listeners) {
        List<PluginListener> l = listeners.get(e);
        if (l == null) {
          l = new Vector<>();
          listeners.put(e, l);
        }
        if (e.getId() < 10000) {
          l.add(listener);
        }
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

  /**
   * <p>Send a custom message to a plugin.</p>
   *
   * <p>Mainly used for internal purposes. Plugins may only send messages to the toolbox core.</p>
   *
   * @param pluginId The plugin id to be contacted
   * @param msg      the message to be sent
   */
  public void sendMessage(String pluginId, Message msg) {
    geigerCommunicator.sendMessage(plugins.get(pluginId), msg);
  }

  /**
   * <p>broadcasts a message to all known plugins.</p>
   *
   * @param msg the message to be broadcasted
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
      case MENU_ACTIVE:
        i = menuItems.get(msg.getPayloadString());
        if (i != null) {
          i.setEnabled(true);
        }
        break;
      case MENU_INACTIVE:
        i = menuItems.get(msg.getPayloadString());
        if (i != null) {
          i.setEnabled(false);
        }
        break;
      case REGISTER_MENU:
        i = MenuItem.fromByteArray(msg.getPayload());
        menuItems.put(new StorableString(i.getMenu()), i);
        break;
      case DEREGISTER_MENU:
        menuItems.remove(msg.getPayloadString());
        break;
      case DEREGISTER_PLUGIN:
        deregisterPlugin(msg.getPayloadString());
        break;
      case REGISTER_PLUGIN:
        registerPlugin(msg.getSourceId(), PluginInformation.fromByteArray(msg.getPayload()));
        break;
      case ACTIVATE_PLUGIN: {
        // get and remove old info
        PluginInformation pluginInfo = plugins.get(new StorableString(msg.getSourceId()));
        plugins.remove(new StorableString(msg.getSourceId()));
        // put new info
        plugins.put(new StorableString(msg.getSourceId()),
            new PluginInformation(pluginInfo.getExecutable(),
                GeigerCommunicator.byteArrayToInt(msg.getPayload())));
        break;
      }
      case DEACTIVATE_PLUGIN: {
        // simply remove port from plugin info
        // get and remove old info
        PluginInformation pluginInfo = plugins.get(new StorableString(msg.getSourceId()));
        plugins.remove(new StorableString(msg.getSourceId()));
        // put new info
        plugins.put(new StorableString(msg.getSourceId()),
            new PluginInformation(pluginInfo.getExecutable(), 0));
        break;
      }
      case PING: {
        // answer with PONG
        sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(),
            MessageType.PONG, new GeigerUrl(msg.getSourceId(), ""), msg.getPayload()));
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
    sendMessage(MASTER, new Message(id, MASTER, MessageType.REGISTER_MENU,
        null, new MenuItem(menu, action).toByteArray()));
  }

  @Override
  public void enableMenu(String menu) {
    sendMessage(MASTER, new Message(id, MASTER, MessageType.MENU_ACTIVE,
        null, menu.getBytes(StandardCharsets.UTF_8)));
  }

  @Override
  public void disableMenu(String menu) {
    sendMessage(MASTER, new Message(id, MASTER, MessageType.MENU_INACTIVE,
        null, menu.getBytes(StandardCharsets.UTF_8)));
  }

  @Override
  public void deregisterMenu(String menu) {
    sendMessage(MASTER, new Message(id, MASTER, MessageType.DEREGISTER_MENU,
        null, menu.getBytes(StandardCharsets.UTF_8)));
  }

  /**
   * <p>notify plugin about a menu entry pressed.</p>
   *
   * @param url the GeigerURL associated with the menu entry
   */
  public void menuPressed(GeigerUrl url) {
    sendMessage(url.getPlugin(), new Message(MASTER, url.getPlugin(),
        MessageType.MENU_PRESSED, url, null));
  }

  /**
   * <p>Returns the List of currently registered menu.</p>
   *
   * <p>This call is for the toolbox core only.</p>
   *
   * @return the list of currently registered menus
   */
  public List<MenuItem> getMenuList() {
    return new Vector<>();
  }

  /**
   * <p>Notify all plugins about the event that a scan button has been pressed.</p>
   *
   * <p>This call is for the toolbox core only.</p>
   */
  public void scanButtonPressed() {
    broadcastMessage(new Message(MASTER, null, MessageType.SCAN_PRESSED, null));
  }

}
