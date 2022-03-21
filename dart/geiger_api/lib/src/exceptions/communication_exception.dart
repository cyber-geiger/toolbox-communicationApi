library geiger_api;

import 'package:geiger_localstorage/geiger_localstorage.dart';

/// Exception signalling wrong communication.
class CommunicationException extends SerializedException implements Serializer {
  CommunicationException(String message,
      [Exception? cause, StackTrace? stackTrace])
      : super('CommunicationException',
            message: message, cause: cause, stackTrace: stackTrace);

  static const int serialversionUID = 2348142321;
}
