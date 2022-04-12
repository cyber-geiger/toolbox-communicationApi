package eu.cybergeiger.serialization;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;

/**
 * <p>Serializer interface for the serialization of value related objects.</p>
 */
public interface Serializer {

  /**
   * <p>Dummy static serializer.</p>
   *
   * <p>Must be overridden by the respective implementing class.</p>
   *
   * @param in The input byte stream to be used
   * @return the object parsed from the input stream by the respective class
   * @throws IOException if not overridden or reached unexpectedly the end of stream
   */
  static Serializer fromByteArrayStream(ByteArrayInputStream in) throws IOException {
    throw new IOException("Not implemented... ");
  }

  /**
   * <p>Writes the current object to the output stream.</p>
   *
   * @param out the output stream receiving the object
   * @throws IOException if  an exception occurs while writing to the stream
   */
  void toByteArrayStream(ByteArrayOutputStream out) throws IOException;

  /**
   * Convenience class to serialize to a bytearray.
   *
   * @param obj the object to serialize
   * @return byteArray representing the object
   */
  static byte[] toByteArray(Serializer obj) {
    try {
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      obj.toByteArrayStream(out);
      return out.toByteArray();
    } catch (IOException ioe) {
      return null;
    }
  }

  /**
   * Convenience Class to deserialize using byte array.
   *
   * @param buf the byte array to deserialize
   * @return Serializer
   */
  static Serializer fromByteArray(byte[] buf) {
    try {
      ByteArrayInputStream in = new ByteArrayInputStream(buf);
      return fromByteArrayStream(in);
    } catch (IOException ioe) {
      ioe.printStackTrace();
      return null;
    }
  }
}
