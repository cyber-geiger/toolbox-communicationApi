package eu.cybergeiger.communication;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class LocalApiFactory {

  private static Map<String, LocalApi> instances = new ConcurrentHashMap<>();

  /**
   * Creates one instance only per id, but cannot guarantee it since LocalApi constructor cant be private
   *
   * @param id the id of the API to be retrieved
   * @param declaration the privacy declaration
   * @return the instance requested
   */
  public static LocalApi getLocalApi(String id, Declaration declaration) throws DeclarationMismatchException {
    synchronized (instances) {
      if (!instances.containsKey(id)) {
        instances.put(id, new LocalApi(id, false, declaration));
      }
    }
    LocalApi l = instances.get(id);
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
  public static LocalApi getLocalApi(String id) {
    return instances.get(id);
  }
}