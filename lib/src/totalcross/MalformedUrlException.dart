import 'dart:io';

/// Exception class to denote a malformed URL.
class MalformedUrlException extends IOException {
  String message;
  Exception? exception;

  MalformedUrlException(this.message, [this.exception]);
}
