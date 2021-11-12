library geiger_api;

// FIXME This exception shares large portions of code with Storage Exception.
//       Should have a common Ancestor Serializable Exception in storage

import 'package:geiger_localstorage/geiger_localstorage.dart';

/// Exception signalling wrong communication.
class CommunicationException extends SerializedException implements Serializer {

  static const int serialversionUID = 2348142321;

  String txt;

  CommunicationException(
      this.txt, [Exception? rootCause, StackTrace? rootTrace]) {

    rootCause=SerializedException(rootCause,rootTrace);
  }

  /// Static deserializer.
  ///
  /// Creates a storage exception from the stream.
  ///
  /// @param in The input byte stream to be used
  /// @return the object parsed from the input stream by the respective class
  /// @throws IOException if not overridden or reached unexpectedly the end of stream
  static Future<CommunicationException> fromByteArrayStream(ByteStream in_) async {
    if (await SerializerHelper.readLong(in_) != serialversionUID) {
      throw Exception('cannot cast');
    }

    // read exception text
    String txt = (await SerializerHelper.readString(in_))!;

    // deserialize stacktrace
    StackTrace? ste = await SerializerHelper.readStackTraces(in_);

    // deserialize Throwable
    //List<Throwable> tv = new Vector<>();
    SerializedException? t;

    if (await SerializerHelper.readInt(in_) == 1) {
      t = await SerializedException.fromByteArrayStream(in_);
    }

    // read object end tag (identifier)
    if (await SerializerHelper.readLong(in_) != serialversionUID) {
      throw Exception('cannot cast');
    }
    return CommunicationException(txt, t, ste);
  }

}
