package eu.cybergeiger.communication;

import java.nio.charset.StandardCharsets;
import java.util.UUID;
import org.junit.Assert;
import org.junit.Test;

/**
 * Class to test the Message class.
 */
public class MessageTest {

  @Test
  public void payloadEncodingTest() {
    Message m = new Message("src", "target", MessageType.ACTIVATE_PLUGIN,
        null, null);
    for (String pl : new String[] {
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
