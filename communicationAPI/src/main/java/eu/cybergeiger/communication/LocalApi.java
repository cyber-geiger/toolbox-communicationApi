package eu.cybergeiger.communication;

import java.util.HashMap;
import java.util.Map;
import javax.naming.NameNotFoundException;
//import eu.cybergeiger.communication.CommunicationSecret;

public class LocalApi implements PluginRegistrar {

  private static Map<String, CommunicationSecret> secrets = new HashMap<>(1);

  private String id;

  protected LocalApi(String id) {
    this.id = id;
  }

  @Override
  public void registerPlugin(String id) {
    // TODO missing implementation
//    CommunicationSecret secret = new CommunicationSecret();
//    secrets.put(id, secret);
  }

  @Override
  public void deregisterPlugin(String id) throws NameNotFoundException {
    if (secrets.get(id) == null) {
      throw new NameNotFoundException("no communication secret found for id \"" + id + "\"");
    }
    // TODO missing implementation
  }

}
