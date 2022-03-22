package eu.cybergeiger.api;

import static org.junit.Assert.fail;

import java.net.MalformedURLException;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.UUID;

import eu.cybergeiger.api.message.GeigerUrl;
import eu.cybergeiger.api.message.Message;
import eu.cybergeiger.api.message.MessageType;
import org.junit.Assert;
import org.junit.Test;

/**
 * Class to test the Message implementation.
 */
public class TestMessage {

  @Test
  public void testConstructionGetterSetter() {
    String sourceId = "sourceId";
    String targetId = "targetId";
    MessageType messageType = MessageType.ALL_EVENTS;
    GeigerUrl url = null;
    try {
      url = new GeigerUrl("geiger://plugin/path");
    } catch (MalformedURLException e) {
      fail("MalformedURLException thrown");
      e.printStackTrace();
    }

    Message msg = new Message(sourceId, targetId, messageType, url);
    Assert.assertEquals("checking sourceId", sourceId, msg.getSourceId());
    Assert.assertEquals("checking targetId", targetId, msg.getTargetId());
    Assert.assertEquals("checking message type", messageType, msg.getType());
    Assert.assertEquals("checking GeigerUrl", url, msg.getAction());
    Assert.assertNull("checking payloadString", msg.getPayloadString());
    Assert.assertEquals("checking payload", null, msg.getPayload());

    byte[] payload = "payload".getBytes(StandardCharsets.UTF_8);
    Message msg2 = new Message(sourceId, targetId, messageType, url, payload);
    Assert.assertEquals("checking sourceId", sourceId, msg2.getSourceId());
    Assert.assertEquals("checking targetId", targetId, msg2.getTargetId());
    Assert.assertEquals("checking message type", messageType, msg2.getType());
    Assert.assertEquals("checking GeigerUrl", url, msg2.getAction());
    Assert.assertEquals("checking payloadString", Base64.getEncoder().encodeToString(payload),
        msg2.getPayloadString());
    Assert.assertArrayEquals("checking payload", payload,
        msg2.getPayload());

    byte[] payload2 = "payload2".getBytes(StandardCharsets.UTF_8);
    msg2.setPayload(payload2);
    Assert.assertArrayEquals("checker setter for payload", payload2, msg2.getPayload());

    msg2.setPayloadString("payload3");
    Assert.assertEquals("checking setter for payloadString", "payload3",
        msg2.getPayloadString());
  }

  @Test
  public void testEquals() {
    String sourceId = "sourceId";
    String targetId = "targetId";
    MessageType messageType = MessageType.ALL_EVENTS;
    GeigerUrl url = null;
    byte[] payload = "payload".getBytes(StandardCharsets.UTF_8);
    try {
      url = new GeigerUrl("geiger://plugin/path");
    } catch (MalformedURLException e) {
      fail("MalformedURLException thrown");
      e.printStackTrace();
    }

    // without payload
    Message msg = new Message(sourceId, targetId, messageType, url);
    Message msg2 = new Message(sourceId, targetId, messageType, url);
    Assert.assertEquals(msg, msg2);

    // with payload
    Message msg3 = new Message(sourceId, targetId, messageType, url, payload);
    Message msg4 = new Message(sourceId, targetId, messageType, url, payload);
    Assert.assertEquals(msg3, msg4);

    // negative tests
    // without payload
    Message msg5 = new Message(targetId, sourceId, messageType, url);
    Assert.assertNotEquals(msg, msg3);

    // with payload
    byte[] payload2 = "payload2".getBytes(StandardCharsets.UTF_8);
    Message msg6 = new Message(sourceId, targetId, messageType, url, payload2);
    Assert.assertNotEquals(msg, msg6);
  }

  @Test
  public void testHashCode() {
    String sourceId = "sourceId";
    String targetId = "targetId";
    MessageType messageType = MessageType.ALL_EVENTS;
    GeigerUrl url = null;
    byte[] payload = "payload".getBytes(StandardCharsets.UTF_8);
    try {
      url = new GeigerUrl("geiger://plugin/path");
    } catch (MalformedURLException e) {
      fail("MalformedURLException thrown");
      e.printStackTrace();
    }

    // without payload
    Message msg = new Message(sourceId, targetId, messageType, url);
    Message msg2 = new Message(sourceId, targetId, messageType, url);
    Assert.assertEquals(msg.hashCode(), msg2.hashCode());

    // with payload
    Message msg3 = new Message(sourceId, targetId, messageType, url, payload);
    Message msg4 = new Message(sourceId, targetId, messageType, url, payload);
    Assert.assertEquals(msg3.hashCode(), msg4.hashCode());

    // negative tests
    Assert.assertNotEquals(msg.hashCode(), msg3.hashCode());
    Message msg5 = new Message(targetId, sourceId, messageType, url);
    Assert.assertNotEquals(msg.hashCode(), msg5.hashCode());
  }

  @Test
  public void payloadEncodingTest() {
    Message m = new Message("src", "target", MessageType.ACTIVATE_PLUGIN,
        null, null);
    for (String pl : new String[]{
        null, "", UUID.randomUUID().toString()
    }) {
      m.setPayloadString(pl);
      Assert.assertEquals(pl, m.getPayloadString());

      byte[] blarr = pl != null ? pl.getBytes(StandardCharsets.UTF_8) : null;
      m.setPayload(blarr);
      Assert.assertArrayEquals(blarr, m.getPayload());
    }
  }

}
