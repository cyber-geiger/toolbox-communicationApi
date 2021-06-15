package eu.cybergeiger.communication;

import eu.cybergeiger.totalcross.Matcher;
import org.junit.Assert;
import org.junit.Test;

/**
 * Test classes for TotalCross compatibility implementations.
 */
public class TestTotalcross {
  /**
   * <p>Trivial Test for getting current system time.</p>
   */
  @Test
  public void totalCrossCurrentTimeMillis() {
    Assert.assertNotEquals(ch.fhnw.geiger.totalcross.System.currentTimeMillis(), 0);
  }

  /**
   * <p>Regex test.</p>
   */
  @Test
  public void regexTests() {
    Matcher m = Matcher.compile("([^:]*)::(.*)");
    Matcher n = m.matcher("hello::dude");
    String g1 = n.group(1);
    String g2 = n.group(2);
    Assert.assertEquals("hello", g1);
    Assert.assertEquals("dude", g2);
  }

}
