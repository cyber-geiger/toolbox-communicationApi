package eu.cybergeiger.api;

import eu.cybergeiger.api.communication.CommunicationHelper;
import eu.cybergeiger.api.exceptions.DeclarationMismatchException;
import eu.cybergeiger.api.message.GeigerUrl;
import eu.cybergeiger.api.message.Message;
import eu.cybergeiger.api.message.MessageType;
import eu.cybergeiger.api.plugin.CommunicationSecret;
import eu.cybergeiger.api.plugin.Declaration;
import eu.cybergeiger.api.plugin.MenuItem;
import eu.cybergeiger.api.plugin.PluginInformation;
import eu.cybergeiger.api.storage.PassthroughController;
import eu.cybergeiger.serialization.SerializerHelper;
import eu.cybergeiger.storage.StorageController;
import eu.cybergeiger.storage.StorageException;
import org.junit.Assert;
import org.junit.Test;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

/**
 * <p>Testing API calling sequence.</p>
 */
public class TestApiCallSequences {

    @Test
    public void testRegisterPlugin() throws Exception, DeclarationMismatchException {
        PluginApi localMaster = CommunicationApiFactory.getLocalApi("", GeigerApi.MASTER_ID,
                Declaration.DO_NOT_SHARE_DATA);
        GeigerUrl testUrl = new GeigerUrl("geiger://" + GeigerApi.MASTER_ID + "/test");
        PluginInformation payload = new PluginInformation(GeigerApi.MASTER_ID, "./plugin1", 5555,
                new CommunicationSecret());
        Message request = new Message(GeigerApi.MASTER_ID, GeigerApi.MASTER_ID, MessageType.REGISTER_PLUGIN,
                testUrl, payload.toByteArray());
        Message reply = CommunicationHelper.sendAndWait(localMaster, request);
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
        PluginApi localMaster = CommunicationApiFactory.getLocalApi("", GeigerApi.MASTER_ID,
                Declaration.DO_NOT_SHARE_DATA);
        GeigerUrl testUrl = new GeigerUrl("geiger://" + GeigerApi.MASTER_ID + "/test");
        Message request = new Message(GeigerApi.MASTER_ID, GeigerApi.MASTER_ID, MessageType.DEREGISTER_PLUGIN,
                testUrl);
        Message reply = CommunicationHelper.sendAndWait(localMaster, request);
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
        PluginApi localMaster = CommunicationApiFactory.getLocalApi("", GeigerApi.MASTER_ID,
                Declaration.DO_NOT_SHARE_DATA);
        GeigerUrl testUrl = new GeigerUrl("geiger://" + GeigerApi.MASTER_ID + "/test");
        PluginInformation payload = new PluginInformation(GeigerApi.MASTER_ID, "./plugin1", 5555,
                new CommunicationSecret());
        // Pregister plugin
        Message request = new Message(GeigerApi.MASTER_ID, GeigerApi.MASTER_ID, MessageType.REGISTER_PLUGIN,
                testUrl, payload.toByteArray());
        CommunicationHelper.sendAndWait(localMaster, request);
        // activate plugin
        int payloadActivate = 5555;
        Message requestActivate = new Message(GeigerApi.MASTER_ID, GeigerApi.MASTER_ID,
                MessageType.ACTIVATE_PLUGIN, testUrl, SerializerHelper.intToByteArray(payloadActivate));
        Message replyActivate = CommunicationHelper.sendAndWait(localMaster, requestActivate);
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
        PluginApi localMaster = CommunicationApiFactory.getLocalApi("", GeigerApi.MASTER_ID,
                Declaration.DO_NOT_SHARE_DATA);
        GeigerUrl testUrl = new GeigerUrl("geiger://" + GeigerApi.MASTER_ID + "/test");
        PluginInformation payload = new PluginInformation(id, "./plugin1", 5555,
                new CommunicationSecret());
        // Pregister plugin
        Message request = new Message(GeigerApi.MASTER_ID, GeigerApi.MASTER_ID, MessageType.REGISTER_PLUGIN,
                testUrl, payload.toByteArray());
        CommunicationHelper.sendAndWait(localMaster, request);
        // activate plugin
        int payloadActivate = 5555;
        Message requestActivate = new Message(GeigerApi.MASTER_ID, GeigerApi.MASTER_ID,
                MessageType.ACTIVATE_PLUGIN, testUrl, SerializerHelper.intToByteArray(payloadActivate));
        Message replyActivate = CommunicationHelper.sendAndWait(localMaster, requestActivate);
        // deactivate Plugin
        Message requestDeactivate = new Message(GeigerApi.MASTER_ID, GeigerApi.MASTER_ID,
                MessageType.DEACTIVATE_PLUGIN, testUrl);
        Message replyDeactivate = CommunicationHelper.sendAndWait(localMaster, requestDeactivate);
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
    public void testGetStorage() throws DeclarationMismatchException, IOException {
        // check master
        PluginApi localMaster = CommunicationApiFactory.getLocalApi("", GeigerApi.MASTER_ID,
                Declaration.DO_NOT_SHARE_DATA);
        StorageController masterController = localMaster.getStorage();
        Assert.assertTrue(masterController instanceof GenericController);

        // check plugin
        PluginApi pluginApi = CommunicationApiFactory.getLocalApi("./plugin1", "plugin1",
                Declaration.DO_NOT_SHARE_DATA);
        StorageController pluginController = pluginApi.getStorage();
        Assert.assertTrue(pluginController instanceof PassthroughController);
    }

    @Test
    public void testRegisterMenu() throws Exception, DeclarationMismatchException {
        PluginApi localMaster = CommunicationApiFactory.getLocalApi("", GeigerApi.MASTER_ID,
                Declaration.DO_NOT_SHARE_DATA);
        GeigerUrl testUrl = new GeigerUrl("geiger://" + GeigerApi.MASTER_ID + "/test");
        GeigerUrl menuUrl = new GeigerUrl("geiger://plugin1/Score");
        MenuItem payload = new MenuItem("plugin1Score", menuUrl);
        Message request = new Message(GeigerApi.MASTER_ID, GeigerApi.MASTER_ID, MessageType.REGISTER_MENU,
                testUrl, payload.toByteArray());
        Message reply = CommunicationHelper.sendAndWait(localMaster, request);

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
    public void testDeregisterMenu() throws Exception, DeclarationMismatchException {
        PluginApi localMaster = CommunicationApiFactory.getLocalApi("", GeigerApi.MASTER_ID,
                Declaration.DO_NOT_SHARE_DATA);
        GeigerUrl testUrl = new GeigerUrl("geiger://" + GeigerApi.MASTER_ID + "/test");
        GeigerUrl menuUrl = new GeigerUrl("geiger://plugin1/Score");
        MenuItem payload = new MenuItem("plugin1Score", menuUrl);
        Message request = new Message(GeigerApi.MASTER_ID, GeigerApi.MASTER_ID, MessageType.REGISTER_MENU,
                testUrl, payload.toByteArray());
        // register a MenuItem
        Message reply = CommunicationHelper.sendAndWait(localMaster, request);

        Message request2 = new Message(GeigerApi.MASTER_ID, GeigerApi.MASTER_ID, MessageType.DEREGISTER_MENU,
                testUrl, payload.getMenu().getBytes(StandardCharsets.UTF_8));
        Message reply2 = CommunicationHelper.sendAndWait(localMaster, request2);

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
    public void testEnableMenu() throws Exception, DeclarationMismatchException {
        PluginApi localMaster = CommunicationApiFactory.getLocalApi("", GeigerApi.MASTER_ID,
                Declaration.DO_NOT_SHARE_DATA);
        GeigerUrl testUrl = new GeigerUrl("geiger://" + GeigerApi.MASTER_ID + "/test");
        GeigerUrl menuUrl = new GeigerUrl("geiger://plugin1/Score");
        // create a disabled menu
        MenuItem payload = new MenuItem("plugin1Score", menuUrl, false);
        Message request = new Message(GeigerApi.MASTER_ID, GeigerApi.MASTER_ID, MessageType.REGISTER_MENU,
                testUrl, payload.toByteArray());
        // register a disabled menuItem
        Message reply = CommunicationHelper.sendAndWait(localMaster, request);

        // enable the menuItem
        Message request2 = new Message(GeigerApi.MASTER_ID, GeigerApi.MASTER_ID, MessageType.ENABLE_MENU,
                testUrl, payload.getMenu().getBytes(StandardCharsets.UTF_8));
        Message reply2 = CommunicationHelper.sendAndWait(localMaster, request2);

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
    public void testDisableMenu() throws Exception, DeclarationMismatchException {
        PluginApi localMaster = CommunicationApiFactory.getLocalApi("", GeigerApi.MASTER_ID,
                Declaration.DO_NOT_SHARE_DATA);
        GeigerUrl testUrl = new GeigerUrl("geiger://" + GeigerApi.MASTER_ID + "/test");
        GeigerUrl menuUrl = new GeigerUrl("geiger://plugin1/Score");
        // create an enabled menu
        MenuItem payload = new MenuItem("plugin1Score", menuUrl, true);
        Message request = new Message(GeigerApi.MASTER_ID, GeigerApi.MASTER_ID, MessageType.REGISTER_MENU,
                testUrl, payload.toByteArray());
        // register a disabled menuItem
        Message reply = CommunicationHelper.sendAndWait(localMaster, request);

        // enable the menuItem
        Message request2 = new Message(GeigerApi.MASTER_ID, GeigerApi.MASTER_ID, MessageType.DISABLE_MENU,
                testUrl, payload.getMenu().getBytes(StandardCharsets.UTF_8));
        Message reply2 = CommunicationHelper.sendAndWait(localMaster, request2);

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
        PluginApi localMaster = CommunicationApiFactory.getLocalApi("", GeigerApi.MASTER_ID,
                Declaration.DO_NOT_SHARE_DATA);
        GeigerUrl testUrl = new GeigerUrl("geiger://" + GeigerApi.MASTER_ID + "/test");
        Message request = new Message(GeigerApi.MASTER_ID, GeigerApi.MASTER_ID, MessageType.PING, testUrl,
                "payload".getBytes(StandardCharsets.UTF_8));
        Message reply = CommunicationHelper.sendAndWait(localMaster, request, new MessageType[]{MessageType.PONG});
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
