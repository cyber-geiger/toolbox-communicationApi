package eu.cybergeiger.communication;

import org.junit.Assert;
import org.junit.Test;

/**
 * <p>Test the feature class of the demo plugin.</p>
 */
public class DemoPluginFeaturesTest {

  @Test
  public void bitSetterTest() {
    Assert.assertEquals("unable to set first bit", 1,
        DemoPluginFeatures.FEATURE_HEARTBEAT.getId());
    Assert.assertEquals("unable to set second bit", 2,
        DemoPluginFeatures.FEATURE_SCAN_DEMO.getId());
    Assert.assertEquals("unable to set third bit", 4,
        DemoPluginFeatures.FEATURE_RANDOM_BOOLEAN.getId());
    for (DemoPluginFeatures f : DemoPluginFeatures.values()) {
      System.out.println("## testing feature " + f.name() + " (" + f.getId() + ")");
      Assert.assertTrue(f.name() + " is not in ALL ",
          DemoPluginFeatures.FEATURE_ALL.containsFeature(f.getId()));
      Assert.assertTrue(f.name() + " does not contain itself",
          f.containsFeature(f.getId()));
    }
  }
}
