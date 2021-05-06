package eu.cybergeiger.communication;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;

/**
 * <p>Class with convenience methods to write basic datatypes.</p>
 */
public class SerializerHelper {

  private static final long STRING_UID = 123798371293L;
  private static final long LONG_UID = 1221312393L;
  private static final long INT_UID = 122134568793L;

  private static void writeIntLong(ByteArrayOutputStream out, Long l) throws IOException {
    ByteBuffer b = ByteBuffer.allocate(Long.BYTES);
    b.putLong(l);
    out.write(b.array());
  }

  private static Long readIntLong(ByteArrayInputStream in) throws IOException {
    int size = Long.BYTES;
    ByteBuffer b = ByteBuffer.allocate(size);
    byte[] arr = new byte[size];
    in.read(arr);
    b.put(arr, 0, size);
    b.flip();
    return b.getLong();
  }

  private static void writeIntInt(ByteArrayOutputStream out, Integer l) throws IOException {
    ByteBuffer b = ByteBuffer.allocate(Integer.BYTES);
    b.putInt(l);
    out.write(b.array());
  }

  private static Integer readIntInt(ByteArrayInputStream in) throws IOException {
    int size = Integer.BYTES;
    ByteBuffer b = ByteBuffer.allocate(size);
    byte[] arr = new byte[size];
    in.read(arr);
    b.put(arr, 0, size);
    b.flip();
    return b.getInt();
  }

  /**
   * <p>Write Long to ByteArrayOutputStream.</p>
   *
   * @param out the ByteArrayOutputStream to write to
   * @param l the Long to write
   * @throws IOException if value cannot be written
   */
  public static void writeLong(ByteArrayOutputStream out, Long l) throws IOException {
    writeIntLong(out, LONG_UID);
    writeIntLong(out, l);
  }

  /**
   * <p>Read Long from ByteArrayInputStream.</p>
   *
   * @param in ByteArrayInputStream to read from
   * @return the read Long
   * @throws IOException if value cannot be read
   */
  public static Long readLong(ByteArrayInputStream in) throws IOException {
    if (readIntLong(in) != LONG_UID) {
      throw new ClassCastException();
    }
    return readIntLong(in);
  }

  /**
   * <p>Write Int to ByteArrayOutputStream.</p>
   *
   * @param out ByteArrayOutputStream to write to
   * @param i the Integer to write
   * @throws IOException if value cannot be writter
   */
  public static void writeInt(ByteArrayOutputStream out, Integer i) throws IOException {
    writeIntLong(out, INT_UID);
    writeIntInt(out, i);
  }

  /**
   * <p>Read int from ByteArrayInputStream.</p>
   *
   * @param in ByteArrayInputStream to read from
   * @return the read integer
   * @throws IOException if value cannot be read
   */
  public static Integer readInt(ByteArrayInputStream in) throws IOException {
    if (readIntLong(in) != INT_UID) {
      throw new ClassCastException();
    }
    return readIntInt(in);
  }

  /**
   * <p>Writes String to ByteArrayOutputStream.</p>
   *
   * @param out ByteArrayOutputStream to write to
   * @param s String to write
   * @throws IOException if value cannot be written
   */
  public static void writeString(ByteArrayOutputStream out, String s) throws IOException {
    writeIntLong(out, STRING_UID);
    writeIntInt(out, s.length());
    out.write(s.getBytes(StandardCharsets.UTF_8));
  }

  /**
   * <p>Read a String from ByteArrayInputStream.</p>
   *
   * @param in ByteArrayInputStream to read from
   * @return String read from ByteArrayInputStream
   * @throws IOException if String could not be read
   */
  public static String readString(ByteArrayInputStream in) throws IOException {
    if (readIntLong(in) != STRING_UID) {
      throw new ClassCastException();
    }
    byte[] arr = new byte[readIntInt(in)];
    in.read(arr);
    return new String(arr, StandardCharsets.UTF_8);
  }

  /**
   * <p>Read object from ByteArrayInputStream.</p>
   *
   * @param in ByteArrayInputStream to read from
   * @return the object read
   * @throws IOException if Object could not be read
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

}
