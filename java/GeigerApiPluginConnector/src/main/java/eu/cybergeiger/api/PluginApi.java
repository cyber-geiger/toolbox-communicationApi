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
import java.net.ConnectException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Paths;
import java.util.*;
import java.util.concurrent.TimeoutException;
import java.util.logging.Level;

import static eu.cybergeiger.api.communication.CommunicationHelper.sendAndWait;


/**
 * <p>Offers an API for all plugins to access the local toolbox.</p>
 */
public class PluginApi implements GeigerApi {
  private static final int MAX_SEND_TRIES = 10;
  private static final int MASTER_START_WAIT_TIME_MILLIS = 1000;
  private static final String INITIAL_STATE_SAVE_DIRECTORY = "./";

  private final StorableHashMap<StorableString, PluginInformation> plugins = new StorableHashMap<>();

  private final String executor;
  private final String id;
  private final Declaration declaration;
  private final PassthroughController storage;
  private String stateSaveDirectory = INITIAL_STATE_SAVE_DIRECTORY;

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
  public PluginApi(String executor, String id, Declaration declaration) throws IOException {
    this.executor = executor;
    this.id = id;
    this.declaration = declaration;

    restoreState();
    communicator = new GeigerCommunicator(this);
    communicator.start();
    registerPlugin();
    activatePlugin();

    storage = new PassthroughController(this);
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
  public StorageController getStorage() {
    return storage;
  }

  @Override
  public void registerPlugin() throws CommunicationException {
    PluginInformation pluginInformation = new PluginInformation(id, this.executor, communicator.getPort());
    try {
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
    } catch (TimeoutException | InterruptedException | IOException e) {
      throw new CommunicationException("Failed to register plugin.", e);
    }
  }

  @Override
  public void activatePlugin() throws CommunicationException {
    try {
      sendAndWait(
        this,
        new Message(
          id,
          MASTER_ID,
          MessageType.ACTIVATE_PLUGIN,
          new GeigerUrl(MASTER_ID, "activatePlugin"),
          SerializerHelper.intToByteArray(communicator.getPort())
        )
      );
    } catch (TimeoutException | InterruptedException | IOException e) {
      throw new CommunicationException("Failed to activate plugin.", e);
    }
  }

  @Override
  public void deactivatePlugin() throws CommunicationException {
    try {
      sendAndWait(this,
        new Message(
          id,
          MASTER_ID,
          MessageType.DEACTIVATE_PLUGIN,
          null
        )
      );
    } catch (TimeoutException | InterruptedException | IOException e) {
      throw new CommunicationException("Failed to deactivate plugin.", e);
    }
  }

  @Override
  public void deregisterPlugin() throws CommunicationException {
    try {
      sendAndWait(this,
        new Message(
          id,
          MASTER_ID,
          MessageType.DEREGISTER_PLUGIN,
          new GeigerUrl(MASTER_ID, "deregisterPlugin")
        )
      );
    } catch (TimeoutException | InterruptedException | IOException e) {
      throw new CommunicationException("Failed to deregister plugin.", e);
    }
  }

  private String getAlternativeStateStoreDirectory() {
    String baseDirectory;
    String platform = System.getProperty("os.name").toLowerCase();
    if (platform.contains("mac")) {
      baseDirectory = "~/Library/Application Support";
    } else if (platform.contains("win")) {
      baseDirectory = System.getenv("AppData");
    } else if (platform.contains("nix") ||
      platform.contains("nux") ||
      platform.contains("aix")) {
      baseDirectory = System.getenv("XDG_DATA_HOME");
    } else {
      throw new RuntimeException("Unknown platform \"" + platform + "\".");
    }
    if (baseDirectory == null)
      baseDirectory = System.getProperty("user.home");
    if (baseDirectory == null)
      throw new RuntimeException("Could not find alternative state store directory.");
    return Paths.get(baseDirectory, "geiger").toString();
  }

  private String getStateSaveLocation() {
    return Paths.get(stateSaveDirectory, "GeigerApi." + id + ".state").toString();
  }

  private interface IOOperation {
    void execute(String path) throws IOException;
  }

  private void tryStateIO(IOOperation operation, String errorMessage) {
    if (stateSaveDirectory.equals(INITIAL_STATE_SAVE_DIRECTORY))
      try {
        operation.execute(getStateSaveLocation());
        return;
      } catch (IOException e) {
        logger.log(Level.WARNING, "State IO operation failed. Switching to alternative save location.");
      }
    stateSaveDirectory = getAlternativeStateStoreDirectory();
    try {
      operation.execute(getStateSaveLocation());
    } catch (IOException e) {
      logger.log(Level.SEVERE, errorMessage, e);
    }
  }

  private void storeState() {
    tryStateIO((path) -> {
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      synchronized (plugins) {
        plugins.toByteArrayStream(out);
      }
      try (FileOutputStream file = new FileOutputStream(getStateSaveLocation())) {
        file.write(out.toByteArray());
      }
    }, "Unable to store state.");
  }

  private void restoreState() {
    tryStateIO((path) -> {
      byte[] buffer;
      try {
        buffer = Files.readAllBytes(Paths.get(getStateSaveLocation()));
      } catch (NoSuchFileException ignored) {
        // No save file is equal to an empty save file.
        plugins.clear();
        return;
      }
      ByteArrayInputStream in = new ByteArrayInputStream(buffer);
      try {
        synchronized (plugins) {
          StorableHashMap.fromByteArrayStream(in, plugins);
        }
      } catch (IOException e) {
        logger.log(Level.WARNING, "Unable to deserialize state. Storing current state.", e);
        storeState();
      }
    }, "Unable to restore state.");
  }

  /**
   * To register a Pluginlistener inside this LocalApi.
   *
   * @param types    The events to register for
   * @param listener The listener to register
   */
  @Override
  public void registerListener(MessageType[] types, PluginListener listener) {
    for (MessageType type : types) {
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
        if (l == null) continue;
        l.remove(listener);
      }
    }
  }

