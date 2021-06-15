package eu.cybergeiger.communication;

import static org.junit.Assert.fail;

import ch.fhnw.geiger.localstorage.StorageController;
import ch.fhnw.geiger.localstorage.db.GenericController;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import org.junit.Assert;
import org.junit.Ignore;
import org.junit.Test;

/**
 * <p>Testing API calling sequence.</p>
 */
public class TestApiCallSequences {

  @Test
  public void testRegisterPlugin() throws Exception, DeclarationMismatchException {
    LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER,
        Declaration.DO_NOT_SHARE_DATA);
    GeigerUrl testUrl = new GeigerUrl("geiger://" + LocalApi.MASTER + "/test");
    PluginInformation payload = new PluginInformation("./plugin1", 5555,
        new CommunicationSecret());
    Message request = new Message(LocalApi.MASTER, LocalApi.MASTER, MessageType.REGISTER_PLUGIN,
        testUrl, payload.toByteArray());
    Message reply = CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) -> msg.getType() == MessageType.COMAPI_SUCCESS
    );
    Assert.assertEquals("checking message type", MessageType.COMAPI_SUCCESS,
        reply.getType());
    Assert.assertEquals("checking recipient of reply", request.getSourceId(),
        reply.getTargetId());
    Assert.assertEquals("checking sender of reply", request.getTargetId(),
        reply.getSourceId());
    Assert.assertEquals("checking geigerURL", "registerPlugin",
        reply.getAction().getPath());
  }

  @Test
  public void testDeregisterPlugin() throws Exception, DeclarationMismatchException {
    LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER,
        Declaration.DO_NOT_SHARE_DATA);
    GeigerUrl testUrl = new GeigerUrl("geiger://" + LocalApi.MASTER + "/test");
    Message request = new Message(LocalApi.MASTER, LocalApi.MASTER, MessageType.DEREGISTER_PLUGIN,
        testUrl);
    Message reply = CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) -> msg.getType() == MessageType.COMAPI_SUCCESS
            && msg.getAction().getPath().equals("deregisterPlugin")
    );
    Assert.assertEquals("checking message type", MessageType.COMAPI_SUCCESS,
        reply.getType());
    Assert.assertEquals("checking recipient of reply", request.getSourceId(),
        reply.getTargetId());
    Assert.assertEquals("checking sender of reply", request.getTargetId(),
        reply.getSourceId());
    Assert.assertEquals("checking geigerURL", "deregisterPlugin",
        reply.getAction().getPath());
  }

  @Test
  public void testActivatePlugin() throws Exception, DeclarationMismatchException {
    LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER,
        Declaration.DO_NOT_SHARE_DATA);
    GeigerUrl testUrl = new GeigerUrl("geiger://" + LocalApi.MASTER + "/test");
    PluginInformation payload = new PluginInformation("./plugin1", 5555,
        new CommunicationSecret());
    // Pregister plugin
    Message request = new Message(LocalApi.MASTER, LocalApi.MASTER, MessageType.REGISTER_PLUGIN,
        testUrl, payload.toByteArray());
    CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) -> msg.getType() == MessageType.COMAPI_SUCCESS
    );
    // activate plugin
    int payloadActivate = 5555;
    Message requestActivate = new Message(LocalApi.MASTER, LocalApi.MASTER,
        MessageType.ACTIVATE_PLUGIN, testUrl, GeigerCommunicator.intToByteArray(payloadActivate));
    Message replyActivate = CommunicationHelper.sendAndWait(localMaster, requestActivate,
        (Message msg) -> msg.getType() == MessageType.COMAPI_SUCCESS
    );
    Assert.assertEquals("checking message type", MessageType.COMAPI_SUCCESS,
        replyActivate.getType());
    Assert.assertEquals("checking recipient of reply", request.getSourceId(),
        replyActivate.getTargetId());
    Assert.assertEquals("checking sender of reply", request.getTargetId(),
        replyActivate.getSourceId());
    Assert.assertEquals("checking geigerURL", "activatePlugin",
        replyActivate.getAction().getPath());
  }

  @Test
  public void testDeactivatePlugin() throws Exception, DeclarationMismatchException {
    LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER,
        Declaration.DO_NOT_SHARE_DATA);
    GeigerUrl testUrl = new GeigerUrl("geiger://" + LocalApi.MASTER + "/test");
    PluginInformation payload = new PluginInformation("./plugin1", 5555,
        new CommunicationSecret());
    // Pregister plugin
    Message request = new Message(LocalApi.MASTER, LocalApi.MASTER, MessageType.REGISTER_PLUGIN,
        testUrl, payload.toByteArray());
    CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) -> msg.getType() == MessageType.COMAPI_SUCCESS
    );
    // activate plugin
    int payloadActivate = 5555;
    Message requestActivate = new Message(LocalApi.MASTER, LocalApi.MASTER,
        MessageType.ACTIVATE_PLUGIN, testUrl, GeigerCommunicator.intToByteArray(payloadActivate));
    Message replyActivate = CommunicationHelper.sendAndWait(localMaster, requestActivate,
        (Message msg) -> msg.getType() == MessageType.COMAPI_SUCCESS
    );
    // deactivate Plugin
    Message requestDeactivate = new Message(LocalApi.MASTER, LocalApi.MASTER,
        MessageType.DEACTIVATE_PLUGIN, testUrl);
    Message replyDeactivate = CommunicationHelper.sendAndWait(localMaster, requestDeactivate,
        (Message msg) -> msg.getType() == MessageType.COMAPI_SUCCESS
    );
    Assert.assertEquals("checking message type", MessageType.COMAPI_SUCCESS,
        replyDeactivate.getType());
    Assert.assertEquals("checking recipient of reply", request.getSourceId(),
        replyDeactivate.getTargetId());
    Assert.assertEquals("checking sender of reply", request.getTargetId(),
        replyDeactivate.getSourceId());
    Assert.assertEquals("checking geigerURL", "deactivatePlugin",
        replyDeactivate.getAction().getPath());
  }

  @Test
  public void testGetStorage() throws DeclarationMismatchException {
    // check master
    LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER,
        Declaration.DO_NOT_SHARE_DATA);
    StorageController masterController = localMaster.getStorage();
    Assert.assertTrue(masterController instanceof GenericController);

    // check plugin
    LocalApi pluginApi = LocalApiFactory.getLocalApi("./plugin1", "plugin1",
        Declaration.DO_NOT_SHARE_DATA);
    StorageController pluginController = pluginApi.getStorage();
    Assert.assertTrue(pluginController instanceof PasstroughController);
  }

  @Test
  @Ignore
  public void testRegisterListener() throws Exception, DeclarationMismatchException {
    fail("not implemented");
  }

  @Test
  @Ignore
  public void testDeregisterListener() throws Exception, DeclarationMismatchException {
    fail("not implemented");
  }

  @Test
  @Ignore
  public void testRegisterMenu() throws Exception, DeclarationMismatchException {
    LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER,
        Declaration.DO_NOT_SHARE_DATA);
    GeigerUrl testUrl = new GeigerUrl("geiger://" + LocalApi.MASTER + "/test");
    GeigerUrl menuUrl = new GeigerUrl("geiger://plugin1/Score");
    MenuItem payload = new MenuItem("plugin1Score", menuUrl);
    Message request = new Message(LocalApi.MASTER, LocalApi.MASTER, MessageType.REGISTER_MENU,
        testUrl, payload.toByteArray());
    Message reply = CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) -> msg.getType() == MessageType.COMAPI_SUCCESS
    );

    Assert.assertEquals("checking message type", MessageType.COMAPI_SUCCESS,
        reply.getType());
    Assert.assertEquals("checking recipient of reply", request.getSourceId(),
        reply.getTargetId());
    Assert.assertEquals("checking sender of reply", request.getTargetId(),
        reply.getSourceId());
    Assert.assertEquals("checking geigerURL", "registerMenu",
        reply.getAction().getPath());
    Assert.assertEquals(1, localMaster.getMenuList().size());
    Assert.assertEquals("checking stored menuItem", payload,
        localMaster.getMenuList().get(0));
  }

  @Test
  @Ignore
  public void testDeregisterMenu() throws Exception, DeclarationMismatchException {
    LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER,
        Declaration.DO_NOT_SHARE_DATA);
    GeigerUrl testUrl = new GeigerUrl("geiger://" + LocalApi.MASTER + "/test");
    GeigerUrl menuUrl = new GeigerUrl("geiger://plugin1/Score");
    MenuItem payload = new MenuItem("plugin1Score", menuUrl);
    Message request = new Message(LocalApi.MASTER, LocalApi.MASTER, MessageType.REGISTER_MENU,
        testUrl, payload.toByteArray());
    // register a MenuItem
    Message reply = CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) -> msg.getType() == MessageType.COMAPI_SUCCESS
    );

    Message request2 = new Message(LocalApi.MASTER, LocalApi.MASTER, MessageType.DEREGISTER_MENU,
        testUrl, payload.getMenu().getBytes(StandardCharsets.UTF_8));
    Message reply2 = CommunicationHelper.sendAndWait(localMaster, request2,
        (Message msg) -> msg.getType() == MessageType.COMAPI_SUCCESS);

    Assert.assertEquals("checking message type", MessageType.COMAPI_SUCCESS,
        reply2.getType());
    Assert.assertEquals("checking recipient of reply", request.getSourceId(),
        reply2.getTargetId());
    Assert.assertEquals("checking sender of reply", request.getTargetId(),
        reply2.getSourceId());
    Assert.assertEquals("checking geigerURL", "deregisterMenu",
        reply2.getAction().getPath());
    Assert.assertEquals(0, localMaster.getMenuList().size());
  }

  @Test
  @Ignore
  public void testEnableMenu() throws Exception, DeclarationMismatchException {
    LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER,
        Declaration.DO_NOT_SHARE_DATA);
    GeigerUrl testUrl = new GeigerUrl("geiger://" + LocalApi.MASTER + "/test");
    GeigerUrl menuUrl = new GeigerUrl("geiger://plugin1/Score");
    // create a disabled menu
    MenuItem payload = new MenuItem("plugin1Score", menuUrl, false);
    Message request = new Message(LocalApi.MASTER, LocalApi.MASTER, MessageType.REGISTER_MENU,
        testUrl, payload.toByteArray());
    // register a disabled menuItem
    Message reply = CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) -> msg.getType() == MessageType.COMAPI_SUCCESS
    );

    // enable the menuItem
    Message request2 = new Message(LocalApi.MASTER, LocalApi.MASTER, MessageType.ENABLE_MENU,
        testUrl, payload.getMenu().getBytes(StandardCharsets.UTF_8));
    Message reply2 = CommunicationHelper.sendAndWait(localMaster, request2,
        (Message msg) -> msg.getType() == MessageType.COMAPI_SUCCESS);

    Assert.assertEquals("checking message type", MessageType.COMAPI_SUCCESS,
        reply2.getType());
    Assert.assertEquals("checking recipient of reply", request.getSourceId(),
        reply2.getTargetId());
    Assert.assertEquals("checking sender of reply", request.getTargetId(),
        reply2.getSourceId());
    Assert.assertEquals("checking geigerURL", "enableMenu",
        reply2.getAction().getPath());
    Assert.assertEquals(1, localMaster.getMenuList().size());
    payload.setEnabled(true);
    Assert.assertNotEquals("checking stored menuItem", payload,
        localMaster.getMenuList().get(0));
  }

  @Test
  @Ignore
  public void testDisableMenu() throws Exception, DeclarationMismatchException {
    LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER,
        Declaration.DO_NOT_SHARE_DATA);
    GeigerUrl testUrl = new GeigerUrl("geiger://" + LocalApi.MASTER + "/test");
    GeigerUrl menuUrl = new GeigerUrl("geiger://plugin1/Score");
    // create an enabled menu
    MenuItem payload = new MenuItem("plugin1Score", menuUrl, true);
    Message request = new Message(LocalApi.MASTER, LocalApi.MASTER, MessageType.REGISTER_MENU,
        testUrl, payload.toByteArray());
    // register a disabled menuItem
    Message reply = CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) -> msg.getType() == MessageType.COMAPI_SUCCESS
    );

    // enable the menuItem
    Message request2 = new Message(LocalApi.MASTER, LocalApi.MASTER, MessageType.DISABLE_MENU,
        testUrl, payload.getMenu().getBytes(StandardCharsets.UTF_8));
    Message reply2 = CommunicationHelper.sendAndWait(localMaster, request2,
        (Message msg) -> msg.getType() == MessageType.COMAPI_SUCCESS);

    Assert.assertEquals("checking message type", MessageType.COMAPI_SUCCESS,
        reply2.getType());
    Assert.assertEquals("checking recipient of reply", request.getSourceId(),
        reply2.getTargetId());
    Assert.assertEquals("checking sender of reply", request.getTargetId(),
        reply2.getSourceId());
    Assert.assertEquals("checking geigerURL", "disableMenu",
        reply2.getAction().getPath());
    Assert.assertEquals(1, localMaster.getMenuList().size());
    payload.setEnabled(false);
    Assert.assertNotEquals("checking stored menuItem", payload,
        localMaster.getMenuList().get(0));
  }

  @Test
  public void testPing() throws Exception, DeclarationMismatchException {
    LocalApi localMaster = LocalApiFactory.getLocalApi("", LocalApi.MASTER,
        Declaration.DO_NOT_SHARE_DATA);
    GeigerUrl testUrl = new GeigerUrl("geiger://" + LocalApi.MASTER + "/test");
    Message request = new Message(LocalApi.MASTER, LocalApi.MASTER, MessageType.PING, testUrl,
        "payload".getBytes(StandardCharsets.UTF_8));
    Message reply = CommunicationHelper.sendAndWait(localMaster, request,
        (Message msg) -> Arrays.equals(msg.getPayload(), request.getPayload())
            && msg.getType() == MessageType.PONG
    );
    Assert.assertEquals("comparing payloads",
        new String(request.getPayload(), StandardCharsets.UTF_8), new String(reply.getPayload(),
            StandardCharsets.UTF_8));
    Assert.assertEquals("checking message type", MessageType.PONG, reply.getType());
    Assert.assertEquals("checking recipient of reply", request.getSourceId(),
        reply.getTargetId());
    Assert.assertEquals("checking sender of reply", request.getTargetId(),
        reply.getSourceId());
  }
}
