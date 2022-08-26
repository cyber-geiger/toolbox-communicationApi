package eu.cybergeiger.api;

import eu.cybergeiger.api.communication.GeigerCommunicator;
import eu.cybergeiger.api.exceptions.CommunicationException;
import eu.cybergeiger.api.message.GeigerUrl;
import eu.cybergeiger.api.message.Message;
import eu.cybergeiger.api.message.MessageType;
import eu.cybergeiger.api.plugin.*;
import eu.cybergeiger.api.storage.PassthroughController;
import eu.cybergeiger.api.utils.Platform;
import eu.cybergeiger.serialization.SerializerHelper;
import eu.cybergeiger.storage.StorageController;
import eu.cybergeiger.storage.StorageException;
import sun.security.util.BitArray;
import sun.security.util.DerOutputStream;
import sun.security.util.DerValue;

import javax.crypto.KeyAgreement;
import java.io.*;
import java.net.ConnectException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Paths;
import java.security.*;
import java.security.spec.InvalidKeySpecException;
import java.security.spec.X509EncodedKeySpec;
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
  private static final String KEY_EXCHANGE_ALGORITHM = "X25519";
  private static final MessageType[] NO_AUTH_MESSAGE_TYPES = new MessageType[]{
    MessageType.AUTH_ERROR
  };
  private static final MessageType[] TEMP_NO_AUTH_MESSAGE_TYPES = new MessageType[]{
    MessageType.COMAPI_SUCCESS,
    MessageType.COMAPI_ERROR
  };


  private final String executor;
  private final String id;
  private final Declaration declaration;
  private final PassthroughController storage;
  private String stateSaveDirectory = INITIAL_STATE_SAVE_DIRECTORY;
  private final boolean ignoreMessageSignature;
  private PluginInformation masterInfo;

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
    this(executor, id, declaration, GeigerApi.MASTER_EXECUTOR, false, false);
  }

  /**
   * <p>Constructor called by LocalApiFactory.</p>
   *
   * @param executor       the executor string of the plugin
   * @param id             the id of the plugin
   * @param declaration    declaration of data sharing
   * @param masterExecutor Alternative master executor string.
   * @throws StorageException if the StorageController could not be initialized
   */
  public PluginApi(String executor, String id, Declaration declaration,
                   String masterExecutor, boolean ignoreMessageSignature,
                   boolean skipInitialStateRestore) throws IOException {
    this.executor = executor;
    this.id = id;
    this.declaration = declaration;
    this.ignoreMessageSignature = ignoreMessageSignature;
    masterInfo = new PluginInformation(
      GeigerApi.MASTER_ID,
      masterExecutor,
      GeigerCommunicator.MASTER_PORT,
      Declaration.DO_NOT_SHARE_DATA
    );

    if (!skipInitialStateRestore)
      restoreState();
    communicator = new GeigerCommunicator(this);
    communicator.start();
    if (masterInfo.getSecret().getBytes().length == 0)
      registerPlugin(); // Only register if not already.
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

  private static class RegisterResultWaiter implements PluginListener, AutoCloseable {
    static final MessageType[] TYPES = new MessageType[]{
      MessageType.AUTH_SUCCESS,
      MessageType.AUTH_ERROR
    };

    private final Object receivedResponse = new Object();
    private Message result;
    private final GeigerApi api;

    RegisterResultWaiter(GeigerApi api) {
      this.api = api;
      api.registerListener(TYPES, this);
    }

    @Override
    public void pluginEvent(Message msg) {
      synchronized (receivedResponse) {
        if (result != null ||
          msg.getAction() == null ||
          !msg.getAction().getPath().equals("registerPlugin")) return;
        result = msg;
        receivedResponse.notifyAll();
      }
    }

    boolean waitForResult() throws InterruptedException, TimeoutException {
      synchronized (receivedResponse) {
        receivedResponse.wait(30000);
      }
      if (result == null)
        throw new TimeoutException("Did not receive register result in time.");
      return result.getType() == MessageType.AUTH_SUCCESS;
    }

    @Override
    public void close() {
      api.deregisterListener(TYPES, this);
    }
  }

  @Override
  public void registerPlugin() throws CommunicationException {
    try {
      KeyPair pair = KeyPairGenerator
        .getInstance(KEY_EXCHANGE_ALGORITHM)
        .generateKeyPair();

      // Extract raw public key
      DerValue ownPubKeyEncoded = new DerValue(pair.getPublic().getEncoded());
      DerValue algoId = ownPubKeyEncoded.data.getDerValue();
      byte[] ownPubKeyRaw = ownPubKeyEncoded.data.getUnalignedBitString().toByteArray();

      // Register result waiter before sending registration request in case
      // result is sent immediately.
      try (RegisterResultWaiter resultWaiter = new RegisterResultWaiter(this)) {
        PluginInformation ownPluginInfo = new PluginInformation(
          id,
          executor,
          communicator.getPort(),
          declaration,
          new CommunicationSecret(ownPubKeyRaw)
        );
        Message result = sendAndWait(
          this,
          new Message(
            id,
            MASTER_ID,
            MessageType.REGISTER_PLUGIN,
            new GeigerUrl(MASTER_ID, "registerPlugin"),
            ownPluginInfo.toByteArray()
          )
        );
        if (result.getType().equals(MessageType.COMAPI_ERROR))
          throw new CommunicationException("Key exchange failed.");

        // Construct foreign public key
        DerOutputStream foreignPubKeyEncoded = new DerOutputStream();
        foreignPubKeyEncoded.write(DerValue.tag_Sequence);
        // Our own public key is structurally the same, so we can use its length.
        foreignPubKeyEncoded.putLength(ownPubKeyEncoded.length());
        algoId.encode(foreignPubKeyEncoded);
        foreignPubKeyEncoded.putUnalignedBitString(new BitArray(
          result.getPayload().length * 8,
          result.getPayload()
        ));
        PublicKey foreignPubKey = KeyFactory.getInstance(KEY_EXCHANGE_ALGORITHM)
          .generatePublic(new X509EncodedKeySpec(foreignPubKeyEncoded.toByteArray()));

        // Compute shared secret and save in master's plugin information.
        KeyAgreement agreement = KeyAgreement.getInstance(KEY_EXCHANGE_ALGORITHM);
        agreement.init(pair.getPrivate());
        agreement.doPhase(foreignPubKey, true);
        masterInfo = masterInfo.withSecret(
          new CommunicationSecret(agreement.generateSecret())
        );
        if (!resultWaiter.waitForResult()) {
          masterInfo = masterInfo.withSecret(null);
          throw new CommunicationException("Plugin registration was denied.");
        }
        storeState();
      }
    } catch (TimeoutException | InterruptedException | IOException | NoSuchAlgorithmException |
             InvalidKeySpecException | InvalidKeyException e) {
      masterInfo = masterInfo.withSecret(null);
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
    String baseDirectory = null;
    switch (Platform.getPlatform()) {
      case WINDOWS:
        baseDirectory = System.getenv("AppData");
        break;
      case LINUX:
        baseDirectory = System.getenv("XDG_DATA_HOME");
        break;
      case MAC:
        baseDirectory = "~/Library/Application Support";
        break;
    }
    if (baseDirectory == null)
      baseDirectory = System.getProperty("user.home");
    if (baseDirectory == null)
      throw new RuntimeException("Could not find alternative state store directory.");
    return Paths.get(baseDirectory, "geiger").toString();
  }

  private File getStateSaveLocation() throws IOException {
    File file = new File(Paths.get(stateSaveDirectory, "GeigerApi." + id + ".state").toUri());
    file.getParentFile().mkdirs();
    file.createNewFile();
    return file;
  }

  private interface IOOperation {
    void execute(File file, boolean lastTry) throws IOException;
  }

  private void tryStateIO(IOOperation operation, String errorMessage) {
    if (stateSaveDirectory.equals(INITIAL_STATE_SAVE_DIRECTORY))
      try {
        operation.execute(getStateSaveLocation(), false);
        return;
      } catch (IOException e) {
        logger.log(Level.WARNING, "State IO operation failed. Switching to alternative save location.", e);
      }
    stateSaveDirectory = getAlternativeStateStoreDirectory();
    try {
      operation.execute(getStateSaveLocation(), true);
    } catch (IOException e) {
      logger.log(Level.SEVERE, errorMessage, e);
    }
  }

  private void storeState() {
    tryStateIO((path, ignored) -> {
      try (FileOutputStream out = new FileOutputStream(getStateSaveLocation())) {
        masterInfo.toByteArrayStream(out);
      }
    }, "Unable to store state.");
  }

  private void restoreState() {
    try {
      tryStateIO((path, lastTry) -> {
        try (FileInputStream in = new FileInputStream(getStateSaveLocation())) {
          masterInfo = PluginInformation.fromByteArrayStream(in);
        } catch (FileNotFoundException e) {
          if (!lastTry) throw e;
          // No saved state should be treated like a reset state.
          zapState();
        }
      }, "Unable to restore state.");
    } catch (ClassCastException ignored) {
      // Found invalid state save. Reset and overwrite to recover.
      zapState();
    }
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
  public void sendMessage(Message message) throws CommunicationException {
    if (!message.getTargetId().equals(GeigerApi.MASTER_ID))
      throw new CommunicationException("PluginApi cannot send messages to non-master plugins.");

    boolean inBackground = message.getType() != MessageType.RETURNING_CONTROL;
    if (!inBackground)
      PluginStarter.startPlugin(masterInfo, false);

    int tries = 1;
    while (true) {
      try {
        communicator.sendMessage(masterInfo, message);
        break;
      } catch (IOException e) {
        if (tries == MAX_SEND_TRIES || !(e instanceof ConnectException))
          throw new CommunicationException("Failed to send message.", e);
        tries++;

        PluginStarter.startPlugin(masterInfo, inBackground);
        try {
          Thread.sleep(MASTER_START_WAIT_TIME_MILLIS);
        } catch (InterruptedException ignored) {
          throw new CommunicationException("Wait for master to start was interrupted.");
        }
      }
    }
  }

  public void receivedMessage(Message message) throws CommunicationException {
    if (!message.getSourceId().equals(GeigerApi.MASTER_ID)) return;
    if (!ignoreMessageSignature &&
      !Arrays.asList(NO_AUTH_MESSAGE_TYPES).contains(message.getType()) &&
      !(masterInfo.getSecret().getBytes().length == 0 &&
        Arrays.asList(TEMP_NO_AUTH_MESSAGE_TYPES).contains(message.getType())) &&
      !message.isHashValid(masterInfo.getSecret())) {
      sendMessage(new Message(
        id, message.getSourceId(),
        MessageType.AUTH_ERROR,
        null, null,
        message.getRequestId()
      ));
      return;
    }

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
    masterInfo = masterInfo.withSecret(null);
    storeState();
  }

  @Override
  public void close() throws IOException {
    communicator.close();
  }
}
