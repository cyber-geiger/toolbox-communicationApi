library geiger_api;

import 'dart:convert';

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

class Message {
  static const int serialVersionUID = 143287432;

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

  void toByteArrayStream(ByteSink out) {
        SerializerHelper.writeLong(out, serialVersionUID);
    SerializerHelper.writeString(out, sourceId);
    if (targetId == null) {
      SerializerHelper.writeInt(out, 0);
    } else {
      SerializerHelper.writeInt(out, 1);
      SerializerHelper.writeString(out, targetId);
    }
    SerializerHelper.writeInt(out, type.id);
    if (action == null) {
      SerializerHelper.writeInt(out, 0);
    } else {
      SerializerHelper.writeInt(out, 1);
      action?.toByteArrayStream(out);
    }
    SerializerHelper.writeString(out, requestId);
    if (payloadString == null) {
      SerializerHelper.writeInt(out, 0);
    } else {
      SerializerHelper.writeInt(out, 1);
      SerializerHelper.writeString(out, payloadString);
    }
    SerializerHelper.writeLong(out, serialVersionUID);
  }

  /// Convert ByteArrayInputStream to Message.
  /// @param in the ByteArrayInputStream to use
  /// @return the converted Message
  /// @throws IOException if bytes cannot be read
  static Future<Message> fromByteArray(ByteStream in_) async{
     SerializerHelper.castTest(
        'Message', serialVersionUID, await SerializerHelper.readLong(in_), 1);
      Message m = Message(
        await SerializerHelper.readString(in_) ?? '',
        (await SerializerHelper.readInt(in_) == 1)
            ? await SerializerHelper.readString(in_)
            : null,
        MessageType.getById(await SerializerHelper.readInt(in_)) ??
            MessageType.comapiError,
        (await SerializerHelper.readInt(in_) == 1)
            ? await GeigerUrl.fromByteArrayStream(in_)
            : null,
        null,
        await SerializerHelper.readString(in_));
    m.payloadString = (await SerializerHelper.readInt(in_) == 1)
        ? await SerializerHelper.readString(in_)
        : null;
    SerializerHelper.castTest(
        'Message', serialVersionUID, await SerializerHelper.readLong(in_), 2);
    return m;
  }

  @override
  bool operator ==(Object other){
    return identical(this, other) ||
        (other is Message &&
            sourceId == other.sourceId &&
            targetId == other.targetId &&
            type == other.type &&
            action == other.action &&
            requestId == other.requestId &&
            payloadString == other.payloadString);
  }


  @override
  int get hashCode{
    return (sourceId +
            (targetId ?? 'null') +
            type.hashCode.toString() +
            action.hashCode.toString() +
            requestId +
            (payloadString ?? 'null'))
        .hashCode;
  }

  @override
  String toString(){
    return '$sourceId=$requestId>${targetId ?? 'null'}{[$type] (${action ?? ""})}';
  }
}