  @Override
  public void sendMessage(Message message) throws IOException {
    if (id.equals(message.getTargetId())) {
      receivedMessage(message);
      return;
    }
    if (!message.getTargetId().equals(GeigerApi.MASTER_ID))
      throw new CommunicationException("PluginApi cannot send messages to non-master plugins.");

    StorableString storableTargetId = new StorableString(message.getTargetId());
    PluginInformation pluginInformation = plugins.computeIfAbsent(
      storableTargetId,
      k -> new PluginInformation(
        message.getTargetId(),
        GeigerApi.MASTER_EXECUTOR,
        GeigerCommunicator.MASTER_PORT
      )
    );
    boolean inBackground = message.getType() != MessageType.RETURNING_CONTROL;
    if (!inBackground)
      PluginStarter.startPlugin(pluginInformation, false);

    int tries = 1;
    while (true) {
      try {
        communicator.sendMessage(pluginInformation.getPort(), message);
        break;
      } catch (IOException e) {
        if (tries == MAX_SEND_TRIES ||
          !(e instanceof ConnectException &&
            e.getMessage().startsWith("Connection refused")))
          throw e;
        tries++;

        PluginStarter.startPlugin(pluginInformation, inBackground);
        try {
          Thread.sleep(MASTER_START_WAIT_TIME_MILLIS);
        } catch (InterruptedException ignored) {
          throw new CommunicationException("Wait for master to start was interrupted.");
        }
      }
    }
  }

  public void receivedMessage(Message message) throws CommunicationException {
    // all other messages are not handled internally
    if (message.getType() == MessageType.PING) {
      try {
        sendMessage(new Message(
          message.getTargetId(),
          message.getSourceId(),
          MessageType.PONG,
          new GeigerUrl(message.getSourceId(), ""),
          message.getPayload(),
          message.getRequestId()
        ));
      } catch (IOException e) {
        throw new CommunicationException("Failed to send pong message.", e);
      }
    }

    notifyListener(message.getType(), message);
    if (message.getType().getId() < MessageType.ALL_EVENTS.getId())
      notifyListener(MessageType.ALL_EVENTS, message);
  }

  private void notifyListener(MessageType type, Message message) {
    synchronized (listeners) {
      List<PluginListener> listeners = this.listeners.get(type);
      if (listeners == null) return;
      for (PluginListener listener : listeners) {
        logger.info(
          "## notifying PluginListener " + listener +
            "for msg " + message.getType() + " " + message.getAction()
        );
        listener.pluginEvent(message);
        logger.info("## PluginEvent fired");
      }
    }
  }

  @Override
  public void registerMenu(MenuItem menu) throws CommunicationException {
    try {
      sendAndWait(this, new Message(
        id, MASTER_ID,
        MessageType.REGISTER_MENU,
        new GeigerUrl(MASTER_ID, "registerMenu"),
        menu.toByteArray()
      ));
    } catch (IOException | InterruptedException | TimeoutException e) {
      throw new CommunicationException("Failed to register menu.", e);
    }
  }

  @Override
  public void enableMenu(String menu) throws CommunicationException {
    try {
      sendAndWait(this, new Message(
        id, MASTER_ID,
        MessageType.ENABLE_MENU,
        new GeigerUrl(MASTER_ID, "enableMenu"),
        menu.getBytes(StandardCharsets.UTF_8)
      ));
    } catch (IOException | InterruptedException | TimeoutException e) {
      throw new CommunicationException("Failed to enable menu.", e);
    }
  }

  @Override
  public void disableMenu(String menu) throws CommunicationException {
    try {
      Message message = new Message(
        id, MASTER_ID,
        MessageType.DISABLE_MENU,
        new GeigerUrl(MASTER_ID, "disableMenu")
      );
      message.setPayloadString(menu);
      sendAndWait(this, message);
    } catch (IOException | InterruptedException | TimeoutException e) {
      throw new CommunicationException("Failed to disable menu.", e);
    }
  }

  @Override
  public void deregisterMenu(String menu) throws CommunicationException {
    try {
      sendAndWait(this, new Message(
        id, MASTER_ID,
        MessageType.DEREGISTER_MENU,
        new GeigerUrl(MASTER_ID, "deregisterMenu"),
        menu.getBytes(StandardCharsets.UTF_8)
      ));
    } catch (IOException | InterruptedException | TimeoutException e) {
      throw new CommunicationException("Failed to deregister menu.", e);
    }
  }

  /**
   * <p>Deletes all current registered items.</p>
   */
  public void zapState() {
    synchronized (plugins) {
      plugins.clear();
    }
    storeState();
  }

  @Override
  public void close() throws IOException {
    communicator.close();
  }
}
