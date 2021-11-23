library geiger_api;

import 'dart:convert';

import 'package:geiger_localstorage/geiger_localstorage.dart';

import 'geiger_url.dart';
import 'message_type.dart';

/// Representation of a message.
class Message with Serializer {
  static const int serialVersionUID = 143287432;
  String _id = '<undefined>';
  final String _sourceId;
  final String? _targetId;
  final MessageType _type;
  final GeigerUrl? _action;
  String? _payloadString = '';

  /// Creates a [Message] with the provided properties.
  Message(this._sourceId, this._targetId, this._type, this._action,
      [List<int>? payload, String? replyToId]) {
    replyToId ??= '${ExtendedTimestamp.now(false)}';
    if (payload != null) {
      _payloadString = base64.encode(payload);
    }
    _id = replyToId;
  }

  /// Returns the target id of the message.
  String? get targetId {
    return _targetId;
  }

  /// Returns the source id of the message.
  String get sourceId {
    return _sourceId;
  }

  /// Returns the type of the message.
  MessageType get type {
    return _type;
  }

  /// Returns the action URL of the message.
  GeigerUrl? get action {
    return _action;
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

  /// Sets the payload as a string and returns the previous payload string.
  // ignore: unnecessary_getters_setters
  set payloadString(String? value) {
    _payloadString = value;
  }

  /// Convert ByteArrayInputStream to Message.
  /// @param in the ByteArrayInputStream to use
  /// @return the converted Message
  /// @throws IOException if bytes cannot be read
  static Future<Message> fromByteArray(ByteStream in_) async {
    if (await SerializerHelper.readLong(in_) != serialVersionUID) {
      throw Exception('cannot cast');
    }
    Message m = Message(
        await SerializerHelper.readString(in_) ?? '',
        (await SerializerHelper.readInt(in_) == 1)
            ? await SerializerHelper.readString(in_)
            : null,
        MessageType.getById(await SerializerHelper.readInt(in_)) ??
            MessageType.storageError,
        (await SerializerHelper.readInt(in_) == 1)
            ? await GeigerUrl.fromByteArrayStream(in_)
            : null);
    m._payloadString = (await SerializerHelper.readInt(in_) == 1)
        ? await SerializerHelper.readString(in_)
        : null;
    return m;
  }

  @override
  void toByteArrayStream(ByteSink out) {
    SerializerHelper.writeLong(out, serialVersionUID);
    SerializerHelper.writeString(out, sourceId);
    if (targetId == null) {
      SerializerHelper.writeInt(out, 0);
    } else {
      SerializerHelper.writeInt(out, 1);
      SerializerHelper.writeString(out, targetId);
    }
    SerializerHelper.writeInt(out, _type.id);
    if (action == null) {
      SerializerHelper.writeInt(out, 0);
    } else {
      SerializerHelper.writeInt(out, 1);
      action?.toByteArrayStream(out);
    }
    if (payloadString == null) {
      SerializerHelper.writeInt(out, 0);
    } else {
      SerializerHelper.writeInt(out, 1);
      SerializerHelper.writeString(out, payloadString);
    }
  }

  @override
  bool operator ==(Object other) => equals(other);

  bool equals(Object? o) {
    if (identical(this, o)) {
      return true;
    }
    if ((o == null) || o is! Message) {
      return false;
    }
    var message = o;
    return (((sourceId == message.sourceId && targetId == message.targetId) &&
                (type == message.type)) &&
            _action == message._action) &&
        payloadString == message.payloadString;
  }

  @override
  int get hashCode {
    return (sourceId +
            (targetId ?? 'null') +
            type.hashCode.toString() +
            _action.hashCode.toString() +
            (payloadString ?? 'null'))
        .hashCode;
  }

  @override
  String toString() {
    return '$sourceId=>${targetId ?? 'null'}{[$type] (${action ?? "".toString()}) }';
  }
}
