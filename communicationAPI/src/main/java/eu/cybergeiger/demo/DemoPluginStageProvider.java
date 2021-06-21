package eu.cybergeiger.demo;

import ch.fhnw.geiger.localstorage.StorageController;
import ch.fhnw.geiger.localstorage.StorageException;
import ch.fhnw.geiger.localstorage.db.data.Node;

/**
 * <p>the class providing demo stages.</p>
 */
public class DemoPluginStageProvider {

  private final StorageController controller;

  /**
   * <p>create a new instance of the provider.</p>
   *
   * @param controller the controller to be used for updates
   */
  public DemoPluginStageProvider(StorageController controller) {
    this.controller = controller;
  }

  /**
   * <p>Get the change set of nodes for a specific stage.</p>
   *
   * @param stage the stage number of the change set
   * @return the nodes to be written
   */
  public Node[] getStageNode(int stage) {
    return null;
  }

  /**
   * <p>Apply all chanes of the specified stage to the controller.</p>
   *
   * @param stage the stage number of the change set
   */
  public void applyStage(int stage) {
    Node[] nodes = getStageNode(stage);
    for (Node n : nodes) {
      try {
        controller.addOrUpdate(n);
      } catch (StorageException se) {
        throw new RuntimeException("Should not happen but is probably harmless (please check)", se);
      }
    }
  }

}
