package eu.cybergeiger.communication;

import java.io.Serializable;
import java.net.URL;
import java.nio.charset.StandardCharsets;

public class Message implements Serializable {

  private static final long serialVersionUID = 143287432L;

  private String sourceId;
  private String targetId;
  private URL action;
  private String payload = "";

  public Message(String sourceId, String targetId, URL action) {
    this.sourceId = sourceId;
    this.targetId = targetId;
    this.action = action;
  }

  public Message(String sourceId, String targetId, URL action, byte[] payload) {
    this(sourceId, targetId, action);
    this.payload = new String(payload, StandardCharsets.UTF_8);
  }

  String getTargetId() {
    return this.targetId;
  }

  String getSourceId() {
    return this.sourceId;
  }

  URL getAction() {
    return this.action;
  }

  public byte[] getPayload() {
    return payload.getBytes(StandardCharsets.UTF_8);
  }

}
