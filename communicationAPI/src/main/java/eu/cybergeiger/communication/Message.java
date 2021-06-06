package eu.cybergeiger.communication;

import ch.fhnw.geiger.serialization.Serializer;
import ch.fhnw.geiger.serialization.SerializerHelper;
import ch.fhnw.geiger.totalcross.ByteArrayInputStream;
import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Objects;

/**
 * <p>Representation of a message.</p>
 */
public class Message implements Serializer {

  private static final long serialVersionUID = 143287432L;

  private String sourceId;
  private String targetId;
  private MessageType type;
  private GeigerUrl action;
  private String payloadString = "";

  /**
   * <p>A message object transported through the local communication api.</p>
   *
   * @param sourceId the id of the source plugin
   * @param targetId the id of the target plugin
   * @param type     the type of message
   * @param action   the url of the event
   */
  public Message(String sourceId, String targetId, MessageType type, GeigerUrl action) {
    this.sourceId = sourceId;
    this.targetId = targetId;
    this.type = type;
    this.action = action;
  }

  /**
   * <p>A message object transported through the local communication api.</p>
   *
   * @param sourceId the id of the source plugin
   * @param targetId the id of the target plugin
   * @param type     the type of message
   * @param action   the url of the event
   * @param payload  the payload section of the message
   */
  public Message(String sourceId, String targetId, MessageType type, GeigerUrl action,
                 byte[] payload) {
    this(sourceId, targetId, type, action);
    setPayload(payload);
  }

  /**
   * <p>returns the target id of the message.</p>
   *
   * @return the target id
   */
  public String getTargetId() {
    return this.targetId;
  }

  /**
   * <p>returns the source id of the message.</p>
   *
   * @return the id of the plugin source
   */
  public String getSourceId() {
    return this.sourceId;
  }

  /**
   * <p>Returns the type of the message.</p>
   *
   * @return the message type
   */
  public MessageType getType() {
    return this.type;
  }

  /**
   * <p>Returns the action URL of the message.</p>
   *
   * @return the action URL
   */
  public GeigerUrl getAction() {
    return this.action;
  }

  /**
   * <p>Returns the payload as array of bytes.</p>
   *
   * @return a byte array representing the payload
   */
  public byte[] getPayload() {
    String pl = this.payloadString;
    if (pl == null) {
      return null;
    }
    return Base64.getDecoder().decode(pl);
  }

  /**
   * <p>sets payload as byte array.</p>
   *
   * @param payload the payload to be set
   */
  public void setPayload(byte[] payload) {
    this.payloadString = payload == null ? null : Base64.getEncoder().encodeToString(payload);
  }


  /**
   * <p>Returns the payload as a string.</p>
   *
   * @return a string representing the payload
   */
  public String getPayloadString() {
    return this.payloadString;
  }

  /**
   * <p>Sets the payload as a string.</p>
   *
   * @return a string representing the payload
   */
  public String setPayloadString(String value) {
    String ret = this.payloadString;
    this.payloadString = value;
    return ret;
  }

  /**
   * <p>Convert ByteArrayInputStream to Message.</p>
   *
   * @param in the ByteArrayInputStream to use
   * @return the converted Message
   * @throws IOException if bytes cannot be read
   */
  public static Message fromByteArray(ByteArrayInputStream in) throws IOException {
    if (SerializerHelper.readLong(in) != serialVersionUID) {
      throw new ClassCastException();
    }
    Message m =  new Message(SerializerHelper.readInt(in) == 1
        ? SerializerHelper.readString(in) : null,
        SerializerHelper.readInt(in) == 1 ? SerializerHelper.readString(in) : null,
        SerializerHelper.readInt(in) == 1
            ? MessageType.getById(SerializerHelper.readInt(in)) : null,
        SerializerHelper.readInt(in) == 1 ? GeigerUrl.fromByteArrayStream(in) : null
    );
    m.setPayloadString(SerializerHelper.readInt(in) == 1 ? SerializerHelper.readString(in) : null);
    return m;
  }

  @Override
  public void toByteArrayStream(ByteArrayOutputStream out) throws IOException {
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
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    }
    if (o == null || getClass() != o.getClass()) {
      return false;
    }
    Message message = (Message) o;
    return Objects.equals(sourceId, message.sourceId)
        && Objects.equals(targetId, message.targetId)
        && type == message.type && Objects.equals(action, message.action)
        && Objects.equals(payloadString, message.payloadString);
  }

  @Override
  public int hashCode() {
    return Objects.hash(sourceId, targetId, type, action, payloadString);
  }
}
