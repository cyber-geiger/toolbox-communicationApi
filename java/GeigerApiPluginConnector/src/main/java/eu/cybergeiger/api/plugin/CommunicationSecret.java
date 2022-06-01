package eu.cybergeiger.api.plugin;

import eu.cybergeiger.serialization.Serializable;
import eu.cybergeiger.serialization.SerializerHelper;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Arrays;
import java.util.Base64;
import java.util.Random;


/**
 * <p>Encapsulates secret parameters for communication and provides methods to employ them.</p>
 */
public class CommunicationSecret implements Serializable {
  private static final long serialVersionUID = 8901230L;

  private byte[] bytes;

  /**
   * Creates a zero length secret.
   */
  public CommunicationSecret() {
    this(new byte[0]);
  }

  /**
   * Creates a secret with the provided bytes.
   */
  public CommunicationSecret(byte[] secret) {
    setBytes(secret);
  }

  public byte[] getBytes() {
    return Arrays.copyOf(bytes, bytes.length);
  }

  public void setBytes(byte[] bytes) {
    this.bytes = Arrays.copyOf(bytes, bytes.length);
  }

  @Override
  public void toByteArrayStream(ByteArrayOutputStream out) throws IOException {
    SerializerHelper.writeMarker(out, serialVersionUID);
    SerializerHelper.writeString(out, Base64.getEncoder().encodeToString(bytes));
    SerializerHelper.writeMarker(out, serialVersionUID);
  }


  public static CommunicationSecret fromByteArrayStream(ByteArrayInputStream in) throws IOException {
    SerializerHelper.testMarker(in, serialVersionUID);
    byte[] secret = Base64.getDecoder().decode(SerializerHelper.readString(in));
    SerializerHelper.testMarker(in, serialVersionUID);
    return new CommunicationSecret(secret);
  }

  @Override
  public String toString() {
    return Integer.toString(Arrays.hashCode(bytes));
  }
}
