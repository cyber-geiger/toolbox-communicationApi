package eu.cybergeiger.communication;

import java.security.SecureRandom;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import javax.naming.NameNotFoundException;

public class LocalApi implements PluginRegistrar {

  private class Secret {

    private static final int DEFAULT_SIZE = 32;
    private byte[] secret = new byte[0];

    public Secret() {
      this(DEFAULT_SIZE);
    }

    public Secret(int size) {
      secret = new byte[size];
      new SecureRandom().nextBytes(secret);
    }

    public byte[] getSecret() {
      return Arrays.copyOf(secret, secret.length);
    }

    public byte[] setSecret(byte[] newSecret) {
      byte[] ret = this.secret;
      this.secret = Arrays.copyOf(newSecret, newSecret.length);
      return ret;
    }

  }

  private static Map<String, Secret> secrets = new HashMap<>(1);

  private String id;

  private LocalApi(String id) {
    this.id = id;
  }

  @Override
  public void registerPlugin(String id) {
    // TODO missing implementation
  }

  @Override
  public void deregisterPlugin(String id) throws NameNotFoundException {
    if (secrets.get(id) == null) {
      throw new NameNotFoundException("no communication secret found for id \"" + id + "\"");
    }
    // TODO missing implementation
  }

}
