package eu.cybergeiger.demo;

import ch.fhnw.geiger.localstorage.StorageController;
import ch.fhnw.geiger.localstorage.StorageException;
import ch.fhnw.geiger.localstorage.db.data.Node;
import ch.fhnw.geiger.localstorage.db.data.NodeImpl;
import ch.fhnw.geiger.localstorage.db.data.NodeValueImpl;
import ch.fhnw.geiger.totalcross.System;
import ch.fhnw.geiger.totalcross.UUID;
import eu.cybergeiger.communication.CommunicatorApi;
import eu.cybergeiger.communication.Declaration;
import eu.cybergeiger.communication.DeclarationMismatchException;
import eu.cybergeiger.communication.GeigerUrl;
import eu.cybergeiger.communication.LocalApi;
import eu.cybergeiger.communication.LocalApiFactory;
import eu.cybergeiger.communication.Message;
import eu.cybergeiger.communication.MessageType;
import eu.cybergeiger.communication.PluginListener;
import java.io.IOException;


/**
 * <p>A Demo plugin providing dummy data.</p>
 */
public class DemoPlugin {

  public static UUID UUID = new UUID(0x1111111122223333L, 0x4444555555555555L);

  private static class DemoPluginRunner extends Thread implements PluginListener {

    /** true if the runner should shut down as soon as possible */
    private boolean shutdown = false;

    /** the currently requested features */
    private final long features;

    /** the current data provider */
    private DemoPluginStageProvider dataProvider;

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

        // check if demo scenario should be used
        if (DemoPluginFeatures.FEATURE_SCAN_DEMO.containsFeature(features)) {
          // get initial data
          dataProvider = new DemoPluginStageProvider(store);
          // register Listener that sets the next state on SCAN_PRESSED event if not already exists
          comm.registerListener(new MessageType[]{MessageType.SCAN_PRESSED}, this);
        }

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
      for (Node n : new Node[]{
          new NodeImpl(":Users:" + userUuid + ":" + UUID),
          new NodeImpl(":Devices:" + deviceUuid + ":" + UUID)}) {
        try {
          store.add(n);
        } catch (StorageException ioe) {
          // just ignore if the node already exists
        }
      }

      // register listener if required
      if (DemoPluginFeatures.FEATURE_SCAN_DEMO.containsFeature(features)) {
        comm.registerListener(new MessageType[]{MessageType.SCAN_PRESSED}, this);
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

          // wait for some time
          Thread.sleep(1000);

        } catch (InterruptedException ie) {
          // may be safely ignored (wakeup by shutdown or state update?)
        }
      }
      // register listener if required
      if (DemoPluginFeatures.FEATURE_SCAN_DEMO.containsFeature(features)) {
        comm.deregisterListener(new MessageType[]{MessageType.SCAN_PRESSED}, this);
      }

      // remove heartbeat node
      if (DemoPluginFeatures.FEATURE_HEARTBEAT.containsFeature(features)) {
        try {
          StorageController storageController = LocalApiFactory.getLocalApi(LocalApi.MASTER)
              .getStorage();
          storageController.delete(":Devices:" + deviceUuid + ":" + UUID);
        } catch (StorageException e) {
          e.printStackTrace();
        }
      }
    }

    /**
     * <p>Sets the state and updates the store to reflect the current state.</p>
     * @param state the state to be set
     */
    public void setState(int state) {
      this.state = state % DemoPluginStageProvider.MAX_STATES;

      // get new Nodes
      try {
        dataProvider.applyStage(this.state);
      } catch (StorageException e) {
        e.printStackTrace();
      }
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

    @Override
    public void pluginEvent(GeigerUrl url, Message msg) {
      setState(++state);
    }
  }

  /** The currently set features to be supported */
  private final long features;

  /** the currently running runner */
  private DemoPluginRunner runner = null;

  /** the lock object to guarantee that only one runner is running simulataneously. */
  private final Object lock = new Object();

  /**
   * <p>Create an instance of the plugin demo.</p>
   *
   * @param features the features to be enabled (xor'ed list of ids from DemoPluginFeatures)
   */
  public DemoPlugin(long features) {
    this.features = features;
  }

  /**
   * <p>start the data provider.</p>
   */
  public void start() {
    synchronized (lock) {
      // check if heartbeat exists
      StorageController store = null;
      long lastHeartbeat = 0;
      try {
        store = LocalApiFactory.getLocalApi("undefined", LocalApi.MASTER,
            Declaration.DO_NOT_SHARE_DATA).getStorage();

        // initialize database
        new DemoPluginStageProvider(store).applyStage(-1);

        String deviceUuid = store.getValue(":Local", "currentDevice").getValue();

        lastHeartbeat = System.currentTimeMillis() - Long.parseLong(store
            .get(":Devices:" + deviceUuid + ":" + UUID)
            .getValue("heartbeat").getValue());
      } catch (StorageException | DeclarationMismatchException e) {
        // ignore it. It simply means that there is nor runner available
        // e.printStackTrace();
      }

      if (runner == null || lastHeartbeat > 5000) {
        // create and start runner if not exists or heartbeat is old
        try {
          runner = new DemoPluginRunner(features);
        } catch (IOException e) {
          // FIXME
          e.printStackTrace();
        }
        runner.start();
      } else {
        throw new RuntimeException("Runner already running");
      }
    }
  }

  /**
   * <p>Stop the data provider.</p>
   */
  public void stop() {
    synchronized (lock) {
      if (runner != null) {
        runner.shutdown();
        runner = null;
      }
    }
  }

}
