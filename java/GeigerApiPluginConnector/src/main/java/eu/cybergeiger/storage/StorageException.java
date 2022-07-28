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
  public static class SerializedException extends Throwable implements Serializable {
    private static final long serialVersionUID = 721364991234L;

    private final String name;

    public SerializedException(Throwable throwable) {
      this(
        throwable.getClass().getName(),
        throwable.getMessage(),
        throwable.getStackTrace(),
        throwable.getCause()
      );
    }

    public SerializedException(String name, String message, StackTraceElement[] stacktrace,
                               Throwable cause) {
      super(message, cause == null || cause instanceof SerializedException ? cause : new SerializedException(cause));
      this.name = name;
      setStackTrace(stacktrace);
    }

    // TODO: deduplicate serialization code

    @Override
    public void toByteArrayStream(ByteArrayOutputStream out) throws IOException {
      SerializerHelper.writeMarker(out, serialVersionUID);
      SerializerHelper.writeString(out, name);
      SerializerHelper.writeString(out, getMessage());
      SerializerHelper.writeStackTraces(out, this);
      if (getCause() != null) {
        SerializerHelper.writeInt(out, 1);
        ((SerializedException) getCause()).toByteArrayStream(out);
      } else {
        SerializerHelper.writeInt(out, 0);
      }
      SerializerHelper.writeMarker(out, serialVersionUID);
    }

    public static SerializedException fromByteArrayStream(ByteArrayInputStream in)
      throws IOException {
      SerializerHelper.testMarker(in, serialVersionUID);
      String name = SerializerHelper.readString(in);
      String message = SerializerHelper.readString(in);
      StackTraceElement[] stackTrace = SerializerHelper.readStackTracesWrapped(in);
      SerializedException cause = null;
      if (SerializerHelper.readInt(in) == 1) {
        cause = SerializedException.fromByteArrayStream(in);
      }
      SerializerHelper.testMarker(in, serialVersionUID);
      return new SerializedException(name, message, stackTrace, cause);
    }

    @Override
    public String toString() {
      String message = getLocalizedMessage();
      return (message != null) ? (name + ": " + message) : name;
    }
  }

  public StorageException() {
    super();
  }

  public StorageException(String message) {
    super(message);
  }

  public StorageException(String message, Throwable cause) {
    super(message, cause);
  }

  public StorageException(Throwable cause) {
    super(cause);
  }

  @Override
  public void toByteArrayStream(ByteArrayOutputStream out) throws IOException {
    new SerializedException(this).toByteArrayStream(out);
  }

  public static StorageException fromByteArrayStream(ByteArrayInputStream in)
    throws IOException {
    SerializedException originalException = SerializedException.fromByteArrayStream(in);
    StorageException storageException = new StorageException(
      originalException.getMessage(),
      originalException.getCause()
    );
    storageException.setStackTrace(originalException.getStackTrace());
    return storageException;
  }
}
