package eu.cybergeiger.api.plugin;

import eu.cybergeiger.serialization.Serializable;
import eu.cybergeiger.serialization.SerializerHelper;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Arrays;
import java.util.Base64;


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
  public void toByteArrayStream(OutputStream out) throws IOException {
    SerializerHelper.writeMarker(out, serialVersionUID);
    SerializerHelper.writeString(out, Base64.getEncoder().encodeToString(bytes));
    SerializerHelper.writeMarker(out, serialVersionUID);
  }


  public static CommunicationSecret fromByteArrayStream(InputStream in) throws IOException {
    SerializerHelper.testMarker(in, serialVersionUID);
    byte[] secret = Base64.getDecoder().decode(SerializerHelper.readString(in));
    SerializerHelper.testMarker(in, serialVersionUID);
    return new CommunicationSecret(secret);
  }

  @Override
  public String toString() {
    return Integer.toString(hashCode());
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    CommunicationSecret that = (CommunicationSecret) o;
    return Arrays.equals(bytes, that.bytes);
  }

  @Override
  public int hashCode() {
    return Arrays.hashCode(bytes);
  }
}
