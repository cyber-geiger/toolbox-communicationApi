package eu.cybergeiger.api.exceptions;

import eu.cybergeiger.serialization.Serializable;
import eu.cybergeiger.serialization.SerializerHelper;

import java.io.*;

// FIXME This exception shares large portions of code with Storage Exception.
//       Should have a common Ancestor Serializable Exception in storage

/**
 * <p>Exception signalling wrong communication.</p>
 */
public class CommunicationException extends IOException implements Serializable {

  private static class SerializedException extends Throwable implements Serializable {

    private static final long serialVersionUID = 2314567434567L;

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
    public void toByteArrayStream(OutputStream out) throws IOException {
      SerializerHelper.writeLong(out, serialVersionUID);
      SerializerHelper.writeString(out, exceptionName);
      SerializerHelper.writeString(out, message);
      SerializerHelper.writeStackTraces(out, this);
      if (getCause() != null) {
        SerializerHelper.writeInt(out, 1);
        if (getCause() instanceof CommunicationException.SerializedException) {
          ((CommunicationException.SerializedException) (getCause())).toByteArrayStream(out);
        } else {
          new CommunicationException.SerializedException(getCause()).toByteArrayStream(out);
        }
      } else {
        SerializerHelper.writeInt(out, 0);
      }
      SerializerHelper.writeLong(out, serialVersionUID);
    }

    public static SerializedException fromByteArrayStream(InputStream in)
      throws IOException {
      if (SerializerHelper.readLong(in) != serialVersionUID) {
        throw new IOException("failed to parse StorageException (bad stream?)");
      }

      // read exception text
      String name = SerializerHelper.readString(in);

      // read exception message
      String message = SerializerHelper.readString(in);

      // read stack trace into a single element
      StackTraceElement[] ste = SerializerHelper.readStackTracesWrapped(in);

      // read cause (if any)
      CommunicationException.SerializedException cause = null;
      if (SerializerHelper.readInt(in) == 1) {
        cause = CommunicationException.SerializedException.fromByteArrayStream(in);
      }

      // read object end tag (identifier)
      if (SerializerHelper.readLong(in) != serialVersionUID) {
        throw new IOException("failed to parse NodeImpl (bad stream end?)");
      }
      return new CommunicationException.SerializedException(name, message, ste, cause);
    }
  }

  private static final long serialVersionUID = 2348142321L;

  private CommunicationException(String txt, Throwable e, StackTraceElement[] ste) {
    super(txt, e);
    if (ste != null) {
      setStackTrace(ste);
    }
  }

  /**
   * <p>Standard exception constructor for including a causing exception.</p>
   *
   * @param txt the exception message
   * @param e   the root cause
   */
  public CommunicationException(String txt, Throwable e) {
    super(txt, e);
  }

  /**
   * <p>Standard exception constructor.</p>
   *
   * @param txt the exception message.
   */
  public CommunicationException(String txt) {
    this(txt, null);
  }

  @Override
  public void toByteArrayStream(OutputStream out) throws IOException {
    SerializerHelper.writeLong(out, serialVersionUID);
    SerializerHelper.writeString(out, getMessage());

    // serialize stack trace
    SerializerHelper.writeStackTraces(out, this);

    // serializing cause
    CommunicationException.SerializedException cause = null;
    if (getCause() != null) {
      if (getCause() instanceof CommunicationException.SerializedException) {
        cause = (CommunicationException.SerializedException) getCause();
      } else {
        cause = new CommunicationException.SerializedException(getCause());
      }
    }
    if (cause != null) {
      SerializerHelper.writeInt(out, 1);
      cause.toByteArrayStream(out);
    } else {
      SerializerHelper.writeInt(out, 0);
    }

    SerializerHelper.writeLong(out, serialVersionUID);
  }

  /**
   * <p>Static deserializer.</p>
   *
   * <p>CReates a storage exception from the stream.</p>
   *
   * @param in The input byte stream to be used
   * @return the object parsed from the input stream by the respective class
   * @throws IOException if not overridden or reached unexpectedly the end of stream
   */
  public static CommunicationException fromByteArrayStream(InputStream in)
    throws IOException {
    if (SerializerHelper.readLong(in) != serialVersionUID) {
      throw new IOException("failed to parse StorageException (bad stream?)");
    }

    // read exception text
    String txt = SerializerHelper.readString(in);

    // deserialize stack trace into a single element
    StackTraceElement[] ste = SerializerHelper.readStackTracesWrapped(in);

    // deserialize Throwable
    //List<Throwable> tv = new Vector<>();
    Throwable t = null;

    if (SerializerHelper.readInt(in) == 1) {
      t = CommunicationException.SerializedException.fromByteArrayStream(in);
    }

    // read object end tag (identifier)
    if (SerializerHelper.readLong(in) != serialVersionUID) {
      throw new IOException("failed to parse NodeImpl (bad stream end?)");
    }
    return new CommunicationException(txt, t, ste);
  }

}
