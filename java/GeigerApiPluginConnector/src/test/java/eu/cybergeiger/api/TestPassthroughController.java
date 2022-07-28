package eu.cybergeiger.api;

import eu.cybergeiger.api.plugin.Declaration;
import eu.cybergeiger.storage.StorageController;
import eu.cybergeiger.storage.StorageException;
import eu.cybergeiger.storage.Visibility;
import eu.cybergeiger.storage.node.DefaultNode;
import eu.cybergeiger.storage.node.Node;
import eu.cybergeiger.storage.node.value.DefaultNodeValue;
import eu.cybergeiger.storage.node.value.NodeValue;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.util.Arrays;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

public class TestPassthroughController extends DartTest {
  static final String PLUGIN_ID = "plugin";
  static final String NODE_NAME = "test";
  static final String OTHER_NODE_NAME = "otherTest";
  static final String ROOT_PATH = StorageController.PATH_DELIMITER;
  static final String NODE_PATH = StorageController.PATH_DELIMITER + NODE_NAME;
  static final String OTHER_NODE_PATH = StorageController.PATH_DELIMITER + OTHER_NODE_NAME;
  static final String VALUE_KEY = "test";
  static final String VALUE_SMALL_VALUE = "test";
  static final int HUGE_VALUE_LENGTH = 10 * (1 << 20);

  private String generateHugeValue() {
    char[] charArray = new char[HUGE_VALUE_LENGTH];
    Arrays.fill(charArray, ' ');
    return new String(charArray);
  }

  private PluginApi createPlugin() throws IOException {
    return new PluginApi(
      "",
      PLUGIN_ID,
      Declaration.DO_NOT_SHARE_DATA
    );
  }

  private Node createNode() throws StorageException {
    return new DefaultNode(NODE_PATH, PLUGIN_ID);
  }

  private NodeValue createValue(String value) {
    return new DefaultNodeValue(VALUE_KEY, value, "test", "test", 0);
  }

  private static void assertNode(Node actual) throws StorageException {
    assertNode(actual, false);
  }

  private static void assertNode(Node actual, boolean isTombstone) throws StorageException {
    assertNode(actual, NODE_PATH, isTombstone);
  }

  private static void assertNode(Node actual, String path) throws StorageException {
    assertNode(actual, path, false);
  }

  private static void assertNode(Node actual, String path, boolean isTombstone) throws StorageException {
    assertThat(actual.getPath()).isEqualTo(path);
    assertThat(actual.getOwner()).isEqualTo(PLUGIN_ID);
    assertThat(actual.getVisibility()).isEqualTo(Visibility.RED);
    assertThat(actual.isSkeleton()).isFalse();
    assertThat(actual.isTombstone()).isEqualTo(isTombstone);
    assertThat(actual.getValues()).isEmpty();
    assertThat(actual.getChildren()).isEmpty();
  }

  private static void assertValue(NodeValue actual, String value) {
    assertThat(actual.getKey()).isEqualTo(VALUE_KEY);
    assertThat(actual.getValue()).isEqualTo(value);
    assertThat(actual.getAllValueTranslations()).hasSize(1);
    assertThat(actual.getAllDescriptionTranslations()).hasSize(1);
  }

  @Test
  public void testGet_Existent() throws IOException {
    try (GeigerApi api = createPlugin()) {
      assertNode(api.getStorage().get(NODE_PATH));
    }
  }

  @Test
  public void testGet_NonExistent() throws IOException {
    try (GeigerApi api = createPlugin()) {
      assertThatThrownBy(() -> api.getStorage().get(NODE_PATH))
        .isInstanceOf(StorageException.class);
    }
  }

  @Test
  public void testGet_Tombstone() throws IOException {
    try (GeigerApi api = createPlugin()) {
      assertThatThrownBy(() -> api.getStorage().get(NODE_PATH))
        .isInstanceOf(StorageException.class);
    }
  }

  @Test
  public void testGetNodeOrTombstone_Existent() throws IOException {
    try (GeigerApi api = createPlugin()) {
      assertNode(api.getStorage().getNodeOrTombstone(NODE_PATH));
    }
  }

  @Test
  public void testGetNodeOrTombstone_NonExistent() throws IOException {
    try (GeigerApi api = createPlugin()) {
      assertThatThrownBy(() -> api.getStorage().getNodeOrTombstone(NODE_PATH))
        .isInstanceOf(StorageException.class);
    }
  }

  @Test
  public void testGetNodeOrTombstone_Tombstone() throws IOException {
    try (GeigerApi api = createPlugin()) {
      assertNode(api.getStorage().getNodeOrTombstone(NODE_PATH), true);
    }
  }

  @Test
  public void testAdd_Existent() throws IOException {
    try (GeigerApi api = createPlugin()) {
      assertThatThrownBy(() -> api.getStorage().add(createNode()))
        .isInstanceOf(StorageException.class);
    }
  }

  @Test
  public void testAdd_NonExistent() throws IOException {
    try (GeigerApi api = createPlugin()) {
      Node node = createNode();
      api.getStorage().add(node);
      assertThat(api.getStorage().get(NODE_PATH)).isEqualTo(node);
    }
  }

  @Test
  public void testAdd_Tombstone() throws IOException {
    try (GeigerApi api = createPlugin()) {
      Node node = createNode();
      api.getStorage().add(node);
      assertThat(api.getStorage().get(NODE_PATH)).isEqualTo(node);
    }
  }

  @Test
  public void testUpdate_Existent() throws IOException {
    try (GeigerApi api = createPlugin()) {
      Node node = api.getStorage().get(NODE_PATH);
      node.setVisibility(Visibility.WHITE);
      api.getStorage().update(node);
      assertThat(api.getStorage().get(NODE_PATH)).isEqualTo(node);
    }
  }

