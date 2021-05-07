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


}
