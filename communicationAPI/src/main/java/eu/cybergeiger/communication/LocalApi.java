package eu.cybergeiger.communication;

import jdk.tools.jlink.plugin.Plugin;

import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Logger;
import javax.naming.NameNotFoundException;

public class LocalApi implements PluginRegistrar, MenuRegistrar {

  public static final String MASTER = "__MASTERPLUGIN__";

  private static Map<String, PluginInformation> secrets = new HashMap<>(1);

  private Logger log = Logger.getLogger("LocalAPI");

  private String id;
  private boolean isMaster;
  private Declaration declaration;

  private final Map<MessageType, List<PluginListener>> listeners = new ConcurrentHashMap<>();

  protected LocalApi(String id, boolean isMaster, Declaration declaration) {
    this.id = id;
    this.isMaster = isMaster;
    this.declaration = declaration;
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
    // TODO missing implementation
    //CommunicationSecret secret = new CommunicationSecret();
    //secrets.put(id, secret);
  }

  @Override
  public void deregisterPlugin() throws NameNotFoundException {
    if (secrets.get(id) == null) {
      throw new NameNotFoundException("no communication secret found for id \"" + id + "\"");
    }
    // TODO missing implementation
  }

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

  private void sendMessage(String pluginId, Message msg) {
    // TODO: reimplement for communication version
    try {
      LocalApi api = LocalApiFactory.getLocalApi(pluginId, null);
      api.receivedMessage(new Message(id, pluginId, msg.getType(), msg.getAction(), msg.getPayload()));
    } catch (DeclarationMismatchException dme) {
      // this should never happen
      dme.printStackTrace();
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
    // TODO process internal events
    //// TODO URGENT handle internal MENU list
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
    sendMessage(MASTER, new Message(id, MASTER, MessageType.REGISTER_MENU, action, menu.getBytes(StandardCharsets.UTF_8)));
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
}
