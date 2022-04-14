library geiger_api;

import 'dart:convert';

import 'package:geiger_localstorage/geiger_localstorage.dart';

import 'geiger_url.dart';
import 'message_type.dart';

/// Representation of a message.
abstract class Message with Serializer {
  /// ID of the source plugin.
  final String sourceId;

  /// ID of the target plugin.
  final String? targetId;

  /// Type of the message.
  final MessageType type;

  /// Unique ID of the request shared by the request message and the confirmation message.
  late final String requestId;

  /// Returns the action URL of the message.
  final GeigerUrl? action;

  String? _payloadString = '';

  /// Creates a [Message] with the provided properties.
  Message(this.sourceId, this.targetId, this.type, this.action,
      [List<int>? payload, String? requestId]) {
    this.requestId = requestId ?? '${ExtendedTimestamp.now(false)}';
    if (payload != null) {
      _payloadString = base64.encode(payload);
    }
  }

  /// Returns the payload as array of bytes.
  List<int> get payload {
    String? pl = _payloadString;
    if (pl == null) {
      return <int>[];
    }
    return base64.decode(pl);
  }

  /// Sets payload as byte array.
  set payload(List<int> payload) {
    _payloadString = base64.encode(payload);
  }

  /// Returns the payload as a string.
  // ignore: unnecessary_getters_setters
  String? get payloadString {
    return _payloadString;
  }

  /// Sets the payload as a string.
  // ignore: unnecessary_getters_setters
  set payloadString(String? value) {
    _payloadString = value;
  }

  @override
  void toByteArrayStream(ByteSink out);

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;

  @override
  String toString();
}