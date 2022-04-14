library geiger_api;

import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_api/src/utils/communication_serializer.dart';
import 'package:geiger_api/src/utils/hash.dart';
import 'package:geiger_api/src/utils/storable_hash.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

class SecuredMessage extends Message {
  static const int serialVersionUID = 143287432;
  StorableHash? hash;

  SecuredMessage(String sourceId, String? targetId, MessageType type, GeigerUrl? action, 
  [List<int>? payload, String? requestId]) : super(sourceId, targetId, type, action, payload, requestId);

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
  static Future<SecuredMessage> fromByteArray(ByteStream in_) async{
     SerializerHelper.castTest(
        'Message', serialVersionUID, await SerializerHelper.readLong(in_), 1);
    SecuredMessage m = SecuredMessage(
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
        StorableHash? hash_ = await readObject(in_) as StorableHash;
        m.hash = hash_;
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