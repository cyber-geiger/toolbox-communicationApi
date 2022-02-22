library geiger_api;

import 'package:geiger_localstorage/geiger_localstorage.dart';

/// Exception signalling wrong communication.
class CommunicationException extends SerializedException implements Serializer {
  CommunicationException(String message,
      [Exception? cause, StackTrace? stackTrace])
      : super('CommunicationException',
            message: message, cause: cause, stackTrace: stackTrace);

  static const int serialversionUID = 2348142321;

  /// Static deserializer.
  ///
  /// Creates a storage exception from the stream.
  ///
  /// @param in The input byte stream to be used
  /// @return the object parsed from the input stream by the respective class
  /// @throws IOException if not overridden or reached unexpectedly the end of stream
  static Future<CommunicationException> fromByteArrayStream(
      ByteStream in_) async {
    SerializerHelper.castTest('CommunicationException', serialversionUID,
        await SerializerHelper.readLong(in_), 1);

    // read exception text
    final String message = (await SerializerHelper.readString(in_))!;

    // deserialize stacktrace
    final StackTrace? ste = await SerializerHelper.readStackTraces(in_);

    // deserialize Throwable
    //List<Throwable> tv = new Vector<>();
    SerializedException? t;

    if (await SerializerHelper.readInt(in_) == 1) {
      t = await SerializedException.fromByteArrayStream(in_);
    }

    // read object end tag (identifier)
    SerializerHelper.castTest('CommunicationException', serialversionUID,
        await SerializerHelper.readLong(in_), 2);
    return CommunicationException(message, t, ste);
  }
}
