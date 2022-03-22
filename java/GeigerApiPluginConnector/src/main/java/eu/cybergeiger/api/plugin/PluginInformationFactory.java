package eu.cybergeiger.api.plugin;

import java.util.HashMap;
import java.util.Map;

/**
 * <p>A factory class to create plugin information entries.</p>
 */
public class PluginInformationFactory {

  private static final Map<String, PluginInformation> store = new HashMap<>();

  /**
   * <p>Retrieves plugin information for a plugin.</p>
   *
   * @param id the id of the the plugin
   * @param executor the executor string required to run the plugin
   * @param port     the current port of the plugin (-1 denotes unknown)
   * @param secret   the communication secret
   * @return returns the information object or null if not available
   */
  public static PluginInformation getPluginInformation(String id, String executor, int port,
                                                       CommunicationSecret secret) {
    PluginInformation info = store.get(id.toLowerCase());
    if (info == null) {
      info = new PluginInformation(executor, port, secret);
      setPluginInformation(id, info);
    }
    return info;
  }

  /**
   * <p>Retrieves plugin information for a plugin.</p>
   *
   * @param id the id of the the plugin
   * @return returns the information object or null if not available
   */
  public static PluginInformation getPluginInformation(String id) {
    return store.get(id.toLowerCase());
  }

  /**
   * <p>Puts a pluginInformation into the store.</p>
   *
   * @param id   the id of the the plugin
   * @param info the information object containing all relevant information to contact the plugin
   * @return the previously set information or null if new
   */
  public static PluginInformation setPluginInformation(String id, PluginInformation info) {
    PluginInformation old = getPluginInformation(id);
    store.put(id.toLowerCase(), info);
    return old;
  }

  /**
   * <p>Clears all plugin information from the store.</p>
   */
  public static void zap() {
    store.clear();
  }
}
