package eu.cybergeiger.communication;

import static junit.framework.TestCase.fail;

import eu.cybergeiger.totalcross.MalformedUrlException;
import org.junit.Assert;
import org.junit.Ignore;
import org.junit.Test;

/**
 * Class to test the MenuItem implementation.
 */
public class TestMenuItem {

  @Test
  public void testConstructorGetterSetter() {
    try {
      String menuName = "testMenu";
      GeigerUrl url = new GeigerUrl("geiger://plugin/path");
      MenuItem menu = new MenuItem(menuName, url);
      Assert.assertEquals("Checking menu name", menuName, menu.getMenu());
      Assert.assertEquals("Checking stored GeigerUrl", url, menu.getAction());
      Assert.assertTrue(menu.isEnabled());

      MenuItem menu2 = new MenuItem(menuName, url, true);
      Assert.assertEquals("Checking menu name", menuName, menu2.getMenu());
      Assert.assertEquals("Checking stored GeigerUrl", url, menu2.getAction());
      Assert.assertTrue(menu2.isEnabled());

      MenuItem menu3 = new MenuItem(menuName, url, false);
      Assert.assertEquals("Checking menu name", menuName, menu3.getMenu());
      Assert.assertEquals("Checking stored GeigerUrl", url, menu3.getAction());
      Assert.assertFalse(menu3.isEnabled());
      menu3.setEnabled(true);
      Assert.assertTrue(menu3.isEnabled());
      menu3.setEnabled(false);
      Assert.assertFalse(menu3.isEnabled());

    } catch (MalformedUrlException e) {
      fail("MalformedUrlException thrown");
      e.printStackTrace();
    }
  }

  @Test
  public void testToString() {
    try {
      String menuName = "testMenu";
      GeigerUrl url = new GeigerUrl("geiger://plugin/path");
      MenuItem menu = new MenuItem(menuName, url);
      String expectedValue = "\"testMenu\"->" + url + "(enabled)";
      Assert.assertEquals("checking toString", expectedValue, menu.toString());

      MenuItem menu2 = new MenuItem(menuName, url, true);
      Assert.assertEquals("checking toString", expectedValue, menu2.toString());

      expectedValue = "\"testMenu\"->" + url + "(disabled)";
      MenuItem menu3 = new MenuItem(menuName, url, false);
      Assert.assertEquals("checking toString", expectedValue, menu3.toString());

    } catch (MalformedUrlException e) {
      fail("MalformedUrlException thrown");
      e.printStackTrace();
    }
  }

  @Test
  public void testEquals() {
    try {
      String menuName = "testMenu";
      GeigerUrl url = new GeigerUrl("geiger://plugin/path");
      MenuItem menu = new MenuItem(menuName, url);
      MenuItem menu2 = new MenuItem(menuName, url);
      MenuItem menu3 = new MenuItem(menuName, url, true);
      Assert.assertEquals(menu, menu2);
      Assert.assertEquals(menu, menu3);

      MenuItem menu4 = new MenuItem(menuName, url, false);
      Assert.assertNotEquals(menu, menu4);
      menu2.setEnabled(false);
      Assert.assertEquals(menu2, menu4);
    } catch (MalformedUrlException e) {
      fail("MalformedUrlException thrown");
      e.printStackTrace();
    }
  }

  @Test
  public void testHashCode() {
    try {
      String menuName = "testMenu";
      GeigerUrl url = new GeigerUrl("geiger://plugin/path");
      MenuItem menu = new MenuItem(menuName, url);
      MenuItem menu2 = new MenuItem(menuName, url);
      Assert.assertEquals(menu.hashCode(), menu2.hashCode());

      MenuItem menu3 = new MenuItem(menuName, url, true);
      MenuItem menu4 = new MenuItem(menuName, url, false);
      Assert.assertNotEquals(menu3.hashCode(), menu4.hashCode());
      menu3.setEnabled(false);
      Assert.assertEquals(menu3.hashCode(), menu4.hashCode());
    } catch (MalformedUrlException e) {
      fail("MalformedUrlException thrown");
      e.printStackTrace();
    }
  }

}
