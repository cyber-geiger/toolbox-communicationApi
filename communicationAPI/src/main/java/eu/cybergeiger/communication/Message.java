package eu.cybergeiger.communication;

import ch.fhnw.geiger.serialization.Serializer;
import ch.fhnw.geiger.serialization.SerializerHelper;
import ch.fhnw.geiger.totalcross.ByteArrayInputStream;
import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

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
    this.payloadString =  Base64.getEncoder().encodeToString(payload);
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
    return Base64.getDecoder().decode(getPayloadString());
  }

  /**
   * <p>Returns the payload as a string.</p>
   *
   * @return a string representing the payload
   */
  public String getPayloadString() {
    return payloadString;
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
    return new Message(SerializerHelper.readString(in),
        SerializerHelper.readString(in),
        MessageType.getById(SerializerHelper.readInt(in)),
        GeigerUrl.fromByteArrayStream(in),
        SerializerHelper.readInt(in)==1?SerializerHelper.readString(in).getBytes(StandardCharsets.UTF_8):null);
  }

  @Override
  public void toByteArrayStream(ByteArrayOutputStream out) throws IOException {
    SerializerHelper.writeLong(out, serialVersionUID);
    SerializerHelper.writeString(out, sourceId);
    SerializerHelper.writeString(out, targetId);
    SerializerHelper.writeInt(out, type.getId());
    if(action==null) {
      SerializerHelper.writeInt(out, 0);
    } else {
      SerializerHelper.writeInt(out, 1);
      action.toByteArrayStream(out);
    }
    SerializerHelper.writeString(out, payloadString);
  }
}
