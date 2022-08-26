package eu.cybergeiger.serialization;

import java.io.*;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;

/**
 * <p>Helper class for serialization serializes important java primitives.</p>
 */
public class SerializerHelper {
  private static final long STRING_UID = 123798371293L;
  private static final long LONG_UID = 1221312393L;
  private static final long INT_UID = 122134568793L;
  private static final long STACKTRACES_UID = 9012350123956L;

  public static void writeRawLong(OutputStream out, Long l) throws IOException {
    out.write(longToByteArray(l));
  }

  public static Long readRawLong(InputStream in) throws IOException {
    byte[] bytes = new byte[Long.BYTES];
    in.read(bytes);
    return byteArrayToLong(bytes);
  }

  public static void writeRawInt(OutputStream out, Integer l) throws IOException {
    out.write(intToByteArray(l));
  }

  public static Integer readRawInt(InputStream in) throws IOException {
    byte[] bytes = new byte[Integer.BYTES];
    in.read(bytes);
    return byteArrayToInt(bytes);
  }

  /**
   * Convert bytearray to long.
   *
   * @param bytes bytearray containing 8 bytes
   * @return long denoting the given bytes
   */
  public static long byteArrayToLong(byte[] bytes) {
    return ByteBuffer.wrap(bytes).getLong();
  }

  /**
   * <p>Convert long to bytearray.</p>
   *
   * @param value the long to convert
   * @return bytearray representing the int
   */
  public static byte[] longToByteArray(long value) {
    ByteBuffer buffer = ByteBuffer.allocate(Long.BYTES);
    buffer.putLong(value);
    return buffer.array();
  }


  /**
   * Convert bytearray to int.
   *
   * @param bytes bytearray containing 4 bytes
   * @return int denoting the given bytes
   */
  public static int byteArrayToInt(byte[] bytes) {
    return ByteBuffer.wrap(bytes).getInt();
  }

  /**
   * <p>Convert int to bytearray.</p>
   *
   * @param value the int to convert
   * @return bytearray representing the int
   */
  public static byte[] intToByteArray(int value) {
    ByteBuffer buffer = ByteBuffer.allocate(Integer.BYTES);
    buffer.putInt(value);
    return buffer.array();
  }

  /**
   * <p>Serialize a long variable.</p>
   *
   * @param out the stream to be read
   * @param l   the value to be deserialized
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static void writeLong(OutputStream out, Long l) throws IOException {
    writeRawLong(out, LONG_UID);
    writeRawLong(out, l);
  }

  /**
   * <p>Deserialize a long variable.</p>
   *
   * @param in the stream to be read
   * @return the deserialized long value
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static Long readLong(InputStream in) throws IOException {
    long raw = readRawLong(in);
    if (raw != LONG_UID) {
      throw new ClassCastException();
    }
    return readRawLong(in);
  }

  /**
   * <p>Serialize an int variable.</p>
   *
   * @param out the stream to be read
   * @param i   the value to be deserialized
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static void writeInt(OutputStream out, Integer i) throws IOException {
    writeRawLong(out, INT_UID);
    writeRawInt(out, i);
  }

  /**
   * <p>Deserialize an int variable.</p>
   *
   * @param in the stream to be read
   * @return the deserialized integer value
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static Integer readInt(InputStream in) throws IOException {
    long marker = readRawLong(in);
    if (marker != INT_UID) {
      throw new ClassCastException();
    }
    return readRawInt(in);
  }

  /**
   * <p>Serialize a string variable.</p>
   *
   * @param out   the stream to be read
   * @param value the value to be serialized
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static void writeString(OutputStream out, String value) throws IOException {
    writeRawLong(out, STRING_UID);
    if (value == null) {
      writeRawInt(out, -1);
      return;
    }
    byte[] bytes = value.getBytes(StandardCharsets.UTF_8);
    writeRawInt(out, bytes.length);
    out.write(bytes);
  }

  /**
   * <p>Deserialize a string variable.</p>
   *
   * @param in the stream to be read
   * @return the deserialized string
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static String readString(InputStream in) throws IOException {
    if (readRawLong(in) != STRING_UID)
      throw new ClassCastException();
    int length = readRawInt(in);
    if (length == -1) return null;

    ByteArrayOutputStream out = new ByteArrayOutputStream(length);
    byte[] buffer = new byte[4096];
    int bytesRead;
    while ((bytesRead = in.read(
      buffer,
      0,
      Math.min(length - out.size(), buffer.length)
    )) > 0)
      out.write(buffer, 0, bytesRead);
    if (out.size() != length) {
      throw new IOException("Insufficient data to deserialize String.");
    }
    return new String(out.toByteArray(), StandardCharsets.UTF_8);
  }

  /**
   * <p>Serialize a stack trace of the provided throwable.</p>
   *
   * @param out       the stream to be read
   * @param throwable the throwable to serialize the stack trace of
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static void writeStackTraces(OutputStream out, Throwable throwable)
    throws IOException {
    StringWriter writer = new StringWriter();
    throwable.printStackTrace(new PrintWriter(writer));
    SerializerHelper.writeStackTraces(out, writer.toString());
  }

  /**
   * <p>Serialize a stack trace. The stack trace is a string to support multiple languages.</p>
   *
   * @param out        the stream to be read
   * @param stackTrace the value to be deserialized
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static void writeStackTraces(OutputStream out, String stackTrace)
    throws IOException {
    writeRawLong(out, STACKTRACES_UID);
    writeString(out, stackTrace);
  }

  /**
   * <p>Deserialize a stack trace. The stack trace is a string to support multiple languages.</p>
   *
   * @param in the stream to be read
   * @return The stack trace
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static String readStackTraces(InputStream in) throws IOException {
    if (readRawLong(in) != STACKTRACES_UID) {
      throw new ClassCastException();
    }
    return readString(in);
  }

  /**
   * <p>Deserialize a stack trace and put it into a single StackTraceElement.</p>
   *
   * @param in the stream to be read
   * @return The stack trace
   * @throws IOException if an exception occurs while writing to the stream
   */
  public static StackTraceElement[] readStackTracesWrapped(InputStream in) throws IOException {
    String trace = SerializerHelper.readStackTraces(in);
    if (trace == null) return null;
    return new StackTraceElement[]{
      new StackTraceElement("", "", trace, 0)
    };
  }

  public static void writeMarker(OutputStream out, long marker) throws IOException {
    writeLong(out, marker);
  }

  public static void testMarker(InputStream in, long marker) throws IOException {
    long actual = readLong(in);
    if (marker != actual)
      throw new ClassCastException(
        "Actual marker value " + actual + " does not match expected value " + marker + "."
      );
  }
}
