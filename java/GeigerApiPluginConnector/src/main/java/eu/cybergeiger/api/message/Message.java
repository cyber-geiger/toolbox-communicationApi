package eu.cybergeiger.api.message;

import eu.cybergeiger.api.plugin.CommunicationSecret;
import eu.cybergeiger.api.utils.Hash;
import eu.cybergeiger.api.utils.HashType;
import eu.cybergeiger.serialization.Serializable;
import eu.cybergeiger.serialization.SerializerHelper;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Objects;
import java.util.UUID;

/**
 * <p>Representation of a message.</p>
 */
public class Message implements Serializable {
  private static final HashType HASH_TYPE = HashType.SHA512;

  private static final long serialVersionUID = 143287432L;

  private final String sourceId;
  private final String targetId;
  private final MessageType type;
  private final String requestId;
  private final GeigerUrl action;
  private Hash hash;
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
    this(sourceId, targetId, type, action, null, null);
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
    this(sourceId, targetId, type, action, null, requestId);
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
    this(sourceId, targetId, type, action, payload, null);
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
    this.sourceId = sourceId;
    this.targetId = targetId;
    this.type = type;
    this.requestId = requestId == null ? UUID.randomUUID().toString() : requestId;
    this.action = action;
    if (payload != null)
      setPayload(payload);
    hash = integrityHash(new CommunicationSecret());
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

  public Hash getHash() {
    return hash;
  }

  public boolean isHashValid(CommunicationSecret secret) {
    return integrityHash(secret).equals(hash);
  }

  private Hash integrityHash(CommunicationSecret secret) {
    ByteArrayOutputStream out = new ByteArrayOutputStream();
    try {
      out.write(
        (sourceId +
          (targetId == null ? "null" : targetId) +
          type.getId() +
          (action == null ? "null" : action.toString()) +
          requestId)
          .getBytes(StandardCharsets.UTF_8)
      );
      out.write(getPayload());
      out.write(secret.getBytes());
    } catch (IOException e) {
      throw new RuntimeException("Got unexpected IO exception.", e);
    }
    return HASH_TYPE.digest(out.toByteArray());
  }

  /**
   * <p>Returns the payload as array of bytes.</p>
   *
   * @return a byte array representing the payload
   */
  public byte[] getPayload() {
    return payloadString == null ? new byte[0] :
      Base64.getDecoder().decode(payloadString);
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
  public void toByteArrayStream(OutputStream out) throws IOException {
    toByteArrayStream(out, null);
  }

  public void toByteArrayStream(OutputStream out, CommunicationSecret secret) throws IOException {
    SerializerHelper.writeMarker(out, serialVersionUID);
    SerializerHelper.writeString(out, sourceId);
    SerializerHelper.writeString(out, targetId);
    SerializerHelper.writeInt(out, type.getId());
    if (action == null) {
      SerializerHelper.writeInt(out, 0);
    } else {
      SerializerHelper.writeInt(out, 1);
      action.toByteArrayStream(out);
    }
    SerializerHelper.writeString(out, requestId);
    SerializerHelper.writeString(out, payloadString);
    integrityHash(secret == null ? new CommunicationSecret() : secret).toByteArrayStream(out);
    SerializerHelper.writeMarker(out, serialVersionUID);
  }

  /**
   * <p>Convert InputStream to Message.</p>
   *
   * @param in the InputStream to use
   * @return the converted Message
   * @throws IOException if bytes cannot be read
   */
  public static Message fromByteArrayStream(InputStream in) throws IOException {
    SerializerHelper.testMarker(in, serialVersionUID);
    Message m = new Message(
      SerializerHelper.readString(in),
      SerializerHelper.readString(in),
      Objects.requireNonNull(MessageType.getById(SerializerHelper.readInt(in))),
      SerializerHelper.readInt(in) == 1 ? GeigerUrl.fromByteArrayStream(in) : null,
      SerializerHelper.readString(in)
    );
    m.setPayloadString(SerializerHelper.readString(in));
    m.hash = Hash.fromByteArrayStream(in);
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
      && Objects.equals(hash, message.hash)
      && Objects.equals(payloadString, message.payloadString);
  }

  @Override
  public int hashCode() {
    return Objects.hash(sourceId, targetId, type, action, hash, payloadString);
  }

  @Override
  public String toString() {
    return getSourceId() + "=" + requestId + ">" + getTargetId() + "" +
      "{[" + getType() + "] (" + (getAction() == null ? "" : getAction()) + ")" +
      (hash == null ? "" : "[" + hash.getType() + ": " + hash + "]")
      + "}";
  }
}
