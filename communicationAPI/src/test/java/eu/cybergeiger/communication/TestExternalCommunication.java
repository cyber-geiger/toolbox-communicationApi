package eu.cybergeiger.communication;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import org.junit.Assert;
import org.junit.Test;

import static org.junit.Assert.fail;

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
    Assert.assertEquals("comparing payloads", ping.getPayload(), reply.getPayload());
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
    // TODO fix infinite loop
    Assert.assertEquals("checking URl", "registerPlugin", reply.getAction().getPath());
    Assert.assertEquals("checking message type", MessageType.COMAPI_SUCCESS, reply.getType());
    Assert.assertEquals("checking recipient of reply", request.getSourceId(), reply.getTargetId());
    Assert.assertEquals("checking sender of reply", request.getTargetId(), reply.getSourceId());
  }

  @Test
  public void testRegisterExternalPlugin() throws Exception, DeclarationMismatchException {
    // create Master
    LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER, Declaration.DO_NOT_SHARE_DATA);

    // create plugin, this registers and activates the plugin automatically
    LocalApi plugin = LocalApiFactory.getLocalApi("", "plugin1", Declaration.DO_NOT_SHARE_DATA);

    // TODO how to test for registration?
  }

  @Test
  public void testActivatePlugin() {
    // TODO is there an answer?
    fail("not implemented");
  }

  @Test
  public void testRegisterListener() {
    fail("not implemented");
  }

  @Test
  public void testRegisterMenu() {
    fail("not implemented");
  }

  @Test
  public void testEnableMenu() {
    fail("not implemented");
  }

  @Test
  public void testMenuPressed() {
    fail("not implemented");
  }

  @Test
  public void testGetMenuList() {
    fail("not implemented");
  }

  @Test
  public void testScanButtonPressed() {
    fail("not implemented");
  }


}