  @Test
  public void testUpdate_NonExistent() throws IOException {
    try (GeigerApi api = createPlugin()) {
      assertThatThrownBy(() -> api.getStorage().update(createNode()))
        .isInstanceOf(StorageException.class);
    }
  }

  @Test
  public void testUpdate_Tombstone() throws IOException {
    try (GeigerApi api = createPlugin()) {
      assertThatThrownBy(() -> api.getStorage().update(createNode()))
        .isInstanceOf(StorageException.class);
    }
  }

  @Test
  public void testDelete_Existent() throws IOException {
    try (GeigerApi api = createPlugin()) {
      assertNode(api.getStorage().delete(NODE_PATH));
      assertNode(api.getStorage().getNodeOrTombstone(NODE_PATH), true);
    }
  }

  @Test
  public void testDelete_NonExistent() throws IOException {
    try (GeigerApi api = createPlugin()) {
      assertThatThrownBy(() -> api.getStorage().delete(NODE_PATH))
        .isInstanceOf(StorageException.class);
    }
  }

  @Test
  public void testDelete_Tombstone() throws IOException {
    try (GeigerApi api = createPlugin()) {
      // TODO: check validity. Expected it to throw a StorageException.
      assertNode(api.getStorage().delete(NODE_PATH), true);
      assertNode(api.getStorage().getNodeOrTombstone(NODE_PATH), true);
    }
  }

  @Test
  public void testAddOrUpdate_Existent() throws IOException {
    try (GeigerApi api = createPlugin()) {
      Node node = api.getStorage().get(NODE_PATH);
      node.setVisibility(Visibility.WHITE);
      assertThat(api.getStorage().addOrUpdate(node)).isFalse();
      assertThat(api.getStorage().get(NODE_PATH)).isEqualTo(node);
    }
  }

  @Test
  public void testAddOrUpdate_NonExistent() throws IOException {
    try (GeigerApi api = createPlugin()) {
      Node node = createNode();
      assertThat(api.getStorage().addOrUpdate(node)).isTrue();
      assertThat(api.getStorage().get(NODE_PATH)).isEqualTo(node);
    }
  }

  @Test
  public void testAddOrUpdate_Tombstone() throws IOException {
    try (GeigerApi api = createPlugin()) {
      Node node = createNode();
      assertThat(api.getStorage().addOrUpdate(node)).isTrue();
      assertThat(api.getStorage().get(NODE_PATH)).isEqualTo(node);
    }
  }

  @Test
  public void testRenameByPath_Existent() throws IOException {
    try (GeigerApi api = createPlugin()) {
      api.getStorage().rename(NODE_PATH, OTHER_NODE_PATH);
      assertNode(api.getStorage().getNodeOrTombstone(NODE_PATH), true);
      assertNode(api.getStorage().get(OTHER_NODE_PATH), OTHER_NODE_PATH);
    }
  }

  @Test
  public void testRenameByPath_NonExistent() throws IOException {
    try (GeigerApi api = createPlugin()) {
      assertThatThrownBy(() -> api.getStorage().rename(NODE_PATH, OTHER_NODE_PATH))
        .isInstanceOf(StorageException.class);
    }
  }

  @Test
  public void testRenameByPath_Tombstone() throws IOException {
    try (GeigerApi api = createPlugin()) {
      assertThatThrownBy(() -> api.getStorage().rename(NODE_PATH, OTHER_NODE_PATH))
        .isInstanceOf(StorageException.class);
    }
  }

  @Test
  public void testRenameByName() throws IOException {
    try (GeigerApi api = createPlugin()) {
      api.getStorage().rename(NODE_PATH, OTHER_NODE_NAME);
      assertNode(api.getStorage().getNodeOrTombstone(NODE_PATH), true);
      assertNode(api.getStorage().get(OTHER_NODE_PATH), OTHER_NODE_PATH);
    }
  }

  // TODO: add rename to occupied
  // TODO: add rename to existent parent
  // TODO: add rename to non existent parent

  @Test
  public void testGetValue_SmallValue() throws IOException {
    try (GeigerApi api = createPlugin()) {
      assertValue(api.getStorage().getValue(ROOT_PATH, VALUE_KEY), VALUE_SMALL_VALUE);
    }
  }

  @Test
  public void testGetValue_HugeValue() throws IOException {
    String value = generateHugeValue();
    try (GeigerApi api = createPlugin()) {
      assertValue(api.getStorage().getValue(ROOT_PATH, VALUE_KEY), value);
    }
  }

  @Test
  public void testGetValue_NoValue() throws IOException {
    try (GeigerApi api = createPlugin()) {
      assertThat(api.getStorage().getValue(ROOT_PATH, VALUE_KEY)).isNull();
    }
  }

  @Test
  public void testGetValue_NoNode() throws IOException {
    try (GeigerApi api = createPlugin()) {
      assertThatThrownBy(() -> api.getStorage().getValue(NODE_PATH, VALUE_KEY))
        .isInstanceOf(StorageException.class);
    }
  }

//  void addValue(String path, NodeValue value) throws StorageException;
//
//
//  boolean addOrUpdateValue(String path, NodeValue value) throws StorageException;
//
//
//  void updateValue(String path, NodeValue value) throws StorageException;
//
//
//  NodeValue deleteValue(String path, String key) throws StorageException;
//
//
//  List<Node> search(SearchCriteria criteria) throws StorageException;
//
//
//  void close() throws StorageException;
//
//
//  void flush() throws StorageException;
//
//
//  void zap() throws StorageException;
//
//
//  String dump() throws StorageException;
//
//
//  String dump(String rootNode, String prefix) throws StorageException;
}
