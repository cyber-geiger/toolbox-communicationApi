package eu.cybergeiger.communication;

import ch.fhnw.geiger.localstorage.StorageController;
import ch.fhnw.geiger.localstorage.db.GenericController;
import ch.fhnw.geiger.localstorage.db.mapper.H2SqlMapper;
import eu.cybergeiger.communication.communicator.GeigerClient;
import eu.cybergeiger.communication.communicator.GeigerCommunicator;
import eu.cybergeiger.communication.communicator.GeigerServer;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;
import totalcross.util.HashMap4D;
import totalcross.util.Logger;


/**
 * <p>Offers an API for all plugins to access the local toolbox.</p>
 */
public class LocalApi implements PluginRegistrar, MenuRegistrar {

  public static final String MASTER = "__MASTERPLUGIN__";

  private static final Map<String, PluginInformation> plugins = new HashMap<>(1);
  private static final Map<String, MenuItem> menuItems = new HashMap<>(0);

  private static final Logger log = Logger.getLogger("LocalAPI");

  private final String executor;
  private final String id;
  private final boolean isMaster;
  private Declaration declaration;

  private final Map<MessageType, List<PluginListener>> listeners
      = Collections.synchronizedMap(new HashMap4D<>());

  private final GeigerCommunicator geigerCommunicator;

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

    // TODO reactivate after implementation
    //restoreState();

    // TODO state store/restore
    //restoreState();

    if (!isMaster) {
      // it is a plugin
      geigerCommunicator = new GeigerClient();
      registerPlugin();
      activatePlugin(geigerCommunicator.getPort());
    } else {
      // it is master
      geigerCommunicator = new GeigerServer();
    }

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
    // TODO write!
  }

  @Override
  public void deregisterPlugin() {
    if (plugins.get(id) == null) {
      // TODO javax.NameNotFoundException does not exists in totalcross
      //throw new NameNotFoundException("no communication secret found for id \"" + id + "\"");
    }
    deactivatePlugin();
    zapState();
  }

  private void deregisterPlugin(String id) {
    // remove on master all menu items
    if (isMaster) {
      synchronized (menuItems) {
        List<String> l = new Vector<>();
        for (Map.Entry<String, MenuItem> i : menuItems.entrySet()) {
          if (i.getValue().getAction().equals(id)) {
            l.add(i.getKey());
          }
        }
        for (String key : l) {
          menuItems.remove(key);
        }
      }
    }

    // remove plugin secret
    plugins.remove(id);

    //storeState();
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
    // TODO reactivate after implementation
    //storeState();
  }

  // TODO rewrite storeState and restoreState with totalcross classes
