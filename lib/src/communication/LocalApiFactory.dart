
import 'java.dart';
/// <p>Implements a singleton pattern for local API.</p>
class LocalApiFactory
{
    static final java_util_Map<String, LocalApi> instances = new java_util_HashMap();
    /// <p>Creates one instance only per id, but cannot guarantee it since LocalApi constructor cant be
    /// private.</p>
    /// @param executor    the executor string required to run the plugin (may be platform dependant)
    /// @param id          the id of the API to be retrieved
    /// @param declaration the privacy declaration
    /// @return the instance requested
    /// @throws DeclarationMismatchException if the plugin has been registered previously and the
    /// declaration does not match
    /// @throws StorageException             if registration failed
    static LocalApi getLocalApi(String executor, String id, Declaration declaration)
    {
        synchronized(instances, {
            if (!instances.containsKey(id)) {
                if (LocalApi_.MASTER == id) {
                    instances.put(id, new LocalApi(executor, id, true, declaration));
                } else {
                    instances.put(id, new LocalApi(executor, id, false, declaration));
                }
            }
        });
        LocalApi l = instances.get(id);
        if ((declaration != null) && (l.getDeclaration() != declaration)) {
            throw new DeclarationMismatchException();
        }
        return l;
    }

    /// <p>Returns only existing and known instances.</p>
    /// @param id the id to be retrieved
    /// @return the instance or null if not found
    static LocalApi getLocalApi(String id)
    {
        return instances.get(id);
    }

}
