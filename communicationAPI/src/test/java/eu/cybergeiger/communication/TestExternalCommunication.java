package eu.cybergeiger.communication;

import static org.junit.Assert.fail;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import org.junit.Assert;
import org.junit.Test;

/**
 * <p>Testing non local communication.</p>
 */
public class TestExternalCommunication {

  @Test
  public void testPing() throws Exception, DeclarationMismatchException {
    LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER, Declaration.DO_NOT_SHARE_DATA);
    GeigerUrl testUrl = new GeigerUrl("geiger://master/test");
    Message ping = new Message(LocalApi.MASTER, LocalApi.MASTER, MessageType.PING, testUrl, "payload".getBytes(StandardCharsets.UTF_8));
    Message reply = CommunicationHelper.sendAndWait(localMaster, ping,
        (Message msg) -> Arrays.equals(msg.getPayload(), ping.getPayload()) && msg.getType() == MessageType.PONG
    );
    Assert.assertEquals("comparing payloads",
        new String(ping.getPayload(),StandardCharsets.UTF_8), new String(reply.getPayload(),StandardCharsets.UTF_8));
    Assert.assertEquals("checking message type", MessageType.PONG, reply.getType());
    Assert.assertEquals("checking recipient of reply", ping.getSourceId(), reply.getTargetId());
    Assert.assertEquals("checking sender of reply", ping.getTargetId(), reply.getSourceId());
  }

  @Test
  public void testRegisterPlugin() throws Exception, DeclarationMismatchException {
    LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER, Declaration.DO_NOT_SHARE_DATA);
    GeigerUrl testUrl = new GeigerUrl("geiger://master/test");
    PluginInformation info = new PluginInformation("./plugin1", 4321);
    Message request = new Message(LocalApi.MASTER, LocalApi.MASTER, MessageType.REGISTER_PLUGIN, testUrl, info.toByteArray());
    Message reply = CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) -> msg.getType() == MessageType.COMAPI_SUCCESS);
    Assert.assertEquals("checking URl", "registerPlugin", reply.getAction().getPath());
    Assert.assertEquals("checking message type", MessageType.COMAPI_SUCCESS, reply.getType());
    Assert.assertEquals("checking recipient of reply", request.getSourceId(), reply.getTargetId());
    Assert.assertEquals("checking sender of reply", request.getTargetId(), reply.getSourceId());
  }

  @Test
  public void testRegisterExternalPlugin() {
    try {
      // create Master
      LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER, Declaration.DO_NOT_SHARE_DATA);

      // create plugin, this registers and activates the plugin automatically
      LocalApi plugin = LocalApiFactory.getLocalApi("", "plugin1", Declaration.DO_NOT_SHARE_DATA);

      // TODO how to test for registration?
    }catch(DeclarationMismatchException e) {
      fail();
    }
  }

  @Test
  public void testActivatePlugin() {
    // TODO is there an answer?
  }

  @Test
  public void testRegisterListener() {

  }

  @Test
  public void testRegisterMenu() {

  }

  @Test
  public void testEnableMenu() {

  }

  @Test
  public void testMenuPressed() {

  }

  @Test
  public void testGetMenuList() {

  }

  @Test
  public void testScanButtonPressed() {

  }


}
