library geiger_api;

import 'dart:io';

import 'geiger_api.dart';

/// Class to handle incoming messages.
class MessageHandler {
  final Socket _socket;
  final GeigerApi _localApi;

  MessageHandler(this._socket, this._localApi);

  void run() {
    // TODO(mgwerder): completely redo this in the new comm manner
  }
}
