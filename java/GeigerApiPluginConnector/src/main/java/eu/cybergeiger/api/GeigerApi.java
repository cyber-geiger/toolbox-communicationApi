package eu.cybergeiger.api;

import eu.cybergeiger.storage.StorageController;
import eu.cybergeiger.storage.StorageException;
import eu.cybergeiger.api.message.GeigerUrl;
import eu.cybergeiger.api.message.Message;
import eu.cybergeiger.api.message.MessageType;
import eu.cybergeiger.api.plugin.*;

import java.io.IOException;
import java.util.List;
import java.util.logging.Logger;

/**
 * <p>The API provided by all communicator interfaces.</p>
 */
public interface GeigerApi extends PluginRegistrar, MenuRegistrar {
  String MASTER_ID = "__MASTERPLUGIN__";
  String MASTER_EXECUTOR = "";

  Logger logger = Logger.getLogger("GeigerApi");

  String getId();

  Declaration getDeclaration();

  /**
   * <p>Obtain controller to access the storage.</p>
   *
   * @return a generic controller providing access to the local storage
   * @throws StorageException in case allocation of storage backed fails
   */
  StorageController getStorage() throws StorageException;

  /**
   * <p>Register an event listener for specific events on the Master.</p>
   *
   * @param events   list of events for which messages should be received. Use MessageType.
   *                 ALL_EVENTS to register for all messages.
   * @param listener the listener to be registered
   */
  void registerListener(MessageType[] events, PluginListener listener);

  /**
   * <p>Remove a listener waiting for Events.</p>
   *
   * @param events   the events affected or null if the listener should be removed from all events
   * @param listener the listener to be removed
   */
  void deregisterListener(MessageType[] events, PluginListener listener);

  /**
   * <p>Sends a custom, plugin-specific message to a peer plugin.</p>
   *
   * <p>Mainly used for internal purposes. Plugins may only send messages to the toolbox core.</p>
   *
   * @param msg the message to be sent
   */
  void sendMessage(Message msg) throws IOException;

  /**
   * <p>Reset the GeigerApi by removing all registered plugins and MenuItems.</p>
   */
  void zapState();

  /**
   * Release all resources.
   */
  void close();
}
