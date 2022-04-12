package eu.cybergeiger.api;

import eu.cybergeiger.api.communication.GeigerCommunicator;
import eu.cybergeiger.api.exceptions.CommunicationException;
import eu.cybergeiger.api.message.GeigerUrl;
import eu.cybergeiger.api.message.Message;
import eu.cybergeiger.api.message.MessageType;
import eu.cybergeiger.api.plugin.*;
import eu.cybergeiger.api.storage.PassthroughController;
import eu.cybergeiger.api.utils.StorableHashMap;
import eu.cybergeiger.api.utils.StorableString;
import eu.cybergeiger.serialization.SerializerHelper;
import eu.cybergeiger.storage.StorageController;
import eu.cybergeiger.storage.StorageException;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.*;
import java.util.logging.Level;

import static eu.cybergeiger.api.communication.CommunicationHelper.sendAndWait;


/**
 * <p>Offers an API for all plugins to access the local toolbox.</p>
 */
public class PluginApi implements GeigerApi {
  static final int MAX_SEND_RETRIES = 100;
  static final int MASTER_START_WAIT_TIME_MILLIS = 1000;

  private final StorableHashMap<StorableString, PluginInformation> plugins = new StorableHashMap<>();
  private final StorableHashMap<StorableString, MenuItem> menuItems = new StorableHashMap<>();

  private final String executor;
  private final String id;
  private final Declaration declaration;
  private final PassthroughController storage;

  private final Map<MessageType, List<PluginListener>> listeners = Collections.synchronizedMap(new HashMap<>());

  private final GeigerCommunicator communicator;

  /**
   * <p>Constructor called by LocalApiFactory.</p>
   *
   * @param executor    the executor string of the plugin
   * @param id          the id of the plugin
   * @param declaration declaration of data sharing
   * @throws StorageException if the StorageController could not be initialized
   */
  protected PluginApi(String executor, String id, Declaration declaration) throws IOException {
    this.executor = executor;
    this.id = id;
    this.declaration = declaration;

    restoreState();
    communicator = new GeigerCommunicator(this);
    communicator.start();
    registerPlugin();
    activatePlugin();

    storage = new PassthroughController(this, id);
    registerListener(new MessageType[]{MessageType.STORAGE_EVENT}, storage);
  }

  public String getId() {
    return id;
  }

  /**
   * <p>Returns the declaration given upon creation.</p>
   *
   * @return the current declaration
   */
  public Declaration getDeclaration() {
    return declaration;
  }

  /**
   * <p>Obtain controller to access the storage.</p>
   *
   * @return a generic controller providing access to the local storage
   */
  public StorageController getStorage() throws StorageException {
    return storage;
  }

  @Override
  public void registerPlugin() throws CommunicationException {
    // TODO share secret in a secure paired way....
    PluginInformation pluginInformation = new PluginInformation(id, this.executor, communicator.getPort());
    sendAndWait(
      this,
      new Message(
        id,
        MASTER_ID,
        MessageType.REGISTER_PLUGIN,
        new GeigerUrl(MASTER_ID, "registerPlugin"),
        pluginInformation.toByteArray()
      )
    );
  }

  @Override
  public void activatePlugin() throws CommunicationException {
    sendAndWait(
      this,
      new Message(
        id,
        MASTER_ID,
        MessageType.ACTIVATE_PLUGIN,
        null,
        SerializerHelper.intToByteArray(communicator.getPort())
      )
    );
  }

  @Override
  public void deactivatePlugin() throws CommunicationException {
    sendAndWait(this,
      new Message(
        id,
        MASTER_ID,
        MessageType.DEACTIVATE_PLUGIN,
        null
      )
    );
  }

  @Override
  public void deregisterPlugin() throws CommunicationException {
    sendAndWait(this,
      new Message(
        id,
        MASTER_ID,
        MessageType.DEREGISTER_PLUGIN,
        new GeigerUrl(MASTER_ID, "deregisterPlugin")
      )
    );
  }

  private void storeState() {
    try {
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      synchronized (plugins) {
        plugins.toByteArrayStream(out);
      }
      synchronized (menuItems) {
        menuItems.toByteArrayStream(out);
      }
      try (FileOutputStream f = new FileOutputStream("LocalAPI." + id + ".state");) {
        f.write(out.toByteArray());
      }
    } catch (Throwable e) {
      logger.log(Level.SEVERE, "Unable to store state.", e);
    }
  }

  private void restoreState() {
    try {
      byte[] buffer = Files.readAllBytes(new File("LocalAPI." + id + ".state").toPath());
      ByteArrayInputStream in = new ByteArrayInputStream(buffer);
      synchronized (plugins) {
        StorableHashMap.fromByteArrayStream(in, plugins);
      }
      synchronized (menuItems) {
        StorableHashMap.fromByteArrayStream(in, menuItems);
      }
    } catch (Throwable e) {
      GeigerApi.logger.log(Level.WARNING, "Unable to restore state. Rewriting...", e);
      storeState();
    }
  }

