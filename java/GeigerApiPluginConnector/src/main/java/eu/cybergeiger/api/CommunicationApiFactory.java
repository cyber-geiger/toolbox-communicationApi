package eu.cybergeiger.api;

import ch.fhnw.geiger.localstorage.StorageException;
import eu.cybergeiger.api.exceptions.DeclarationMismatchException;
import eu.cybergeiger.api.plugin.Declaration;

import java.util.HashMap;
import java.util.Map;

/**
 * <p>Implements a singleton pattern for local API.</p>
 */
public class CommunicationApiFactory {

  public static final String MASTER_EXECUTOR = "FIXME";

  // TODO check for threadsafety as concurrenthashmap is not supported
  private static final Map<String, CommunicationApi> instances = new HashMap<>();

  /**
   * <p>Creates one instance only per id, but cannot guarantee it since LocalApi constructor cant be
   * private.</p>
   *
   * @param executor    the executor string required to run the plugin (may be platform dependant)
   * @param id          the id of the API to be retrieved
   * @param declaration the privacy declaration
   * @return the instance requested
   * @throws DeclarationMismatchException if the plugin has been registered previously and the
   *                                      declaration does not match
   * @throws StorageException             if registration failed
   */
  public static CommunicationApi getLocalApi(String executor, String id, Declaration declaration)
      throws DeclarationMismatchException, StorageException {
    synchronized (instances) {
      if (!instances.containsKey(id)) {
        if (CommunicationApi.MASTER.equals(id)) {
          // create master
          instances.put(id, new CommunicationApi(executor, id, true, declaration));
        } else {
          instances.put(id, new CommunicationApi(executor, id, false, declaration));
        }
      }
    }
    CommunicationApi l = instances.get(id);
    if (declaration != null && l.getDeclaration() != declaration) {
      throw new DeclarationMismatchException();
    }
    return l;
  }

  /**
   * <p>Returns only existing and known instances.</p>
   *
   * @param id the id to be retrieved
   * @return the instance or null if not found
   */
  public static CommunicationApi getLocalApi(String id) {
    return instances.get(id);
  }
}
