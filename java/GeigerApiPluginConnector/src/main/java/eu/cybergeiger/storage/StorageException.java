package eu.cybergeiger.storage;

import eu.cybergeiger.serialization.Serializable;
import eu.cybergeiger.serialization.SerializerHelper;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;

/**
 * <p>Exception to be raised on any problems related to the local storage.</p>
 */
public class StorageException extends IOException implements Serializable {


  private static class SerializedException extends Throwable implements Serializable {

    private static final long serialversionUID = 721364991234L;

    private final String exceptionName;
    private final String message;

    public SerializedException(Throwable t) {
      super(t.getCause());
      this.message = t.getMessage();
      this.exceptionName = t.getClass().getName();
      setStackTrace(t.getStackTrace());
    }

    public SerializedException(String exceptionName, String message, StackTraceElement[] stacktrace,
                               Throwable cause) {
      super(message, cause);
      this.exceptionName = exceptionName;
      this.message = message;
      setStackTrace(stacktrace);
    }

    @Override
    public void toByteArrayStream(ByteArrayOutputStream out) throws IOException {
      SerializerHelper.writeLong(out, serialversionUID);
      SerializerHelper.writeString(out, exceptionName);
      SerializerHelper.writeString(out, message);
      SerializerHelper.writeStackTraces(out, getStackTrace());
      if (getCause() != null) {
        SerializerHelper.writeInt(out, 1);
        if (getCause() instanceof SerializedException) {
          ((SerializedException) (getCause())).toByteArrayStream(out);
        } else {
          new SerializedException(getCause()).toByteArrayStream(out);
        }
      } else {
        SerializerHelper.writeInt(out, 0);
      }
      SerializerHelper.writeLong(out, serialversionUID);
    }

    public static SerializedException fromByteArrayStream(ByteArrayInputStream in)
      throws IOException {
      if (SerializerHelper.readLong(in) != serialversionUID) {
        throw new IOException("failed to parse StorageException (bad stream?)");
      }

      // read exception text
      String name = SerializerHelper.readString(in);

      // read exception message
      String message = SerializerHelper.readString(in);

      // read stack trace
      StackTraceElement[] ste = SerializerHelper.readStackTraces(in);

      // read cause (if any)
      SerializedException cause = null;
      if (SerializerHelper.readInt(in) == 1) {
        cause = SerializedException.fromByteArrayStream(in);
      }

      // read object end tag (identifier)
      if (SerializerHelper.readLong(in) != serialversionUID) {
        throw new IOException("failed to parse NodeImpl (bad stream end?)");
      }
      return new SerializedException(name, message, ste, cause);
    }
  }

  private static final long serialversionUID = 178324938L;

  private StorageException(String txt, Throwable e, StackTraceElement[] ste) {
    super(txt, e);
    if (ste != null) {
      setStackTrace(ste);
    }
  }

  /**
   * <p>Creates a StorageException with message and root cause.</p>
   *
   * @param txt the message
   * @param e   the root cause
   */
  public StorageException(String txt, Throwable e) {
    this(txt, e, null);
  }

  public StorageException(String txt) {
    this(txt, null, null);
  }

  @Override
  public void toByteArrayStream(ByteArrayOutputStream out) throws IOException {
    SerializerHelper.writeLong(out, serialversionUID);
    SerializerHelper.writeString(out, getMessage());

    // serialize stack trace
    SerializerHelper.writeStackTraces(out, getStackTrace());

    // serializing cause
    SerializedException cause = null;
    if (getCause() == null) {
      if (getCause() instanceof SerializedException) {
        cause = (SerializedException) getCause();
      } else {
        cause = new SerializedException(getCause());
      }
    }
    if (cause != null) {
      SerializerHelper.writeInt(out, 1);
      cause.toByteArrayStream(out);
    } else {
      SerializerHelper.writeInt(out, 0);
    }

    SerializerHelper.writeLong(out, serialversionUID);
  }

  /**
   * <p>Static deserializer.</p>
   *
   * <p>Creates a storage exception from the stream.</p>
   *
   * @param in The input byte stream to be used
   * @return the object parsed from the input stream by the respective class
   * @throws IOException if not overridden or reached unexpectedly the end of stream
   */
  public static StorageException fromByteArrayStream(ByteArrayInputStream in) throws IOException {
    if (SerializerHelper.readLong(in) != serialversionUID) {
      throw new IOException("failed to parse StorageException (bad stream?)");
    }

    // read exception text
    String txt = SerializerHelper.readString(in);

    // deserialize stacktrace
    StackTraceElement[] ste = SerializerHelper.readStackTraces(in);

    // deserialize Throwable
    //List<Throwable> tv = new Vector<>();
    Throwable t = null;

    if (SerializerHelper.readInt(in) == 1) {
      t = SerializedException.fromByteArrayStream(in);
    }

    // read object end tag (identifier)
    if (SerializerHelper.readLong(in) != serialversionUID) {
      throw new IOException("failed to parse NodeImpl (bad stream end?)");
    }
    return new StorageException(txt, t, ste);
  }
}
