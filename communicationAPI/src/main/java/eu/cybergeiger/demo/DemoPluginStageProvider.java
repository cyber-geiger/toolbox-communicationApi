package eu.cybergeiger.demo;

import ch.fhnw.geiger.localstorage.SearchCriteria;
import ch.fhnw.geiger.localstorage.StorageController;
import ch.fhnw.geiger.localstorage.StorageException;
import ch.fhnw.geiger.localstorage.Visibility;
import ch.fhnw.geiger.localstorage.db.data.Node;
import ch.fhnw.geiger.localstorage.db.data.NodeImpl;
import ch.fhnw.geiger.localstorage.db.data.NodeValue;
import ch.fhnw.geiger.localstorage.db.data.NodeValueImpl;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

/**
 * <p>the class providing demo stages.</p>
 */
public class DemoPluginStageProvider {

  public static final String UUID_MI_CYBERRANGE = "123456-1234-1234-1234-1234567890";
  public static final String UUID_KSP_ON_ACCESS_SCAN = "123456-1234-1234-1234-1234567891";

  private final String localUser;
  private final String localDevice;
  private final String deviceGeigerPlugin;
  private final String userGeigerPlugin;

  private final StorageController controller;

  /**
   * <p>create a new instance of the provider.</p>
   *
   * @param controller the controller to be used for updates
   * @throws StorageException if anythings goes wrong when accessing the database backend
   */
  public DemoPluginStageProvider(StorageController controller) throws StorageException {
    this.controller = controller;
    Node localNode = controller.get(":Local");
    this.localUser = localNode.getValue("currentUser").getValue();
    this.localDevice = localNode.getValue("currentDevice").getValue();
    this.deviceGeigerPlugin = ":Devices:" + localDevice
        + ":gi7448fc-0795-44a9-8ec6-gicba9520c20:data";
    this.userGeigerPlugin = ":Users:" + localUser
        + ":gi7448fc-0795-44a9-8ec6-gicba9520c20:data";
    initNodes();
  }

  private void initNodes() throws StorageException {
    applyStage(-1);
    applyStage(0);
  }

  /**
   * <p>Get the change set of nodes for a specific stage.</p>
   *
   * @param stage the stage number of the change set
   * @return the nodes to be written
   * @throws StorageException if anythings goes wrong when accessing the database backend
   */
  public Node[] getStageNode(int stage) throws StorageException {
    Node[] nodes;
    switch (stage) {
      case -1:
        nodes = getInitialNodes();
        break;
      case 0:
        nodes = getStage0Nodes();
        break;
      default:
        nodes = new Node[0];
    }
    return nodes;
  }

