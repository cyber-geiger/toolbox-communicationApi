package eu.cybergeiger.demo;

import ch.fhnw.geiger.localstorage.StorageController;
import ch.fhnw.geiger.localstorage.StorageException;
import ch.fhnw.geiger.localstorage.db.data.Node;
import ch.fhnw.geiger.localstorage.db.data.NodeImpl;
import ch.fhnw.geiger.localstorage.db.data.NodeValueImpl;
import ch.fhnw.geiger.totalcross.System;
import eu.cybergeiger.communication.CommunicatorApi;
import eu.cybergeiger.communication.Declaration;
import eu.cybergeiger.communication.DeclarationMismatchException;
import eu.cybergeiger.communication.LocalApiFactory;
import java.io.IOException;
import java.util.UUID;

/**
 * <p>A Demo plugin providing dummy data.</p>
 */
public class DemoPlugin {

  public static UUID UUID = new UUID(0x1111111122223333L, 0x4444555555555555L);

  private static class DemoPluginRunner extends Thread {

    private boolean shutdown = false;
    private long features = 0;
    public static int MAX_STATES = 1;

    private int state;
    private CommunicatorApi comm;
    private StorageController store;

    private final String userUuid;
    private final String deviceUuid;
    private final String pluginUuid = UUID.toString();

    public DemoPluginRunner(long features) throws IOException {
      try {
        comm = LocalApiFactory.getLocalApi("still undefined", "DemoPlugin",
            Declaration.DO_NOT_SHARE_DATA);
        store = comm.getStorage();
      } catch (DeclarationMismatchException dme) {
        throw new IOException("OOPS! that should not happen... please contact developer", dme);
      }
      this.features = features;
      try {
        // get user node
        userUuid = store.getValue(":Local", "currentUser").getValue();

        // get device node
        deviceUuid = store.getValue(":Local", "currentDevice").getValue();

      } catch (StorageException se) {
        throw new RuntimeException("OOPS! ... mandatory keys in storage are missing. "
            + "s should not happen. Contact developer", se);
      }
      setState(0);
    }

    @Override
    public void run() {
      // make sure that this is always a daemon thread and not keeping the app from shutting down
      setDaemon(true);

      // initially create plugin nodes
      for (Node n :
          new Node[]
            {
              new NodeImpl(":Users:" + userUuid + ":" + UUID),
              new NodeImpl(":Devices:" + deviceUuid + ":" + UUID)
            }
      ) {
        try {
          store.add(n);
        } catch (StorageException ioe) {
          // just ignore if the node already exists
        }
      }

      // Do the data
      while (!shutdown) {
        try {
          // update heartbeat
          if (DemoPluginFeatures.FEATURE_HEARTBEAT.containsFeature(features)) {
            try {
              Node n = store.get(":Devices:" + deviceUuid + ":" + UUID);
              n.updateValue(new NodeValueImpl("heartbeat", "" + System.currentTimeMillis()));
            } catch (StorageException se) {
              throw new RuntimeException("OOPS! ... mandatory keys in storage are missing. "
                  + "s should not happen. Contact developer", se);
            }
          }

          // implement scan states
          if (DemoPluginFeatures.FEATURE_SCAN_DEMO.containsFeature(features)) {
            // FIXME waiting for spec here
          }

          // wait for some time
          Thread.sleep(1000);

        } catch (InterruptedException ie) {
          // may be safely ignored (wakeup by shutdown or state update?)
        }
      }
    }

    public void setState(int state) {
      this.state = state % MAX_STATES;
    }

    public void shutdown() {
      // initiate shutdown
      shutdown = true;
      synchronized (this) {
        this.interrupt();
        while (this.isAlive()) {
          try {
            Thread.sleep(10);
          } catch (InterruptedException ie) {
            // may be safely ignored
          }
        }
      }
    }

  }

  private long features;

  private Thread runner = null;

  /**
   * <p>Create an instance of the plugin demo.</p>
   *
   * @param features the features to be enabled
   *                 (xor'ed list of ids from DemoPluginFeatures)
   */
  public DemoPlugin(long features) {
    this.features = features;
  }

  /**
   * <p>start the data provider.</p>
   */
  public void start() {
    // check if heartbeat exists
    // FIXME
    if (runner != null && runner.isAlive()) {
      // check if threat not already running
      // FIXME
      synchronized (runner) {
        // FIXME
      }
    }
    // start thread

  }

  /**
   * <p>Stop the data provider.</p>
   */
  public void stop() {
    // stop thread
    // remove heartbeat node
  }

}
