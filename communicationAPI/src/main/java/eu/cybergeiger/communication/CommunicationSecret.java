package eu.cybergeiger.communication;

import ch.fhnw.geiger.serialization.Serializer;
import ch.fhnw.geiger.serialization.SerializerHelper;
import ch.fhnw.geiger.totalcross.ByteArrayInputStream;
import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;
import eu.cybergeiger.totalcross.Base64;
import eu.cybergeiger.totalcross.Random;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;


/**
 * <p>Encapsulates secret parameters for communication and provides methods to employ them.</p>
 */
public class CommunicationSecret implements Serializer {

  private static final long serialVersionUID = 8901230L;

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
    setRandomSecret(size);
  }

  /**
   * <p>Creates a secret which is already known.</p>
   *
   * @param secret the already known secret
   */
  public CommunicationSecret(byte[] secret) {
    if (secret == null || secret.length == 0) {
      setRandomSecret(DEFAULT_SIZE);
    } else {
      this.secret = secret;
    }
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
   * <p>Sets a new Secret with size.</p>
   *
   * @param size the size of the new secret
   */
  private void setRandomSecret(int size) {
    if (size <= 0) {
      throw new IllegalArgumentException("size must be greater than 0");
    }
    secret = new byte[size];
    // TODO get proper randomization, secureRandom() does not exists in TotalCross
    for (int i = 0; i < size; i++) {
      int value = Random.nextInt(Integer.MAX_VALUE);
      secret[i] = (byte) (value);
    }
  }

  /**
   * <p>Sets the secret.</p>
   * If new secret is null or its length is 0 a random secret is generated
   *
   * @param newSecret the new secret bytes
   * @return the previously set secret
   */
  public byte[] setSecret(byte[] newSecret) {
    byte[] ret = this.secret;
    if (newSecret == null || newSecret.length == 0) {
      setRandomSecret(DEFAULT_SIZE);
    } else {
      this.secret = Arrays.copyOf(newSecret, newSecret.length);
    }
    return ret;
  }

  @Override
  public void toByteArrayStream(ByteArrayOutputStream out) throws IOException {
    SerializerHelper.writeLong(out, serialVersionUID);
    // TotalCross adaption
    SerializerHelper.writeString(out, Base64.encodeToString(secret));
    //SerializerHelper.writeString(out, Base64.getEncoder().encodeToString(secret));
    SerializerHelper.writeLong(out, serialVersionUID);
  }


  /**
   * <p>Reads objects from ByteArrayInputStream and stores them in map.</p>
   *
   * @param in ByteArrayInputStream to be used
   * @return the deserialized Storable String
   * @throws IOException if value cannot be read
   */
  public static CommunicationSecret fromByteArrayStream(ByteArrayInputStream in)
      throws IOException {
    if (SerializerHelper.readLong(in) != serialVersionUID) {
      throw new ClassCastException("Reading start marker fails");
    }
    // TotalCross adaption
    byte[] secret = Base64.decode(SerializerHelper.readString(in));
    //byte[] secret = Base64.getDecoder().decode(SerializerHelper.readString(in));
    CommunicationSecret ret = new CommunicationSecret(secret);
    if (SerializerHelper.readLong(in) != serialVersionUID) {
      throw new ClassCastException("Reading end marker fails");
    }
    return ret;
  }

  @Override
  public String toString() {
    return "" + (new String(secret, StandardCharsets.UTF_8)).hashCode();
  }
}
