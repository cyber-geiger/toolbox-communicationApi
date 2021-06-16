package eu.cybergeiger.communication;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;

import ch.fhnw.geiger.totalcross.ByteArrayInputStream;
import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import org.junit.Test;

/**
 * <p>Unit testing of serializable objects.</p>
 */
public class TestSerialization {

  /**
   * <p>Tests the serialization of the ParameterList object.</p>
   */
  @Test
  public void parameterListSerializationTest() throws IOException {
    ParameterList p = new ParameterList("test", null, "Test", "null");

    ByteArrayOutputStream bout = new ByteArrayOutputStream();
    p.toByteArrayStream(bout);
    ByteArrayInputStream bin = new ByteArrayInputStream(bout.toByteArray());
    ParameterList p2 = ParameterList.fromByteArrayStream(bin);
    assertEquals("Cloned ParameterLists are not equal", p.toString(), p2.toString());

  }

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
    assertEquals("Cloned MenuItems are not equal", p.toString(), p2.toString());

  }

  /**
   * <p>Tests the serialization of the MenuItem object.</p>
   */
  @Test
  public void menuItemSerializationTest() throws IOException {
    MenuItem p = new MenuItem("test", new GeigerUrl("Test", "action"), false);

    ByteArrayOutputStream bout = new ByteArrayOutputStream();
    p.toByteArrayStream(bout);
    ByteArrayInputStream bin = new ByteArrayInputStream(bout.toByteArray());
    MenuItem p2 = MenuItem.fromByteArrayStream(bin);
    assertEquals("Cloned MenuItems are not equal", p.toString(), p2.toString());

  }

  /**
   * <p>Tests the serialization of the ParameterList object.</p>
   */
  @Test
  public void pluginInformationSerializationTest() throws IOException {
    PluginInformation p = new PluginInformation("exec", 1234);
    ByteArrayOutputStream bout = new ByteArrayOutputStream();
    p.toByteArrayStream(bout);
    ByteArrayInputStream bin = new ByteArrayInputStream(bout.toByteArray());
    PluginInformation p2 = PluginInformation.fromByteArrayStream(bin);
    PluginInformation p3 = PluginInformation.fromByteArray(p.toByteArray());
    assertNotNull(p);
    assertNotNull("deserialized object (stream) is null", p2);
    assertNotNull("deserialized object (array) is null", p3);
    assertEquals("Cloned Plugininformation using stream are not equal",
        p.hashCode(), p2.hashCode());
    assertEquals("Cloned Plugininformation using array are not equal",
        p.hashCode(), p3.hashCode());

  }

  /**
   * <p>Tests the serialization of the ParameterList object.</p>
   */
  @Test
  public void communicationSecretSerializationTest() throws IOException {
    CommunicationSecret[] comsec = new CommunicationSecret[]{
        new CommunicationSecret("Hello".getBytes(StandardCharsets.UTF_8)),
        new CommunicationSecret(),
        new CommunicationSecret(1024)
      };

    for (CommunicationSecret p : comsec) {
      ByteArrayOutputStream bout = new ByteArrayOutputStream();
      p.toByteArrayStream(bout);
      ByteArrayInputStream bin = new ByteArrayInputStream(bout.toByteArray());
      CommunicationSecret p2 = CommunicationSecret.fromByteArrayStream(bin);
      assertNotNull(p);
      assertNotNull("deserialized object (stream) is null", p2);
      assertEquals("Cloned Plugininformation using stream are not equal",
          p.toString(), p2.toString());
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
    assertNotNull("deserialized object (stream) is null", hm2);
    assertEquals("Cloned Plugininformation using stream are not equal",
        hm.toString(), hm2.toString());
  }

  /**
   * <p>Tests the serialization of the a serializable Hashmap object.</p>
   */
  @Test
  public void messageSerializationTest() throws IOException {
    for (Message m :
        new Message[]{
            new Message("src", "target", MessageType.DEACTIVATE_PLUGIN,
                new GeigerUrl("geiger://id1/path1"), null),
            new Message("src", "target", MessageType.DEACTIVATE_PLUGIN,
                null, new byte[0]),
            new Message("src", "target", MessageType.DEACTIVATE_PLUGIN,
                new GeigerUrl("id", "path2"), new byte[0]),
            new Message("src", "target", MessageType.DEACTIVATE_PLUGIN,
                new GeigerUrl("id", null), new byte[0]),
            new Message("src", "target", MessageType.DEACTIVATE_PLUGIN,
                new GeigerUrl("id1", null), new byte[0]),
            new Message("src", "target", null, null, new byte[0]),
            new Message("src", "target", null, null,
                UUID.randomUUID().toString().getBytes(StandardCharsets.UTF_8))
          }
    ) {
      ByteArrayOutputStream bout = new ByteArrayOutputStream();
      m.toByteArrayStream(bout);
      ByteArrayInputStream bin = new ByteArrayInputStream(bout.toByteArray());
      Message m2 = Message.fromByteArray(bin);
      assertNotNull("deserialized object (stream) is null", m2);
      assertEquals("Cloned Plugininformation using stream are not equal", m, m2);
    }
  }

}
