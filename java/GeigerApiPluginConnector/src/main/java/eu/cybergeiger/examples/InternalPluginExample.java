package eu.cybergeiger.examples;

import ch.fhnw.geiger.localstorage.StorageController;
import ch.fhnw.geiger.localstorage.StorageException;
import ch.fhnw.geiger.localstorage.db.data.Node;
import ch.fhnw.geiger.localstorage.db.data.NodeImpl;
import ch.fhnw.geiger.localstorage.db.data.NodeValueImpl;
import eu.cybergeiger.api.plugin.Declaration;
import eu.cybergeiger.api.exceptions.DeclarationMismatchException;
import eu.cybergeiger.api.CommunicationApi;
import eu.cybergeiger.api.CommunicationApiFactory;
import java.util.logging.Level;
import java.util.logging.Logger;

public class InternalPluginExample {

  public static void main(String[] args) {
    try {
      CommunicationApi localMaster = CommunicationApiFactory.getLocalApi("NOT_YET_NEEDED_HERE", CommunicationApi.MASTER,
          Declaration.DO_NOT_SHARE_DATA);
      StorageController controller = localMaster.getStorage();

      //get and print currentUser value
      Node n = controller.get(":Local");
      System.out.println("Current user UUID is:" + n.getValue("currentUser"));

      // geting invocation counter
      try {
        n = controller.get(":Local:temp");
      } catch (StorageException se) {
        n = new NodeImpl(":Local:temp");
        n.addValue(new NodeValueImpl("counter", "0"));
        controller.add(n);
      }

      //incrementing counter
      int i = Integer.parseInt(n.getValue("counter").getValue()) + 1;
      System.out.println("Current counter is:" + i);
      n.updateValue(new NodeValueImpl("counter", "" + i));

      // updating counter
      controller.update(n);
    } catch (StorageException se) {
      Logger.getLogger("ExampleLogger").log(Level.SEVERE, "got an unexpected exception", se);
    } catch (DeclarationMismatchException e) {
      Logger.getLogger("ExampleLogger").log(Level.SEVERE, "OOPS... unexpected exception", e);
    }
  }


}
