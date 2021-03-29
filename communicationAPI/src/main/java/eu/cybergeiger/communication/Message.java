package eu.cybergeiger.communication;

import java.io.Serializable;
import java.nio.charset.StandardCharsets;

/**
 * <p>Representation of a message.</p>
 */
public class Message implements Serializable {

  private static final long serialVersionUID = 143287432L;

  private String sourceId;
  private String targetId;
  private MessageType type;
  private GeigerUrl action;
  private String payload = "";

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
    this.payload = new String(payload, StandardCharsets.UTF_8);
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
    return getPayloadString().getBytes(StandardCharsets.UTF_8);
  }

  /**
   * <p>Returns the payload as a string.</p>
   *
   * @return a string representing the payload
   */
  public String getPayloadString() {
    return payload;
  }

}