  /**
   * To register a Pluginlistener inside this LocalApi.
   *
   * @param events   The events to register for
   * @param listener The listener to register
   */
  @Override
  public void registerListener(MessageType[] events, PluginListener listener) {
    for (MessageType type : events) {
      synchronized (listeners) {
        listeners
          .computeIfAbsent(type, k -> new Vector<>())
          .add(listener);
      }
    }
  }

  /**
   * <p>Remove a listener waiting for Events.</p>
   *
   * @param events   the events affected or null if the listener should be removed from all events
   * @param listener the listener to be removed
   */
  @Override
  public void deregisterListener(MessageType[] events, PluginListener listener) {
    if (events == null)
      events = MessageType.values();
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
  public void sendMessage(Message message) {
    String pluginId = Objects.requireNonNull(message.getSourceId());
    if (id.equals(pluginId)) {
      receivedMessage(message);
      return;
    }

    StorableString storablePluginId = new StorableString(pluginId);
    PluginInformation pluginInformation = plugins.computeIfAbsent(
      storablePluginId,
      k -> new PluginInformation(
        pluginId,
        GeigerApi.MASTER_EXECUTOR,
        pluginId.equals(GeigerApi.MASTER_ID) ? GeigerCommunicator.MASTER_PORT : 0
      )
    );
    boolean inBackground = message.getType() == MessageType.RETURNING_CONTROL;
    if (pluginInformation.getPort() == 0) {
      PluginStarter.startPlugin(pluginInformation, inBackground);
      // TODO: wait for startup
      pluginInformation = plugins.get(storablePluginId);
    } else if (!inBackground) {
      PluginStarter.startPlugin(pluginInformation, false);
    }

    for (int retryCount = 0; retryCount < MAX_SEND_RETRIES; retryCount++) {
      try {
        communicator.sendMessage(pluginInformation.getPort(), message);
        break;
      } catch (Exception e) {
        PluginStarter.startPlugin(pluginInformation, inBackground);
        if (pluginId.equals(MASTER_ID)) {
          try {
            Thread.sleep(MASTER_START_WAIT_TIME_MILLIS);
          } catch (InterruptedException ignored) {
          }
        } else {
          // TODO: wait for startup
          pluginInformation = plugins.get(storablePluginId);
        }
      }
    }
  }

  public void receivedMessage(Message message) {
    // all other messages are not handled internally
    if (message.getType() == MessageType.PING) {
      sendMessage(new Message(
        message.getTargetId(),
        message.getSourceId(),
        MessageType.PONG,
        new GeigerUrl(message.getSourceId(), ""),
        message.getPayload(),
        message.getRequestId()
      ));
    }

    notifyListener(MessageType.ALL_EVENTS, message);
    notifyListener(message.getType(), message);
  }

  private void notifyListener(MessageType type, Message message) {
    List<PluginListener> listeners = this.listeners.get(type);
    if (listeners == null) return;
    for (PluginListener listener : listeners) {
      GeigerApi.logger.info(
        "## notifying PluginListener " + listener.toString() +
          "for msg " + message.getType().toString() + " " + message.getAction().toString());
      listener.pluginEvent(message);
      GeigerApi.logger.info("## PluginEvent fired");
    }
  }

  @Override
  public void registerMenu(String menu, GeigerUrl action) {
    sendMessage(new Message(
      id, MASTER_ID,
      MessageType.REGISTER_MENU,
      new GeigerUrl(MASTER_ID, "registerMenu"),
      new MenuItem(menu, action).toByteArray()
    ));
  }

  @Override
  public void enableMenu(String menu) {
    sendMessage(new Message(
      id, MASTER_ID,
      MessageType.ENABLE_MENU,
      new GeigerUrl(MASTER_ID, "enableMenu"),
      menu.getBytes(StandardCharsets.UTF_8)
    ));
  }

  @Override
  public void disableMenu(String menu) {
    sendMessage(new Message(
      id, MASTER_ID,
      MessageType.DISABLE_MENU,
      new GeigerUrl(MASTER_ID, "disableMenu"),
      menu.getBytes(StandardCharsets.UTF_8)
    ));
  }

  @Override
  public void deregisterMenu(String menu) {
    sendMessage(new Message(
      id, MASTER_ID,
      MessageType.DEREGISTER_MENU,
      new GeigerUrl(MASTER_ID, "deregisterMenu"),
      menu.getBytes(StandardCharsets.UTF_8)
    ));
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

  @Override
  public void close() {
    try {
      communicator.close();
    } catch (IOException e) {
      e.printStackTrace();
    }
  }
}
