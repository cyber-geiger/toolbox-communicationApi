// FIXME This exception shares large portions of code with Storage Exception.
//       Should have a common Ancestor Serializable Exception in storage

import 'dart:io';

/// <p>Exception signalling wrong communication.</p>
class CommunicationException extends IOException /*implements Serializer*/ {
  /*
  private static class SerializedException extends Throwable implements Serializer {

    private static final long serialversionUID = 2314567434567L;

    private final String exceptionName;
    private final String message;

    public SerializedException(Throwable t) {
      super(t.cause);
      this.message = t.message;
      this.exceptionName = t.getClass().getName();
      setStackTrace(t.stackTrace);
    }

    public SerializedException(String exceptionName, String message, List<StackTraceElement> stacktrace,
                               Throwable cause) {
      super(message, cause);
      this.exceptionName = exceptionName;
      this.message = message;
      setStackTrace(stacktrace);
    }


    public void toByteArrayStrea(ByteArrayOutputStream out) throws IOException {      SerializerHelper.writeLong(out, serialversionUID);      SerializerHelper.writeString(out, exceptionName);      SerializerHelper.writeString(out, message);     SerializerHelper.writeStackTraces(out, stackTrace);
      if (cause != null) {
        SerializerHelper.writeInt(out, 1);
        if (cause instanceof CommunicationException.SerializedException) {
          ((CommunicationException.SerializedException) (cause)).toByteArrayStream(out);
        } else {
          new CommunicationException.SerializedException(cause).toByteArrayStream(out);
        }
      } else {
        SerializerHelper.writeInt(out, 0);
      }
      SerializerHelper.writeLong(out, serialversionUID);
    }    public static SerializedException fromByteArrayStream(ByteArrayInputStream in)        throws IOException {      if (SerializerHelper.readLong(in) != serialversionUID) {       throw new IOException("failed to parse StorageException (bad stream?)");
      }

      // read exception text
      String name = SerializerHelper.readString(in);

      // read exception message
      String message = SerializerHelper.readString(in);

      // read stack trace
      List<StackTraceElement> ste = SerializerHelper.readStackTraces(in);

      // read cause (if any)
      CommunicationException.SerializedException cause = null;
      if (SerializerHelper.readInt(in) == 1) {
        cause = CommunicationException.SerializedException.fromByteArrayStream(in);
      }

      // read object end? tag (identifier)
      if (SerializerHelper.readLong(in) != serialversionUID) {
        throw new IOException("failed to parse NodeImpl (bad stream end?)");
      }
      return new CommunicationException.SerializedException(name, message, ste, cause);
    }
  }
   */

  static final int serialversionUID = 2348142321;

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  /// <p>Standard exception constructor for including a causing exception.</p>
  ///
  /// @param txt the exception message
  /// @param e   the root cause
  CommunicationException(this.message, [this.cause, this.stackTrace]);

/*void toByteArrayStream(ByteArrayOutputStream out) {
    SerializerHelper.writeLong(out, serialversionUID);

    SerializerHelper.writeString(out, message);

    // serialize stack trace
    SerializerHelper.writeStackTraces(out, stackTrace);

    // serializing cause
    CommunicationException.SerializedException cause = null;

    if (cause == null) {
      // empty cause
    } else if (cause is CommunicationException.SerializedException) {
      cause = (CommunicationException.SerializedException) cause;
    } else {
      cause = CommunicationException.SerializedException(cause);
    }
    if (cause != null) {
      SerializerHelper.writeInt(out, 1);
      cause.toByteArrayStream(out);
    } else {
      SerializerHelper.writeInt(out, 0);
    }

    SerializerHelper.writeLong(out, serialversionUID);
  }

  /// <p>Static deserializer.</p>
  ///
  /// <p>CReates a storage exception from the stream.</p>
  ///
  /// @param in The input byte stream to be used
  /// @return the object parsed from the input stream by the respective class
  /// @throws IOException if not overridden or reached unexpectedly the end of stream
  static CommunicationException fromByteArrayStream(ByteArrayInputStream in_) {
    if (SerializerHelper.readLong(in_) != serialversionUID) {
      throw IOException("failed to parse StorageException (bad stream?)");
    }

// read exception text
    String txt = SerializerHelper.readString(in_);

// deserialize stacktrace
    List<StackTraceElement> ste = SerializerHelper.readStackTraces(in_);

// deserialize Throwable
//List<Throwable> tv = new Vector<>();
    Object? t = null;

    if (SerializerHelper.readInt(in_) == 1) {
      t = CommunicationException.SerializedException.fromByteArrayStream(in_);
    }

// read object end tag (identifier)
    if (SerializerHelper.readLong(in_) != serialversionUID) {
      throw IOException(*/ /*"failed to parse NodeImpl (bad stream end?)"*/ /*);
    }
    return CommunicationException(txt, t, ste);
  }*/

}
