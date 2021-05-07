package eu.cybergeiger.communication;

import static org.junit.Assert.assertEquals;

import ch.fhnw.geiger.totalcross.ByteArrayInputStream;
import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;
import java.io.IOException;
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


}
