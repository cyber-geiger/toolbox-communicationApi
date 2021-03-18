package eu.cybergeiger.communication;

import java.io.Serializable;
import java.security.SecureRandom;
import java.util.Arrays;

/**
 * <p>Encapsulates secret parameters for communication and provides methods to employ them.</p>
 */
public class CommunicationSecret implements Serializable {

  private static final int DEFAULT_SIZE = 32;
  private byte[] secret = new byte[0];

  /**
   * <p>Creates a new secret with random content and standard size.</p>
   */
  public CommunicationSecret() {
    this(DEFAULT_SIZE);
  }

  /**
   * <p>Creates a new secret with random content and specified size.</p>
   *
   * @param size the size of the secret in bytes
   */
  public CommunicationSecret(int size) {
    secret = new byte[size];
    new SecureRandom().nextBytes(secret);
  }

  /**
   * <p>Gets the secret.</p>
   *
   * @return the current secret
   */
  public byte[] getSecret() {
    return Arrays.copyOf(secret, secret.length);
  }

  /**
   * <p>Sets the secret.</p>
   *
   * @param newSecret the new secret bytes
   * @return the previously set secret
   */
  public byte[] setSecret(byte[] newSecret) {
    byte[] ret = this.secret;
    this.secret = Arrays.copyOf(newSecret, newSecret.length);
    return ret;
  }

}
