package eu.cybergeiger.communication;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import org.junit.Assert;
import org.junit.Test;

/**
 * <p>Testing non local communication.</p>
 */
public class TestExternalCommunication {

  @Test
  public void testRegisterPlugin() throws Exception, DeclarationMismatchException {
    LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER, Declaration.DO_NOT_SHARE_DATA);
    GeigerUrl testUrl = new GeigerUrl("geiger://master/test");
    Message ping = new Message(LocalApi.MASTER, LocalApi.MASTER, MessageType.PING, testUrl, "payload".getBytes(StandardCharsets.UTF_8));
    Message reply = CommunicationHelper.sendAndWait(localMaster, ping,
        (Message msg) -> Arrays.equals(msg.getPayload(), ping.getPayload()) && msg.getType() == MessageType.PONG
    );
    Assert.assertEquals("comparing payloads", ping.getPayload(), reply.getPayload());
    Assert.assertEquals("checking message type", MessageType.PONG, reply.getType());
    Assert.assertEquals("checking recipient of reply", ping.getSourceId(), reply.getTargetId());
    Assert.assertEquals("checking sender of reply", ping.getTargetId(), reply.getSourceId());
  }
}
