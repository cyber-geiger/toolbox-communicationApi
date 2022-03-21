package eu.cybergeiger.examples;

import static eu.cybergeiger.communication.LocalApiFactory.MASTER_EXECUTOR;

import ch.fhnw.geiger.localstorage.StorageController;
import ch.fhnw.geiger.localstorage.StorageException;
import ch.fhnw.geiger.localstorage.db.data.Node;
import ch.fhnw.geiger.localstorage.db.data.NodeImpl;
import ch.fhnw.geiger.localstorage.db.data.NodeValueImpl;
import eu.cybergeiger.communication.Declaration;
import eu.cybergeiger.communication.DeclarationMismatchException;
import eu.cybergeiger.communication.LocalApi;
import eu.cybergeiger.communication.LocalApiFactory;
import java.util.logging.Level;
import java.util.logging.Logger;

/**********************************/
/*** BROKEN... DO NOT USE (YET) ***/
/**********************************/
public class ExternalPluginExample {

  public static void main(String[] args) {
    try {
      // Make sure there is a master (For development only)
      LocalApiFactory.getLocalApi(MASTER_EXECUTOR, LocalApi.MASTER,
          Declaration.DO_NOT_SHARE_DATA);

      LocalApi plugin = LocalApiFactory.getLocalApi("NOT_YET_NEEDED_HERE", "plugin1",
          Declaration.DO_NOT_SHARE_DATA);

      StorageController controller = plugin.getStorage();

      //get and print currentUser value
      Node n = controller.get(":Local");
      System.out.println("Current user UUID is:" + n.getValue("currentUser"));

    } catch (StorageException se) {
      Logger.getLogger("ExampleLogger").log(Level.SEVERE, "got an unexpected exception", se);
    } catch (DeclarationMismatchException e) {
      Logger.getLogger("ExampleLogger").log(Level.SEVERE, "OOPS... unexpected exception", e);
    }
  }


}
