import 'dart:convert';

import 'GeigerUrl.dart';
import 'MessageType.dart';

/// Representation of a message.
class Message // with ch_fhnw_geiger_serialization_Serializer
{
  static const int serialVersionUID = 143287432;
  final String? sourceId;
  final String? targetId;
  final MessageType type;
  final GeigerUrl? action;
  String? payloadString;

  /// Creates a [Message] with the provided properties.
  Message(this.sourceId, this.targetId, this.type, this.action,
      [List<int>? payload]) {
    if (payload != null) {
      setPayload(payload);
    }
  }

  /// Returns the target id of the message.
  String? getTargetId() {
    return targetId;
  }

  /// Returns the source id of the message.
  String? getSourceId() {
    return sourceId;
  }

  /// Returns the type of the message.
  MessageType getType() {
    return type;
  }

  /// Returns the action URL of the message.
  GeigerUrl? getAction() {
    return action;
  }

  /// Returns the payload as array of bytes.
  List<int>? getPayload() {
    var pl = payloadString;
    if (pl == null) {
      return null;
    }
    return base64.decode(pl);
  }

  /// Sets payload as byte array.
  void setPayload(List<int>? payload) {
    payloadString = (payload == null) ? null : base64.encode(payload);
  }

  /// Returns the payload as a string.
  String? getPayloadString() {
    return payloadString;
  }

  /// Sets the payload as a string and returns the previous payload string.
  String? setPayloadString(String value) {
    var ret = payloadString;
    payloadString = value;
    return ret;
  }

  /* /// Convert ByteArrayInputStream to Message.
    /// @param in the ByteArrayInputStream to use
    /// @return the converted Message
    /// @throws IOException if bytes cannot be read
    static Message fromByteArray(ch_fhnw_geiger_totalcross_ByteArrayInputStream in_)
    {
        if (SerializerHelper.readLong(in_) != serialVersionUID) {
            throw new ClassCastException();
        }
        Message m = new Message((SerializerHelper.readInt(in_) == 1) ? SerializerHelper.readString(in_) : null, (SerializerHelper.readInt(in_) == 1) ? SerializerHelper.readString(in_) : null, (SerializerHelper.readInt(in_) == 1) ? MessageType_.getById(SerializerHelper.readInt(in_)) : null, (SerializerHelper.readInt(in_) == 1) ? GeigerUrl_.fromByteArrayStream(in_) : null);
        m.setPayloadString((SerializerHelper.readInt(in_) == 1) ? SerializerHelper.readString(in_) : null);
        return m;
    }

    void toByteArrayStream(ch_fhnw_geiger_totalcross_ByteArrayOutputStream out)
    {
        SerializerHelper.writeLong(out, serialVersionUID);
        if (sourceId != null) {
            SerializerHelper.writeInt(out, 1);
            SerializerHelper.writeString(out, sourceId);
        } else {
            SerializerHelper.writeInt(out, 0);
        }
        if (targetId != null) {
            SerializerHelper.writeInt(out, 1);
            SerializerHelper.writeString(out, targetId);
        } else {
            SerializerHelper.writeInt(out, 0);
        }
        if (type != null) {
            SerializerHelper.writeInt(out, 1);
            SerializerHelper.writeInt(out, type.getId());
        } else {
            SerializerHelper.writeInt(out, 0);
        }
        if (action == null) {
            SerializerHelper.writeInt(out, 0);
        } else {
            SerializerHelper.writeInt(out, 1);
            action.toByteArrayStream(out);
        }
        if (payloadString == null) {
            SerializerHelper.writeInt(out, 0);
        } else {
            SerializerHelper.writeInt(out, 1);
            SerializerHelper.writeString(out, payloadString);
        }
    }*/

  @override
  bool operator ==(Object other) => equals(other);

  bool equals(Object? o) {
    if (this == o) {
      return true;
    }
    if ((o == null) || !(o is Message)) {
      return false;
    }
    var message = o;
    return (((sourceId == message.sourceId && targetId == message.targetId) &&
                (type == message.type)) &&
            action == message.action) &&
        payloadString == message.payloadString;
  }

  @override
  int get hashCode {
    return ((sourceId ?? 'null') +
            (targetId ?? 'null') +
            type.hashCode.toString() +
            action.hashCode.toString() +
            (payloadString ?? 'null'))
        .hashCode;
  }

  @override
  String toString() {
    return (getSourceId() ?? 'null') +
        '=>' +
        (getTargetId() ?? 'null') +
        '{[' +
        getType().toString() +
        '] ' +
        (getAction()?.toString() ?? 'null') +
        '}';
  }
}
