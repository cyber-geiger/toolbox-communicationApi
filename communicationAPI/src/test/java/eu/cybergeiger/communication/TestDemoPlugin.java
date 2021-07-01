package eu.cybergeiger.communication;

import ch.fhnw.geiger.localstorage.StorageException;
import eu.cybergeiger.demo.DemoPlugin;
import eu.cybergeiger.demo.DemoPluginFeatures;
import org.junit.Ignore;
import org.junit.Test;

/**
 * <p>Class to test the DemoPlugin implementation.</p>
 */
public class TestDemoPlugin {

  @Test
  @Ignore
  public void testScanButtonListener() throws StorageException, DeclarationMismatchException {
    LocalApi localApi = LocalApiFactory.getLocalApi("undefined", LocalApi.MASTER,
        Declaration.DO_NOT_SHARE_DATA);
    // create demoPlugin
    DemoPlugin demoPlugin = new DemoPlugin(DemoPluginFeatures.FEATURE_ALL.getId());
    demoPlugin.start();

  }
}
