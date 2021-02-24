package eu.cybergeiger.communication;

import java.io.Serializable;
import java.nio.charset.StandardCharsets;

public class Message implements Serializable {

  private static final long serialVersionUID = 143287432L;

  private String sourceId;
  private String targetId;
  private MessageType type;
  private GeigerURL action;
  private String payload = "";

  public Message(String sourceId, String targetId, MessageType type, GeigerURL action) {
    this.sourceId = sourceId;
    this.targetId = targetId;
    this.type = type;
    this.action = action;
  }

  public Message(String sourceId, String targetId, MessageType type, GeigerURL action, byte[] payload) {
    this(sourceId, targetId, type, action);
    this.payload = new String(payload, StandardCharsets.UTF_8);
  }

  public String getTargetId() {
    return this.targetId;
  }

  public String getSourceId() {
    return this.sourceId;
  }

  public MessageType getType() {
    return this.type;
  }

  public GeigerURL getAction() {
    return this.action;
  }

  public byte[] getPayload() {
    return payload.getBytes(StandardCharsets.UTF_8);
  }

}
