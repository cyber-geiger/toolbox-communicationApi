package eu.cybergeiger.serialization;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

/**
 * <p>Helper class for serialization serializes important java primitives.</p>
 */
public class SerializerHelper {

  private static final long STRING_UID = 123798371293L;
  private static final long LONG_UID = 1221312393L;
  private static final long INT_UID = 122134568793L;
  private static final long STACKTRACES_UID = 9012350123956L;

  private static void writeIntLong(ByteArrayOutputStream out, Long l) throws IOException {
    byte[] result = new byte[Long.BYTES];
    for (int i = Long.BYTES - 1; i >= 0; i--) {
      result[i] = (byte) (l & 0xFF);
      l >>= Byte.SIZE;
    }
    out.write(result);
  }

  private static Long readIntLong(ByteArrayInputStream in) throws IOException {
    int size = Long.BYTES;
    byte[] arr = new byte[size];
    in.read(arr);
    long result = 0;
    for (int i = 0; i < size; i++) {
      result <<= Byte.SIZE;
      result |= (arr[i] & 0xFF);
    }
    return result;
  }

  private static void writeIntInt(ByteArrayOutputStream out, Integer l) throws IOException {
    int size = Integer.BYTES;
    byte[] result = new byte[size];
    for (int i = size - 1; i >= 0; i--) {
      result[i] = (byte) (l & 0xFF);
      l >>= Byte.SIZE;
    }
    out.write(result);
  }

  private static Integer readIntInt(ByteArrayInputStream in) throws IOException {
    int size = Integer.BYTES;
    byte[] arr = new byte[size];
    in.read(arr);
    int result = 0;
    for (int i = 0; i < size; i++) {
      result <<= Byte.SIZE;
      result |= (arr[i] & 0xFF);
    }
    return result;
  }


  /**
   * Convert bytearray to int.
   *
   * @param bytes bytearray containing 4 bytes
   * @return int denoting the given bytes
   */
  public static int byteArrayToInt(byte[] bytes) {
    return ((bytes[0] & 0xFF) << 24)
      | ((bytes[1] & 0xFF) << 16)
      | ((bytes[2] & 0xFF) << 8)
      | ((bytes[3] & 0xFF));
  }

  /**
   * <p>Convert int to bytearray.</p>
   *
   * @param value the int to convert
   * @return bytearray representing the int
   */
  public static byte[] intToByteArray(int value) {
    return new byte[]{
      (byte) (value >>> 24),
      (byte) (value >>> 16),
      (byte) (value >>> 8),
      (byte) value};
  }

  /**
   * <p>Serialize a long variable.</p>
   *
   * @param out the stream to be read
   * @param l   the value to be deserialized
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static void writeLong(ByteArrayOutputStream out, Long l) throws IOException {
    writeIntLong(out, LONG_UID);
    writeIntLong(out, l);
  }

  /**
   * <p>Deserialize a long variable.</p>
   *
   * @param in the stream to be read
   * @return the deserialized long value
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static Long readLong(ByteArrayInputStream in) throws IOException {
    if (readIntLong(in) != LONG_UID) {
      throw new ClassCastException();
    }
    return readIntLong(in);
  }

  /**
   * <p>Serialize an int variable.</p>
   *
   * @param out the stream to be read
   * @param i   the value to be deserialized
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static void writeInt(ByteArrayOutputStream out, Integer i) throws IOException {
    writeIntLong(out, INT_UID);
    writeIntInt(out, i);
  }

  /**
   * <p>Deserialize an int variable.</p>
   *
   * @param in the stream to be read
   * @return the deserialized integer value
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static Integer readInt(ByteArrayInputStream in) throws IOException {
    if (readIntLong(in) != INT_UID) {
      throw new ClassCastException();
    }
    return readIntInt(in);
  }

  /**
   * <p>Serialize a string variable.</p>
   *
   * @param out the stream to be read
   * @param s   the value to be deserialized
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static void writeString(ByteArrayOutputStream out, String s) throws IOException {
    writeIntLong(out, STRING_UID);
    if (s == null) {
      writeIntInt(out, -1);
    } else {
      writeIntInt(out, s.length());
      out.write(s.getBytes(StandardCharsets.UTF_8));
    }
  }

  /**
   * <p>Deserialize a string variable.</p>
   *
   * @param in the stream to be read
   * @return the deserialized string
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static String readString(ByteArrayInputStream in) throws IOException {
    if (readIntLong(in) != STRING_UID) {
      throw new ClassCastException();
    }
    int length = readIntInt(in);
    if (length == -1) {
      return null;
    } else {
      byte[] arr = new byte[length];
      in.read(arr);
      return new String(arr, StandardCharsets.UTF_8);
    }
  }

  /**
   * <p>Serialize an array of StackTraces.</p>
   *
   * @param out the stream to be read
   * @param ste the value to be deserialized
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static void writeStackTraces(ByteArrayOutputStream out, StackTraceElement[] ste)
    throws IOException {
    writeIntLong(out, STACKTRACES_UID);
    if (ste == null) {
      writeIntInt(out, -1);
    } else {
      writeIntInt(out, ste.length);
      for (StackTraceElement st : ste) {
        writeString(out, st.getClassName());
        writeString(out, st.getMethodName());
        writeString(out, st.getFileName());
        writeInt(out, st.getLineNumber());
      }
    }
  }

  /**
   * <p>Deserialize an array of StackTraceElement variable.</p>
   *
   * @param in the stream to be read
   * @return the deserialized array
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static StackTraceElement[] readStackTraces(ByteArrayInputStream in) throws IOException {
    if (readIntLong(in) != STACKTRACES_UID) {
      throw new ClassCastException();
    }
    int length = readIntInt(in);
    if (length == -1) {
      return null;
    } else {
      StackTraceElement[] arr = new StackTraceElement[length];
      for (int i = 0; i < length; i++) {
        arr[i] = new StackTraceElement(readString(in), readString(in), readString(in), readInt(in));
      }
      return arr;
    }
  }

  /**
   * Read an object from ByteArrayInputStream.
   *
   * @param in the byteArrayInputStream to use
   * @return return the object read
   * @throws IOException if object cannot be read
   */
  public static Object readObject(ByteArrayInputStream in) throws IOException {
    switch ("" + readIntLong(in)) {
      case "" + STRING_UID:
        byte[] arr = new byte[readIntInt(in)];
        in.read(arr);
        return new String(arr, StandardCharsets.UTF_8);
      case "" + LONG_UID:
        return readIntLong(in);
      default:
        throw new ClassCastException();
    }
  }

  /**
   * Write an object to ByteArrayOutputStream.
   *
   * @param out the ByteArrayOutputStream to use
   * @param o   the Object to write
   * @throws IOException if object cannot be written
   */
  public static void writeObject(ByteArrayOutputStream out, Object o) throws IOException {
    switch (o.getClass().getName()) {
      case "String":
        writeString(out, (String) (o));
        break;
      case "Long":
        writeLong(out, (Long) (o));
        break;
      case "Integer":
        writeInt(out, (Integer) (o));
        break;
      default:
        throw new ClassCastException();
    }
  }

  public static void writeMarker(ByteArrayOutputStream out, long marker) throws IOException {
    writeLong(out, marker);
  }

  public static void testMarker(ByteArrayInputStream in, long marker) throws IOException {
    long actual = readLong(in);
    if (marker != actual)
      throw new InvalidObjectException(
        "Actual marker value(" + actual + ") does not match expected value(" + marker + ")."
      );
  }
}
