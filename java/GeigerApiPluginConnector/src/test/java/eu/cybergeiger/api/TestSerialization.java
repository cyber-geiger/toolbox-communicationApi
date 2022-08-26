package eu.cybergeiger.api;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.UUID;

import eu.cybergeiger.api.message.GeigerUrl;
import eu.cybergeiger.api.message.Message;
import eu.cybergeiger.api.message.MessageType;
import eu.cybergeiger.api.plugin.CommunicationSecret;
import eu.cybergeiger.api.plugin.Declaration;
import eu.cybergeiger.api.plugin.MenuItem;
import eu.cybergeiger.api.plugin.PluginInformation;
import eu.cybergeiger.api.utils.StorableHashMap;
import eu.cybergeiger.storage.Visibility;
import eu.cybergeiger.storage.node.DefaultNode;
import eu.cybergeiger.storage.node.Node;
import eu.cybergeiger.storage.node.value.DefaultNodeValue;
import eu.cybergeiger.storage.node.value.NodeValue;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * <p>Unit testing of serializable objects.</p>
 */
public class TestSerialization {


  /**
   * <p>Tests the serialization of the GeigerUrl object.</p>
   */
  @Test
  public void geigerUrlSerializationTest() throws IOException {
    GeigerUrl p = new GeigerUrl("id", "path");
    ByteArrayOutputStream bout = new ByteArrayOutputStream();
    p.toByteArrayStream(bout);
    ByteArrayInputStream bin = new ByteArrayInputStream(bout.toByteArray());
    GeigerUrl p2 = GeigerUrl.fromByteArrayStream(bin);
    assertThat(p).isEqualTo(p2);
  }

  /**
   * <p>Tests the serialization of the MenuItem object.</p>
   */
  @Test
  public void menuItemSerializationTest() throws IOException {
    MenuItem p = new MenuItem(
      new DefaultNode(
        ":menu",
        "plugin",
        Visibility.RED,
        new NodeValue[]{
          new DefaultNodeValue(MenuItem.NAME_KEY, "test"),
          new DefaultNodeValue(MenuItem.TOOLTIP_KEY, "test")
        },
        new Node[0]
      ),
      new GeigerUrl("plugin", "menu")
    );

    ByteArrayOutputStream bout = new ByteArrayOutputStream();
    p.toByteArrayStream(bout);
    ByteArrayInputStream bin = new ByteArrayInputStream(bout.toByteArray());
    MenuItem p2 = MenuItem.fromByteArrayStream(bin);
    assertThat(p).isEqualTo(p2);
  }

  /**
   * <p>Tests the serialization of the ParameterList object.</p>
   */
  @Test
  public void pluginInformationSerializationTest() throws IOException {
    PluginInformation p = new PluginInformation("", "exec", 1234, Declaration.DO_NOT_SHARE_DATA);
    ByteArrayOutputStream bout = new ByteArrayOutputStream();
    p.toByteArrayStream(bout);
    ByteArrayInputStream bin = new ByteArrayInputStream(bout.toByteArray());
    PluginInformation p2 = PluginInformation.fromByteArrayStream(bin);
    PluginInformation p3 = PluginInformation.fromByteArray(p.toByteArray());
    assertThat(p.hashCode())
      .isEqualTo(p2.hashCode())
      .isEqualTo(p3.hashCode());
  }

  /**
   * <p>Tests the serialization of the ParameterList object.</p>
   */
  @Test
  public void communicationSecretSerializationTest() throws IOException {
    CommunicationSecret[] comsec = new CommunicationSecret[]{
      new CommunicationSecret("Hello".getBytes(StandardCharsets.UTF_8)),
      new CommunicationSecret()
    };

    for (CommunicationSecret p : comsec) {
      ByteArrayOutputStream bout = new ByteArrayOutputStream();
      p.toByteArrayStream(bout);
      ByteArrayInputStream bin = new ByteArrayInputStream(bout.toByteArray());
      CommunicationSecret p2 = CommunicationSecret.fromByteArrayStream(bin);
      assertThat(p.toString()).isEqualTo(p2.toString());
    }
  }

  /**
   * <p>Tests the serialization of the a serializable Hashmap object.</p>
   */
  @Test
  public void storableMapSerializationTest() throws IOException {
    StorableHashMap hm = new StorableHashMap();
    ByteArrayOutputStream bout = new ByteArrayOutputStream();
    hm.toByteArrayStream(bout);
    ByteArrayInputStream bin = new ByteArrayInputStream(bout.toByteArray());
    StorableHashMap hm2 = new StorableHashMap();
    StorableHashMap.fromByteArrayStream(bin, hm2);
    assertThat(hm).isEqualTo(hm2);
  }

  /**
   * <p>Tests the serialization of the a serializable Hashmap object.</p>
   */
  @Test
  public void messageSerializationTest() throws IOException {
    for (Message m : new Message[]{
      new Message("src", "target", MessageType.DEACTIVATE_PLUGIN, new GeigerUrl("geiger://id1/path1")),
      new Message("src", "target", MessageType.DEACTIVATE_PLUGIN, null),
      new Message("src", "target", MessageType.DEACTIVATE_PLUGIN, new GeigerUrl("id", "path2")),
      new Message("src", "target", MessageType.DEACTIVATE_PLUGIN, new GeigerUrl("id1", "path")),
    }) {
      ByteArrayOutputStream bout = new ByteArrayOutputStream();
      m.toByteArrayStream(bout);
      ByteArrayInputStream bin = new ByteArrayInputStream(bout.toByteArray());
      Message m2 = Message.fromByteArrayStream(bin);
      assertThat(m).isEqualTo(m2);
    }
  }
}
