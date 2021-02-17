package eu.cybergeiger.communication;

import java.security.SecureRandom;
import java.util.Arrays;

public class CommunicationSecret {

  private static final int DEFAULT_SIZE = 32;
  private byte[] secret = new byte[0];

  public CommunicationSecret() {
    this(DEFAULT_SIZE);
  }

  public CommunicationSecret(int size) {
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
