package eu.cybergeiger.communication;

import static org.junit.Assert.assertEquals;

import ch.fhnw.geiger.localstorage.StorageController;
import ch.fhnw.geiger.localstorage.StorageException;
import ch.fhnw.geiger.localstorage.db.data.Node;
import eu.cybergeiger.demo.DemoPlugin;
import eu.cybergeiger.demo.DemoPluginFeatures;
import eu.cybergeiger.demo.DemoPluginStageProvider;
import org.junit.After;
import org.junit.Before;
import org.junit.Ignore;
import org.junit.Test;

/**
 * <p>Class to test the DemoPlugin implementation.</p>
 */
public class TestDemoPlugin {

  LocalApi localApi;
  StorageController storageController;
  String localUser;
  String localDevice;

  /**
   * setting up the environment.
   *
   * @throws DeclarationMismatchException if localApi declaration does not match
   * @throws StorageException if storage initialization fails
   */
  @Before
  public void setup() throws DeclarationMismatchException, StorageException {
    localApi = LocalApiFactory.getLocalApi("undefined", LocalApi.MASTER,
        Declaration.DO_NOT_SHARE_DATA);
    storageController = localApi.getStorage();
    Node localNode = storageController.get(":Local");
    localUser = localNode.getValue("currentUser").getValue();
    localDevice = localNode.getValue("currentDevice").getValue();
  }

  /**
   * deleting written nodes in storage for cosistency.
   *
   * @throws StorageException if storage cannot be cleared
   */
  @After
  public void tearDown() throws StorageException {
    localApi = null;
    // clear data
    storageController.zap();
    storageController = null;
  }

  @Test
  @Ignore
  public void testStartStop() throws StorageException, DeclarationMismatchException {
    // create demoPlugin
    DemoPlugin demoPlugin = new DemoPlugin(DemoPluginFeatures.FEATURE_ALL.getId());
    demoPlugin.start();
    demoPlugin.stop();
  }

  @Test
  @Ignore
  public void testScanButtonListener() throws StorageException, DeclarationMismatchException {
    // create demoPlugin
    DemoPlugin demoPlugin = new DemoPlugin(DemoPluginFeatures.FEATURE_ALL.getId());
    demoPlugin.start();

    // check data before scan button pressed (stage 0)
    Node geigerIndicatorUserData = storageController.get(":Users:" + localUser + ":"
        + DemoPluginStageProvider.UUID_GEIGER_INDICATOR + ":data");
    assertEquals("checking user aggregate GeigerScore", "74",
        geigerIndicatorUserData.getValue("GEIGER_score").getValue());
    assertEquals("Checking user aggregate threat scores", "Phishing=75;Malware=73",
        geigerIndicatorUserData.getChild("GeigerScoreAgregate")
            .getValue("threats_score").getValue());
    assertEquals("Checking user threat scores", "Phishing=73;Malware=70",
        geigerIndicatorUserData.getChild("GeigerScoreUser")
            .getValue("threats_score").getValue());

    // checking device scores
    Node geigerIndicatorDeviceData = storageController.get(":Devices:" + localDevice + ":"
        + DemoPluginStageProvider.UUID_GEIGER_INDICATOR + ":data");
    assertEquals("checking device threats score", "Phishing=79;Malware=75",
        geigerIndicatorDeviceData.getChild("GeigerScoreDevice")
            .getValue("threats_score").getValue());

    // notify listeners for SCAN_PRESSED event
    localApi.scanButtonPressed();

    // check if values changed
    geigerIndicatorUserData = storageController.get(":Users:" + localUser + ":"
        + DemoPluginStageProvider.UUID_GEIGER_INDICATOR + ":data");
    assertEquals("checking user aggregate GeigerScore", "60",
        geigerIndicatorUserData.getValue("GEIGER_score").getValue());
    assertEquals("Checking user aggregate threat scores", "Phishing=59;Malware=60",
        geigerIndicatorUserData.getChild("GeigerScoreAgregate")
            .getValue("threats_score").getValue());
    assertEquals("Checking user threat scores", "Phishing=58;Malware=58",
        geigerIndicatorUserData.getChild("GeigerScoreUser")
            .getValue("threats_score").getValue());

    // checking device scores
    geigerIndicatorDeviceData = storageController.get(":Devices:" + localDevice + ":"
        + DemoPluginStageProvider.UUID_GEIGER_INDICATOR + ":data");
    assertEquals("checking device threats score", "Phishing=60;Malware=62",
        geigerIndicatorDeviceData.getChild("GeigerScoreDevice")
            .getValue("threats_score").getValue());

  }
}