//  private void storeState() {
//    // store plugin state
//    try (ObjectOutputStream out = new ObjectOutputStream(
//        Files.newOutputStream(Paths.get("LocalAPI." + id + ".state"))
//    )
//    ) {
//      synchronized (secrets) {
//        out.writeInt(secrets.size());
//        for (Map.Entry<String, PluginInformation> e : secrets.entrySet()) {
//          out.writeObject(e.getKey());
//          out.writeObject(e.getValue());
//        }
//      }
//      synchronized (menuItems) {
//        out.writeInt(menuItems.size());
//        for (Map.Entry<String, MenuItem> e : menuItems.entrySet()) {
//          out.writeObject(e.getKey());
//          out.writeObject(e.getValue());
//        }
//      }
//    } catch (IOException ioe) {
//      log.log(Level.SEVERE, "persisting LocalAPI state", ioe);
//    }
//  }
//
//  private void restoreState() {
//    try (ObjectInputStream in = new ObjectInputStream(Files.newInputStream(
//        Paths.get("LocalAPI." + id + ".state")
//    ))) {
//      // restoring plugin information
//      int mapSize = in.readInt();
//      Map<String, PluginInformation> l = new HashMap<>(mapSize);
//      for (int i = 0; i < mapSize; i++) {
//        l.put((String) (in.readObject()), (PluginInformation) (in.readObject()));
//      }
//      synchronized (secrets) {
//        secrets.clear();
//        secrets.putAll(l);
//      }
//
//      // restoring menu information
//      mapSize = in.readInt();
//      Map<String, MenuItem> l2 = new HashMap<>(mapSize);
//      for (int i = 0; i < mapSize; i++) {
//        l2.put((String) (in.readObject()), (MenuItem) (in.readObject()));
//      }
//      synchronized (menuItems) {
//        menuItems.clear();
//        menuItems.putAll(l2);
//      }
//    } catch (IOException | ClassNotFoundException e) {
//      log.log(Level.SEVERE, "persisting LocalAPI state", e);
//    }
//  }

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
    // TODO implementation passthru missing
    return new GenericController(id, new H2SqlMapper("jdbc:h2:./testdb;AUTO_SERVER=TRUE",
        "sa2", "1234"));
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
  private void sendMessage(String pluginId, Message msg) {
    // TODO: reimplement for communication version
//    LocalApi api = LocalApiFactory.getLocalApi(pluginId);
//    api.receivedMessage(PluginInformationFactory.getPluginInformation(id),
//        new Message(id, pluginId, msg.getType(), msg.getAction(), msg.getPayload()));
    geigerCommunicator.sendMessage(plugins.get(pluginId), msg);
  }

  /**
   * <p>broadcasts a message to all known plugins.</p>
   *
   * @param msg the message to be broadcasted
   */
  private void broadcastMessage(Message msg) {
    for (Map.Entry<String, PluginInformation> plugin : plugins.entrySet()) {
      sendMessage(plugin.getKey(),
          new Message(MASTER, plugin.getKey(), msg.getType(), msg.getAction(), msg.getPayload()));
    }
  }

  private void receivedMessage(PluginInformation info, Message msg) {
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
        i = (MenuItem) (toObject(msg.getPayload()));
        menuItems.put(i.getMenu(), i);
        break;
      case DEREGISTER_MENU:
        menuItems.remove(msg.getPayloadString());
        break;
      case DEREGISTER_PLUGIN:
        deregisterPlugin(msg.getPayloadString());
        break;
      case REGISTER_PLUGIN:
        registerPlugin(msg.getSourceId(), (PluginInformation) (toObject(msg.getPayload())));
        break;
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
    //sendMessage(MASTER, new Message(id, MASTER, MessageType.REGISTER_MENU,
    // null, toByteArray(new MenuItem(menu, action))));
  }

  @Override
  public void enableMenu(String menu) {
    //sendMessage(MASTER, new Message(id, MASTER, MessageType.MENU_ACTIVE,
    // null, menu.getBytes(StandardCharsets.UTF_8)));
  }

  @Override
  public void disableMenu(String menu) {
    //sendMessage(MASTER, new Message(id, MASTER, MessageType.MENU_INACTIVE,
    // null, menu.getBytes(StandardCharsets.UTF_8)));
  }

  @Override
  public void deregisterMenu(String menu) {
    //sendMessage(MASTER, new Message(id, MASTER, MessageType.DEREGISTER_MENU,
    // null, menu.getBytes(StandardCharsets.UTF_8)));
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

  /**
   * <p>Convenience function to convert a serializable object to a byte array.</p>
   *
   * @param object the object to be serialized
   * @return the byte array representation of the object
   */
  // TODO reimplement serialization
  /*
  public static byte[] toByteArray(Serializable object) {
    try (ByteArrayOutputStream bos = new ByteArrayOutputStream();
         ObjectOutputStream out = new ObjectOutputStream(bos);) {
      out.writeObject(object);
      out.flush();
      out.close();
      return bos.toByteArray();
    } catch (IOException ioe) {
      log.log(Level.SEVERE, "Error serializing object", ioe);
    }
    return null;
  }
  */

  /**
   * <p>Convenience function to deserialize a byte array back to an object.</p>
   *
   * @param arr the byte array representing the serialized object
   * @return the deserialized object
   */
  public static Object toObject(byte[] arr) {
    // TODO reimplement serialization
    /*
    try (ByteArrayInputStream bis = new ByteArrayInputStream(arr);
         ObjectInputStream in = new ObjectInputStream(bis);) {
      return in.readObject();
    } catch (IOException | ClassNotFoundException e) {
      log.log(Level.SEVERE, "Error serializing object", e);
    }
    */
    return null;
  }
}
