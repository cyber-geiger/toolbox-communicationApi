package eu.cybergeiger.api.message;

import eu.cybergeiger.serialization.Serializable;
import eu.cybergeiger.serialization.SerializerHelper;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.Base64;
import java.util.Objects;
import java.util.UUID;

/**
 * <p>Representation of a message.</p>
 */
public class Message implements Serializable {
  private static final long serialVersionUID = 143287432L;

  private final String sourceId;
  private final String targetId;
  private final MessageType type;
  private final String requestId;
  private final GeigerUrl action;
  private String payloadString = null;

  /**
   * <p>A message object transported through the local communication api.</p>
   *
   * @param sourceId the id of the source plugin
   * @param targetId the id of the target plugin
   * @param type     the type of message
   * @param action   the url of the event
   */
  public Message(String sourceId, String targetId, MessageType type, GeigerUrl action) {
    this(sourceId, targetId, type, action, UUID.randomUUID().toString());
  }

  /**
   * <p>A message object transported through the local communication api.</p>
   *
   * @param sourceId  the id of the source plugin
   * @param targetId  the id of the target plugin
   * @param type      the type of message
   * @param requestId Unique ID of the request shared by the request message and the confirmation message.
   * @param action    the url of the event
   */
  public Message(String sourceId, String targetId, MessageType type, GeigerUrl action, String requestId) {
    this.sourceId = sourceId;
    this.targetId = targetId;
    this.type = type;
    this.requestId = requestId;
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
   * <p>A message object transported through the local communication api.</p>
   *
   * @param sourceId  the id of the source plugin
   * @param targetId  the id of the target plugin
   * @param type      the type of message
   * @param action    the url of the event
   * @param payload   the payload section of the message
   * @param requestId Unique ID of the request shared by the request message and the confirmation message.
   */
  public Message(String sourceId, String targetId, MessageType type, GeigerUrl action,
                 byte[] payload, String requestId) {
    this(sourceId, targetId, type, action, requestId);
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
   * Unique ID of the request shared by the request message and the confirmation message.
   */
  public String getRequestId() {
    return requestId;
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
    if (payloadString == null) {
      return null;
    }
    return Base64.getDecoder().decode(payloadString);
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
   * @param value the string to be used as payload
   */
  public void setPayloadString(String value) {
    this.payloadString = value;
  }

  @Override
  public void toByteArrayStream(ByteArrayOutputStream out) throws IOException {
    SerializerHelper.writeMarker(out, serialVersionUID);
    SerializerHelper.writeString(out, sourceId);
    if (targetId != null) {
      SerializerHelper.writeInt(out, 1);
      SerializerHelper.writeString(out, targetId);
    } else {
      SerializerHelper.writeInt(out, 0);
    }
    SerializerHelper.writeInt(out, type.getId());
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
    SerializerHelper.writeMarker(out, serialVersionUID);
  }

  /**
   * <p>Convert ByteArrayInputStream to Message.</p>
   *
   * @param in the ByteArrayInputStream to use
   * @return the converted Message
   * @throws IOException if bytes cannot be read
   */
  public static Message fromByteArrayStream(ByteArrayInputStream in) throws IOException {
    SerializerHelper.testMarker(in, serialVersionUID);
    Message m = new Message(
      SerializerHelper.readString(in),
      SerializerHelper.readInt(in) == 1 ? SerializerHelper.readString(in) : null,
      MessageType.getById(SerializerHelper.readInt(in)),
      SerializerHelper.readInt(in) == 1 ? GeigerUrl.fromByteArrayStream(in) : null
    );
    m.setPayloadString(SerializerHelper.readInt(in) == 1 ? SerializerHelper.readString(in) : null);
    SerializerHelper.testMarker(in, serialVersionUID);
    return m;
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
      && type == message.type
      && Objects.equals(action, message.action)
      && Objects.equals(requestId, message.requestId)
      && Objects.equals(payloadString, message.payloadString);
  }

  @Override
  public int hashCode() {
    return Objects.hash(sourceId, targetId, type, action, payloadString);
  }

  @Override
  public String toString() {
    return getSourceId() + "=" + requestId + ">" + getTargetId() + "{[" + getType() + "] " + getAction() + "}";
  }
}
