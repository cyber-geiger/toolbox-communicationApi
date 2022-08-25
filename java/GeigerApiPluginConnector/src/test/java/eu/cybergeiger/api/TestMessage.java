package eu.cybergeiger.api;


import eu.cybergeiger.api.message.GeigerUrl;
import eu.cybergeiger.api.message.Message;
import eu.cybergeiger.api.message.MessageType;
import org.junit.jupiter.api.Test;

import java.net.MalformedURLException;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Class to test the Message implementation.
 */
public class TestMessage {
  @Test
  public void testConstructionGetterSetter() throws MalformedURLException {
    String sourceId = "sourceId";
    String targetId = "targetId";
    MessageType messageType = MessageType.ALL_EVENTS;
    GeigerUrl url = GeigerUrl.parse("geiger://plugin/path");

    Message msg = new Message(sourceId, targetId, messageType, url);
    assertThat(sourceId).isEqualTo(msg.getSourceId());
    assertThat(targetId).isEqualTo(msg.getTargetId());
    assertThat(messageType).isEqualTo(msg.getType());
    assertThat(url).isEqualTo(msg.getAction());
    assertThat(msg.getPayloadString()).isEmpty();
    assertThat(msg.getPayload()).isEmpty();

    byte[] payload = "payload".getBytes(StandardCharsets.UTF_8);
    Message msg2 = new Message(sourceId, targetId, messageType, url, payload);
    assertThat(msg2.getSourceId()).isEqualTo(sourceId);
    assertThat(msg2.getTargetId()).isEqualTo(targetId);
    assertThat(msg2.getType()).isEqualTo(messageType);
    assertThat(msg2.getAction()).isEqualTo(url);
    assertThat(msg2.getPayloadString()).isEqualTo(Base64.getEncoder().encodeToString(payload));
    assertThat(payload).containsExactly(msg2.getPayload());

    byte[] payload2 = "payload2".getBytes(StandardCharsets.UTF_8);
    msg2.setPayload(payload2);
    assertThat(payload2).containsExactly(msg2.getPayload());

    msg2.setPayloadString("payload3");
    assertThat(msg2.getPayloadString()).isEqualTo("payload3").as("checking setter for payloadString");
  }

  @Test
  public void testEquals() throws MalformedURLException {
    String sourceId = "sourceId";
    String targetId = "targetId";
    String requestId = "some-id";
    MessageType messageType = MessageType.ALL_EVENTS;
    GeigerUrl url = GeigerUrl.parse("geiger://plugin/path");
    byte[] payload = "payload".getBytes(StandardCharsets.UTF_8);

    // without payload
    Message msg = new Message(sourceId, targetId, messageType, url, requestId);
    Message msg2 = new Message(sourceId, targetId, messageType, url, requestId);
    assertThat(msg2).isEqualTo(msg);

    // with payload
    Message msg3 = new Message(sourceId, targetId, messageType, url, payload, requestId);
    Message msg4 = new Message(sourceId, targetId, messageType, url, payload, requestId);
    assertThat(msg4).isEqualTo(msg3);

    // negative tests
    // without payload
    assertThat(msg3).isNotEqualTo(msg);
  }

  @Test
  public void testHashCode() throws MalformedURLException {
    String sourceId = "sourceId";
    String targetId = "targetId";
    MessageType messageType = MessageType.ALL_EVENTS;
    GeigerUrl url = GeigerUrl.parse("geiger://plugin/path");
    byte[] payload = "payload".getBytes(StandardCharsets.UTF_8);

    // without payload
    Message msg = new Message(sourceId, targetId, messageType, url);
    Message msg2 = new Message(sourceId, targetId, messageType, url);
    assertThat(msg2.hashCode()).isEqualTo(msg.hashCode());

    // with payload
    Message msg3 = new Message(sourceId, targetId, messageType, url, payload);
    Message msg4 = new Message(sourceId, targetId, messageType, url, payload);
    assertThat(msg4.hashCode()).isEqualTo(msg3.hashCode());

    // negative tests
    assertThat(msg3.hashCode()).isNotEqualTo(msg.hashCode());
    Message msg5 = new Message(targetId, sourceId, messageType, url);
    assertThat(msg5.hashCode()).isNotEqualTo(msg.hashCode());
  }

  @Test
  public void payloadEncodingTest() {
    Message m = new Message("src", "target", MessageType.ACTIVATE_PLUGIN, null);
    for (String pl : new String[]{
      null, "", UUID.randomUUID().toString()
    }) {
      m.setPayloadString(pl);
      assertThat(m.getPayloadString()).isEqualTo(pl);

      byte[] blarr = pl != null ? pl.getBytes(StandardCharsets.UTF_8) : null;
      m.setPayload(blarr);
      assertThat(blarr == null ? new byte[0] : blarr).containsExactly(m.getPayload());
    }
  }
}
