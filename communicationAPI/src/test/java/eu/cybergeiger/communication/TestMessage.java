package eu.cybergeiger.communication;

import static org.junit.Assert.fail;

import eu.cybergeiger.totalcross.Base64;
import eu.cybergeiger.totalcross.MalformedUrlException;
import java.nio.charset.StandardCharsets;
import org.junit.Assert;
import org.junit.Ignore;
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
    } catch (MalformedUrlException e) {
      fail("MalformedUrlException thrown");
      e.printStackTrace();
    }

    Message msg = new Message(sourceId, targetId, messageType, url);
    Assert.assertEquals("checking sourceId", sourceId, msg.getSourceId());
    Assert.assertEquals("checking targetId", targetId, msg.getTargetId());
    Assert.assertEquals("checking message type", messageType, msg.getType());
    Assert.assertEquals("checking GeigerUrl", url, msg.getAction());
    Assert.assertEquals("checking payloadString", null, msg.getPayloadString());
    // TODO what to do in this case?
    //Assert.assertEquals("checking payload", Base64.decode(""),
    //    msg.getPayload());

    byte[] payload = "payload".getBytes(StandardCharsets.UTF_8);
    Message msg2 = new Message(sourceId, targetId, messageType, url, payload);
    Assert.assertEquals("checking sourceId", sourceId, msg2.getSourceId());
    Assert.assertEquals("checking targetId", targetId, msg2.getTargetId());
    Assert.assertEquals("checking message type", messageType, msg2.getType());
    Assert.assertEquals("checking GeigerUrl", url, msg2.getAction());
    Assert.assertEquals("checking payloadString", Base64.encodeToString(payload),
        msg2.getPayloadString());
    Assert.assertEquals("checking payload", payload,
        msg2.getPayload());

    byte[] payload2 = "payload2".getBytes(StandardCharsets.UTF_8);
    msg2.setPayload(payload2);
    Assert.assertEquals("checker setter for payload",  payload2, msg2.getPayload());

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
    } catch (MalformedUrlException e) {
      fail("MalformedUrlException thrown");
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
  @Ignore
  public void testHashCode() {
    fail("not implemented");
  }
}
