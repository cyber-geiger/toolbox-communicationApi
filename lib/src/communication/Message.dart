import 'dart:convert';

import 'GeigerUrl.dart';
import 'MessageType.dart';

/// <p>Representation of a message.</p>
class Message // with ch_fhnw_geiger_serialization_Serializer
{
  static const int serialVersionUID = 143287432;
  final String? sourceId;
  final String? targetId;
  final MessageType type;
  final GeigerUrl? action;
  String? payloadString;

  /// <p>A message object transported through the local communication api.</p>
  /// @param sourceId the id of the source plugin
  /// @param targetId the id of the target plugin
  /// @param type     the type of message
  /// @param action   the url of the event
  /// @param payload  the payload section of the message
  Message(this.sourceId, this.targetId, this.type, this.action,
      [List<int>? payload]) {
    if (payload != null) {
      setPayload(payload);
    }
  }

  /// <p>returns the target id of the message.</p>
  /// @return the target id
  String? getTargetId() {
    return targetId;
  }

  /// <p>returns the source id of the message.</p>
  /// @return the id of the plugin source
  String? getSourceId() {
    return sourceId;
  }

  /// <p>Returns the type of the message.</p>
  /// @return the message type
  MessageType getType() {
    return type;
  }

  /// <p>Returns the action URL of the message.</p>
  /// @return the action URL
  GeigerUrl? getAction() {
    return action;
  }

  /// <p>Returns the payload as array of bytes.</p>
  /// @return a byte array representing the payload
  List<int>? getPayload() {
    var pl = payloadString;
    if (pl == null) {
      return null;
    }
    return base64.decode(pl);
  }

  /// <p>sets payload as byte array.</p>
  /// @param payload the payload to be set
  void setPayload(List<int>? payload) {
    payloadString = (payload == null) ? null : base64.encode(payload);
  }

  /// <p>Returns the payload as a string.</p>
  /// @return a string representing the payload
  String? getPayloadString() {
    return payloadString;
  }

  /// <p>Sets the payload as a string.</p>
  /// @param value the string to be used as payload
  /// @return a string representing the payload
  String? setPayloadString(String value) {
    var ret = payloadString;
    payloadString = value;
    return ret;
  }

  /* /// <p>Convert ByteArrayInputStream to Message.</p>
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