  private Node[] getInitialNodes() throws StorageException {
    // Add global threats map
    Map<String, String[]> threatMap = new HashMap<>();
    threatMap.put("80efffaf-98a1-4e0a-8f5e-gr89388350ma",
        new String[]{"Malware"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-gr89388351wb",
        new String[]{"Web-based threats"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-gr89388352ph",
        new String[]{"Phishing"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-gr89388353wa",
        new String[]{"Web application threats"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-gr89388354sp",
        new String[]{"Spam"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-gr89388355ds",
        new String[]{"Denial of service"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-gr89388356db",
        new String[]{"Data breach"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-gr89388357it",
        new String[]{"Insider threats"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-gr89388358bn",
        new String[]{"Botnets"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-gr89388359ph",
        new String[]{"Physical threats"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-gr89388360ra",
        new String[]{"Ransomware", "Malware"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-gr89388361ee",
        new String[]{"External environment threats"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-th89388362wb",
        new String[]{"Web-based attacks", "Web-based threats"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-th89388363wa",
        new String[]{"Web application attacks", "Web-based threats"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-th89388364ds",
        new String[]{"DDoS", "Denial of service"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-th89388365it",
        new String[]{"Identity theft", "Data breach"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-th89388366ph",
        new String[]{"Physical", "Physical threats"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-th89388367il",
        new String[]{"Information leakage", "Insider threats"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-th89388368cj",
        new String[]{"Cryptojacking", "Malware"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-th89388369er",
        new String[]{"Erroneous use", "Insider threats"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-th89388370tp",
        new String[]{"Third party", "External environment threats"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-th89388371sc",
        new String[]{"Supply chain", "External environment threats"});
    threatMap.put("80efffaf-98a1-4e0a-8f5e-th89388372le",
        new String[]{"Legal", "External environment threats"});

    // building node list
    List<Node> l = new Vector<>();
    l.add(new NodeImpl(":Global:threats"));
    for (Map.Entry<String, String[]> e : threatMap.entrySet()) {
      Node threat = new NodeImpl(":Global:threats:" + e.getKey(), Visibility.RED,
          new NodeValue[]{
              new NodeValueImpl("name", e.getValue()[0]),
              new NodeValueImpl("GEIGER_threat",
                  e.getValue().length > 1 ? e.getValue()[1] : e.getValue()[0])}, null
      );
      l.add(threat);
    }
    // add threat score list
    l.add(new NodeImpl(":Global:profiles"));
    final String[] listOfThreats = new String[]{
        "Malware", "Web-based threats", "Phishing", "Web application threats", "Spam",
        "Denial of service", "Data breach", "Insider threats", "Botnets", "Physical threats",
        "Ransomware", "External environment threats"};
    final Map<String, String[]> childMap = new HashMap<>();
    childMap.put("328161f6-89bd-49f6-prof-dig75ff5ind", new String[]{"digitally dependent",
        "0.1489", "0.0848", "0.1693", "0.0622", "0.0718", "0.0196", "0.0786", "0.0622", "0.0305",
        "0.0357", "0.1531", "0.0833"});
    childMap.put("328161f6-89bd-49f6-prof-dig75ffenab", new String[]{"digital enabler",
        "0.1489", "0.0760", "0.1308", "0.0782", "0.0610", "0.0810", "0.0855", "0.1070", "0.0402",
        "0.0678", "0.1078", "0.0833"});
    childMap.put("328161f6-89bd-49f6-prof-dig75ff5bas", new String[]{"digitally based",
        "0.0966", "0.0794", "0.1226", "0.0776", "0.0630", "0.0668", "0.0858", "0.0897", "0.0491",
        "0.0588", "0.1272", "0.8333"});
    for (Map.Entry<String, String[]> e : childMap.entrySet()) {
      String[] a = e.getValue();
      Node node = new NodeImpl(":Global:profiles:" + e.getKey());
      node.addValue(new NodeValueImpl("name", a[0]));
      for (int i = 1; i < a.length; i++) {
        String threat = listOfThreats[i - 1];
        String threatValue = a[i];
        node.addValue(new NodeValueImpl(getThreatUuid(threat), threatValue));
      }
      l.add(node);
    }
    return l.toArray(new Node[0]);
  }

  private String getThreatUuid(String name) throws StorageException {
    List<Node> n = controller.search(new SearchCriteria(":Global:threats", "name", name));
    return n.get(0).getName();
  }

  private Node[] getStage0Nodes() {
    return new Node[]{
        new NodeImpl(userGeigerPlugin, null,
            new NodeValue[]{new NodeValueImpl("GEIGER_score", "74")},
            new Node[]{
                new NodeImpl(userGeigerPlugin + ":GeigerScoreAgregate", null,
                    new NodeValue[]{
                        new NodeValueImpl("GEIGER_score", "74"),
                        new NodeValueImpl("threats_score", "Phishing=75;Malware=73")}, null),
                new NodeImpl(userGeigerPlugin + ":GeigerScoreUser", null,
                    new NodeValue[]{new NodeValueImpl("threats_score", "Phishing=75;Malware=73")},
                    null),
                new NodeImpl(userGeigerPlugin + ":recommendations", null,
                    new NodeValue[]{new NodeValueImpl("80efffaf-98a1-4e0a-8f5e-gr89388355ds", "")},
                    null)}
        ),
        new NodeImpl(deviceGeigerPlugin, null,
            new NodeValue[]{
                new NodeValueImpl("GEIGER_score", "")},
            new Node[]{
              new NodeImpl(deviceGeigerPlugin + ":GeigerScoreDevice", null,
                  new NodeValue[]{
                      new NodeValueImpl("threats_score", "")}, null),
              new NodeImpl(deviceGeigerPlugin + ":recommendations", null,
                  new NodeValue[]{new NodeValueImpl("80efffaf-98a1-4e0a-8f5e-gr89388355ds", "")},
                  null)}),
        new NodeImpl(":Global:Recommendations:" + UUID_MI_CYBERRANGE, null,
            new NodeValue[]{
                new NodeValueImpl("short", "Experience Phishing Simulation"),
                new NodeValueImpl("long", "Experience the MontImage basic cyber range.")},
            new Node[]{
                new NodeImpl(deviceGeigerPlugin + ":GeigerScoreDevice", null,
                  new NodeValue[]{new NodeValueImpl("threats_score", "")}, null),
                new NodeImpl(deviceGeigerPlugin + ":recommendations", null,
                  new NodeValue[]{new NodeValueImpl("80efffaf-98a1-4e0a-8f5e-gr89388355ds", "")},
                  null)})};
  }

  /**
   * <p>Apply all chanes of the specified stage to the controller.</p>
   *
   * @param stage the stage number of the change set
   * @throws StorageException if anything goes wrong when accessing the storage backend
   */
  public void applyStage(int stage) throws StorageException {
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
