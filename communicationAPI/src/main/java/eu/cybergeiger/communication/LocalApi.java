package eu.cybergeiger.communication;

//import ch.fhnw.geiger.localstorage.StorageController;
//import ch.fhnw.geiger.localstorage.db.GenericController;
import eu.cybergeiger.communication.communicator.GeigerCommunicator;
import eu.cybergeiger.communication.communicator.GeigerServer;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.Serializable;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.naming.NameNotFoundException;


public class LocalApi implements PluginRegistrar, MenuRegistrar {

  public static final String MASTER = "__MASTERPLUGIN__";

  private static Map<String, PluginInformation> secrets = new HashMap<>(1);
  private static Map<String, MenuItem> menuItems = new HashMap<>(0);

  private static Logger log = Logger.getLogger("LocalAPI");

  private String executor;
  private String id;
  private boolean isMaster;
  private Declaration declaration;

  private final Map<MessageType, List<PluginListener>> listeners = new ConcurrentHashMap<>();

  public LocalApi(String executor, String id, boolean isMaster, Declaration declaration) {
    this.executor = executor;
    this.id = id;
    this.isMaster = isMaster;
    this.declaration = declaration;

//    restoreState();

//    if (!isMaster) {
//      registerPlugin();
//      activatePlugin();
//    }

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
  public void registerPlugin(Message msg) {
    // TODO share secret in a secure paired way....
    PluginInformation pi = new PluginInformation(msg.getAction().toString(), Integer.parseInt(msg.getPayloadString()), new CommunicationSecret());
    //CommunicationSecret secret = new CommunicationSecret();
    secrets.put(msg.getSourceId(), pi);
  }

  @Override
  public void deregisterPlugin() throws NameNotFoundException {
    if (secrets.get(id) == null) {
      throw new NameNotFoundException("no communication secret found for id \"" + id + "\"");
    }
    deactivatePlugin();
    zapState();
  }

  /**
   * <p>Deletes all current registered items.</p>
   */
  public void zapState() {
    synchronized (menuItems) {
      menuItems.clear();
    }
    synchronized (secrets) {
      secrets.clear();
    }
    storeState();
  }

  public void registerPlugin(String id, PluginInformation info) {
    // add plugin information to local secrets storage
    // TODO check first if a secret is overridden?
    synchronized (secrets) {
      secrets.put(id, info);
    }
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
    secrets.remove(id);

    storeState();
  }

  private void storeState() {
    // store plugin state
    try (ObjectOutputStream out = new ObjectOutputStream(Files.newOutputStream(Paths.get("LocalAPI." + id + ".state")))) {
      synchronized (secrets) {
        out.writeInt(secrets.size());
        for (Map.Entry<String, PluginInformation> e : secrets.entrySet()) {
          out.writeObject(e.getKey());
          out.writeObject(e.getValue());
        }
      }
      synchronized (menuItems) {
        out.writeInt(menuItems.size());
        for (Map.Entry<String, MenuItem> e : menuItems.entrySet()) {
          out.writeObject(e.getKey());
          out.writeObject(e.getValue());
        }
      }
    } catch (IOException ioe) {
      log.log(Level.SEVERE, "persisting LocalAPI state", ioe);
    }
  }

  private void restoreState() {
    try (ObjectInputStream in = new ObjectInputStream(Files.newInputStream(Paths.get("LocalAPI." + id + ".state")))) {
      // restoring plugin information
      int mapSize = in.readInt();
      Map<String, PluginInformation> l = new HashMap<>(mapSize);
      for (int i = 0; i < mapSize; i++) {
        l.put((String) (in.readObject()), (PluginInformation) (in.readObject()));
      }
      synchronized (secrets) {
        secrets.clear();
        secrets.putAll(l);
      }

      // restoring menu information
      mapSize = in.readInt();
      Map<String, MenuItem> l2 = new HashMap<>(mapSize);
      for (int i = 0; i < mapSize; i++) {
        l2.put((String) (in.readObject()), (MenuItem) (in.readObject()));
      }
      synchronized (menuItems) {
        menuItems.clear();
        menuItems.putAll(l2);
      }
    } catch (IOException | ClassNotFoundException e) {
      log.log(Level.SEVERE, "persisting LocalAPI state", e);
    }
  }

  /**
   * <p>Activates the plugin and sets up communication.</p>
   */
  public void activatePlugin() {
    sendMessage(MASTER, new Message(id, MASTER, MessageType.ACTIVATE_PLUGIN, null));
  }

  /**
   * <p>deactivates the plugin and makes sure that a plugin is started immediately if contacted</p>
   *
   * <p>If a plugin is properly deactivated no timeout is reached before contacting a plugin.</p>
   */
  public void deactivatePlugin() {
    sendMessage(MASTER, new Message(id, MASTER, MessageType.DEACTIVATE_PLUGIN, null));
  }

  /**
   * <p>Obtain controller to access the storage.</p>
   *
   * @return a generic conroller providing access to the local storage.
   */
//  public StorageController getStorage() {
//    // TODO implementation passthru missing
//    return new GenericController(id, new H2SqlMapper("jdbc:h2:./testdb;AUTO_SERVER=TRUE", "sa2", "1234"));
//  }

  /**
   * <p>Register an event listener for specific events.</p>
   * @param events list of events for which lessages should be received. Use MessageType.ALL_EVENTS to
   *               register for all messages.
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
   * @param events the events affected or null if the listener should be removed from all events
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
   * @param msg the message to be sent
   */
  public void sendMessage(String pluginId, Message msg) {
    // TODO: reimplement for communication version
    //LocalApi api = LocalApiFactory.getLocalApi(pluginId);
    //api.receivedMessage(new Message(id, pluginId, msg.getType(), msg.getAction(), msg.getPayload()));
    if(MASTER.equals(msg.getTargetId())) {
      try {
            // connect to core
            InetSocketAddress address = new InetSocketAddress(InetAddress.getLocalHost(), GeigerServer.getDefaultPort());
            Socket s = new Socket();
            s.bind(address);
            s.connect(address, 10000);
            ObjectOutputStream out = new ObjectOutputStream(s.getOutputStream()); // TODO close
            out.writeObject(msg);
            out.close();
            s.close();
        } catch (IOException ioe) {
            // TODO
            ioe.printStackTrace();
        }
    } else {
      // its not the master
      try {
        // connect to core
        InetSocketAddress address = new InetSocketAddress(InetAddress.getLocalHost(), secrets.get(msg.getTargetId()).getPort());
        Socket s = new Socket();
        s.bind(address);
        s.connect(address, 10000);
        ObjectOutputStream out = new ObjectOutputStream(s.getOutputStream()); // TODO close
        out.writeObject(msg);
        out.close();
        s.close();
      } catch (IOException ioe) {
        // TODO
        ioe.printStackTrace();
      }
    }
  }

  /**
   * <p>broadcasts a message to all known plugins.</p>
   *
   * @param msg the message to be broadcasted
   */
  private void broadcastMessage(Message msg) {
    for (Map.Entry<String, PluginInformation> plugin : secrets.entrySet()) {
      sendMessage(plugin.getKey(), new Message(MASTER, plugin.getKey(), msg.getType(), msg.getAction(), msg.getPayload()));
    }
  }

  private void receivedMessage(Message msg) {
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
        PluginInformation info = (PluginInformation) (toObject(msg.getPayload()));
        registerPlugin(msg.getSourceId(), info);
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
  public void registerMenu(String menu, GeigerURL action) {
    sendMessage(MASTER, new Message(id, MASTER, MessageType.REGISTER_MENU, null, toByteArray(new MenuItem(menu, action))));
  }

  @Override
  public void enableMenu(String menu) {
    sendMessage(MASTER, new Message(id, MASTER, MessageType.MENU_ACTIVE, null, menu.getBytes(StandardCharsets.UTF_8)));
  }

  @Override
  public void disableMenu(String menu) {
    sendMessage(MASTER, new Message(id, MASTER, MessageType.MENU_INACTIVE, null, menu.getBytes(StandardCharsets.UTF_8)));
  }

  @Override
  public void deregisterMenu(String menu) {
    sendMessage(MASTER, new Message(id, MASTER, MessageType.DEREGISTER_MENU, null, menu.getBytes(StandardCharsets.UTF_8)));
  }

  /**
   * <p>notify plugin about a menu entry pressed.</p>
   *
   * @param url the GeigerURL associated with the menu entry
   */
  public void menuPressed(GeigerURL url) {
    sendMessage(url.getPlugin(), new Message(MASTER, url.getPlugin(), MessageType.MENU_PRESSED, url, null));
  }

  /**
   * <p>Returns the List of currently registered menu.</p>
   *
   * <p>This call is for the toolbox core only.</p>
   *
   * @return the list of currently registered menus
   */
  public List<MenuItem> getMenuLIst() {
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
  public static byte[] toByteArray(Serializable object) {
    try (ByteArrayOutputStream bos = new ByteArrayOutputStream(); ObjectOutputStream out = new ObjectOutputStream(bos);) {
      out.writeObject(object);
      out.flush();
      out.close();
      return bos.toByteArray();
    } catch (IOException ioe) {
      log.log(Level.SEVERE, "Error serializing object", ioe);
    }
    return null;
  }

  /**
   * <p>Convenience function to deserialize a byte array back to an object.</p>
   *
   * @param arr the byte array representing the serialized object
   * @return the deserialized object
   */
  public static Object toObject(byte[] arr) {
    try (ByteArrayInputStream bis = new ByteArrayInputStream(arr); ObjectInputStream in = new ObjectInputStream(bis);) {
      return in.readObject();
    } catch (IOException | ClassNotFoundException e) {
      log.log(Level.SEVERE, "Error serializing object", e);
    }
    return null;
  }
}
