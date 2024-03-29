library geiger_api;

import 'dart:convert';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

import '../plugin/communication_secret.dart';

class Message {
  static const int serialVersionUID = 143287432;
  static const _hashType = HashType.sha512;

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

  // TODO: change hash so it cannot be miss matched with message content.
  /// Hash of the data
  late Hash hash;

  String? _payloadString = '';

  /// Creates a [Message] with the provided properties.
  Message(this.sourceId, this.targetId, this.type, this.action,
      [List<int>? payload, String? requestId]) {
    this.requestId = requestId ?? '${ExtendedTimestamp.now(false)}';
    if (payload != null) {
      _payloadString = base64.encode(payload);
    }
    hash = integrityHash(CommunicationSecret([]));
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

  Hash integrityHash(CommunicationSecret secret) {
    return _hashType.hashBytes(utf8.encode(sourceId +
            (targetId ?? 'null') +
            type.id.toString() +
            (action?.toString() ?? 'null') +
            requestId) +
        payload +
        secret.secret);
  }

  void toByteArrayStream(ByteSink out, [CommunicationSecret? secret]) {
    SerializerHelper.writeLong(out, serialVersionUID);
    SerializerHelper.writeString(out, sourceId);
    SerializerHelper.writeString(out, targetId);
    SerializerHelper.writeInt(out, type.id);
    if (action == null) {
      SerializerHelper.writeInt(out, 0);
    } else {
      SerializerHelper.writeInt(out, 1);
      action!.toByteArrayStream(out);
    }
    SerializerHelper.writeString(out, requestId);
    SerializerHelper.writeString(out, payloadString);
    (secret == null ? hash : integrityHash(secret)).toByteArrayStream(out);
    SerializerHelper.writeLong(out, serialVersionUID);
  }

  /// Convert ByteArrayInputStream to Message.
  /// @param in the ByteArrayInputStream to use
  /// @return the converted Message
  /// @throws IOException if bytes cannot be read
  static Future<Message> fromByteArray(ByteStream in_) async {
    SerializerHelper.castTest(
        'Message', serialVersionUID, await SerializerHelper.readLong(in_), 1);

    Message m = Message(
        await SerializerHelper.readString(in_) ?? '',
        await SerializerHelper.readString(in_),
        MessageType.getById(await SerializerHelper.readInt(in_)) ??
            MessageType.comapiError,
        (await SerializerHelper.readInt(in_) == 1)
            ? await GeigerUrl.fromByteArrayStream(in_)
            : null,
        null,
        await SerializerHelper.readString(in_));
    m.payloadString = await SerializerHelper.readString(in_);
    m.hash = await Hash.fromByteArrayStream(in_);

    SerializerHelper.castTest(
        'Message', serialVersionUID, await SerializerHelper.readLong(in_), 2);
    return m;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Message &&
            sourceId == other.sourceId &&
            targetId == other.targetId &&
            type == other.type &&
            action == other.action &&
            requestId == other.requestId &&
            payloadString == other.payloadString &&
            hash == other.hash);
  }

  @override
  int get hashCode {
    return (sourceId +
            (targetId ?? 'null') +
            type.hashCode.toString() +
            action.hashCode.toString() +
            requestId +
            (payloadString ?? 'null') +
            hash.toString())
        .hashCode;
  }

  @override
  String toString() {
    return '$sourceId=$requestId>${targetId ?? 'null'}{[$type] (${action ?? ""})'
        '[${hash.hashType.toString()}: ${hash.toString()}]'
        '}';
  }
}
