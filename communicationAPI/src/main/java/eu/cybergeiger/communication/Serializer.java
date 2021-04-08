package eu.cybergeiger.communication;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;

public interface Serializer<T> {

  static Object fromByteArrayStream(ByteArrayInputStream out) throws IOException {
    throw new IOException("Not implemented... ");
  }

  /**
   * <p>Writes the current oject to the output stream.</p>
   * @param out the output stream receiving the object
   */
  void toByteArrayStream(ByteArrayOutputStream out) throws IOException;


  static Object fromByteArrayStream(ByteArrayInputStream out) throws IOException;
}
