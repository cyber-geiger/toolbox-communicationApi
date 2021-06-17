package eu.cybergeiger.communication;

import ch.fhnw.geiger.serialization.Serializer;
import ch.fhnw.geiger.serialization.SerializerHelper;
import ch.fhnw.geiger.totalcross.ByteArrayInputStream;
import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;
import java.io.IOException;

/**
 * <p>A serializable yet simple String object.</p>
 */
public class StorableString implements Serializer {

  private static final long serialVersionUID = 142314912322198374L;

  private final String value;

  public StorableString() {
    value = "";
  }

  public StorableString(String value) {
    this.value = value;
  }

  public String toString() {
    return value;
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    }
    if (o == null || getClass() != o.getClass()) {
      return false;
    }
    StorableString that = (StorableString) o;
    return (value == null && that.value == null) || (value != null && value.equals(that.value));
  }

  @Override
  public int hashCode() {
    return value.hashCode();
  }

  @Override
  public void toByteArrayStream(ByteArrayOutputStream out) throws IOException {
    SerializerHelper.writeString(out, this.value);
  }

  /**
   * <p>Reads objects from ByteArrayInputStream and stores them in map.</p>
   *
   * @param in ByteArrayInputStream to be used
   * @return the deserialized Storable String
   * @throws IOException if value cannot be read
   */
  public StorableString fromByteArrayStream(ByteArrayInputStream in) throws IOException {
    return new StorableString(SerializerHelper.readString(in));
  }
}
