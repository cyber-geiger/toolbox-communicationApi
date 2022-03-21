package eu.cybergeiger.communication;

import ch.fhnw.geiger.localstorage.StorageController;
import ch.fhnw.geiger.localstorage.StorageException;
import java.util.List;

/**
 * <p>The API provided by all communicator interfaces.</p>
 */
public interface CommunicatorApi extends PluginRegistrar, MenuRegistrar {

  /**
   * <p>Activates the plugin and sets up communication.</p>
   *
   * @param port the port to be occupied
   */
  void activatePlugin(int port);

  /**
   * <p>deactivates the plugin and makes sure that a plugin is started immediately if contacted.</p>
   *
   * <p>If a plugin is properly deactivated no timeout is reached before contacting a plugin.</p>
   */
  void deactivatePlugin();

  /**
   * <p>Obtain controller to access the storage.</p>
   *
   * @return a generic controller providing access to the local storage
   *
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
   * @param pluginId The plugin id to be contacted
   * @param msg      the message to be sent
   */
  void sendMessage(String pluginId, Message msg);

  /**
   * <p>Notify plugin about a menu entry pressed.</p>
   *
   * <p>Wrapper function used by UI to notify plugins about pressed buttons/menu entries.</p>
   *
   * @param url the GeigerURL associated with the menu entry
   */
  void menuPressed(GeigerUrl url);

  /**
   * <p>Returns the List of currently registered menu.</p>
   *
   * <p>This call is for the toolbox core only.</p>
   *
   * @return the list of currently registered menus
   */
  List<MenuItem> getMenuList();

  /**
   * <p>Notify all plugins about the event that a scan button has been pressed.</p>
   *
   * <p>This call is for the toolbox core only.</p>
   */
  void scanButtonPressed();

}
