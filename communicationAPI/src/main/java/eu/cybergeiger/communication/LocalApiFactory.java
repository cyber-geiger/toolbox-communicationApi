package eu.cybergeiger.communication;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class LocalApiFactory {

    private static Map<String, LocalApi> instances = new ConcurrentHashMap<>();

    /**
     * Creates one instance only per id, but cannot guarantee it since LocalApi constructor cant be private
     * @param id
     * @return
     */
    public static LocalApi getLocalApi(String id) {
        synchronized(instances) {
            if (!instances.containsKey(id)) {
                instances.put(id, new LocalApi(id));
            }
        }
        return instances.get(id);
    }
}
