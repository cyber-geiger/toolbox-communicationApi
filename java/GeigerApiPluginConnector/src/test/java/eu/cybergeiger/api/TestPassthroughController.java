package eu.cybergeiger.api;

import eu.cybergeiger.api.plugin.Declaration;
import eu.cybergeiger.storage.SearchCriteria;
import eu.cybergeiger.storage.StorageController;
import eu.cybergeiger.storage.StorageException;
import eu.cybergeiger.storage.Visibility;
import eu.cybergeiger.storage.node.DefaultNode;
import eu.cybergeiger.storage.node.Node;
import eu.cybergeiger.storage.node.value.DefaultNodeValue;
import eu.cybergeiger.storage.node.value.NodeValue;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.util.Arrays;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

public class TestPassthroughController extends DartTest {
  static final String PLUGIN_ID = "plugin";
  static final String NODE_NAME = "test";
  static final String OTHER_NODE_NAME = "otherTest";
  static final String NODE_PATH = StorageController.PATH_DELIMITER + NODE_NAME;
  static final String OTHER_NODE_PATH = StorageController.PATH_DELIMITER + OTHER_NODE_NAME;
  static final String CHILD_NODE_PATH = OTHER_NODE_PATH + NODE_PATH;
  static final String VALUE_KEY = "test";
  static final String VALUE_VALUE = "test";
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

  private NodeValue createValue() {
    return createValue(VALUE_VALUE);
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

  private static void assertValue(NodeValue actual) {
    assertValue(actual, VALUE_VALUE);
  }

  private static void assertValue(NodeValue actual, String value) {
    assertThat(actual.getKey()).isEqualTo(VALUE_KEY);
    assertThat(actual.getValue()).isEqualTo(value);
    assertThat(actual.getAllValueTranslations()).hasSize(1);
    assertThat(actual.getAllDescriptionTranslations()).hasSize(1);
  }

  @Nested
  class TestGet {
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
  }

  @Nested
  class TestGetNodeOrTombstone {
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
  }

  @Nested
  class TestAdd {
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
  }

  @Nested
  class TestUpdate {
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
  }

  @Nested
  class TestDelete {
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
  }

  @Nested
  class TestAddOrUpdate {
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
  }

  @Nested
  class TestRename {
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

    @Test
    public void testRenameTo_Existent() throws IOException {
      try (GeigerApi api = createPlugin()) {
        assertThatThrownBy(() -> api.getStorage().rename(NODE_PATH, OTHER_NODE_PATH))
          .isInstanceOf(StorageException.class);
      }
    }

    @Test
    public void testRenameTo_Tombstone() throws IOException {
      try (GeigerApi api = createPlugin()) {
        api.getStorage().rename(NODE_PATH, OTHER_NODE_PATH);
        assertNode(api.getStorage().getNodeOrTombstone(NODE_PATH), true);
        assertNode(api.getStorage().get(OTHER_NODE_PATH), OTHER_NODE_PATH);
      }
    }

    @Test
    public void testRenameWithParent_Existent() throws IOException {
      try (GeigerApi api = createPlugin()) {
        api.getStorage().rename(NODE_PATH, CHILD_NODE_PATH);
        assertNode(api.getStorage().getNodeOrTombstone(NODE_PATH), true);
        assertNode(api.getStorage().get(CHILD_NODE_PATH), CHILD_NODE_PATH);
      }
    }

    @Test
    public void testRenameWithParent_NonExistent() throws IOException {
      try (GeigerApi api = createPlugin()) {
        assertThatThrownBy(() -> api.getStorage().rename(NODE_PATH, CHILD_NODE_PATH))
          .isInstanceOf(StorageException.class);
      }
    }

    @Test
    public void testRenameWithParent_Tombstone() throws IOException {
      try (GeigerApi api = createPlugin()) {
        // TODO: check validity. Expected it to throw a StorageException.
        api.getStorage().rename(NODE_PATH, CHILD_NODE_PATH);
        assertNode(api.getStorage().getNodeOrTombstone(NODE_PATH), true);
        assertNode(api.getStorage().get(CHILD_NODE_PATH), CHILD_NODE_PATH);
      }
    }
  }

  @Nested
  class TestGetValue {
    @Test
    public void testGetValue_Existent() throws IOException {
      try (GeigerApi api = createPlugin()) {
        assertValue(api.getStorage().getValue(NODE_PATH, VALUE_KEY));
      }
    }

    @Test
    public void testGetValue_NonExistent() throws IOException {
      try (GeigerApi api = createPlugin()) {
        assertThat(api.getStorage().getValue(NODE_PATH, VALUE_KEY)).isNull();
      }
    }

    @Test
    public void testGetValue_NoNode() throws IOException {
      try (GeigerApi api = createPlugin()) {
        assertThatThrownBy(() -> api.getStorage().getValue(NODE_PATH, VALUE_KEY))
          .isInstanceOf(StorageException.class);
      }
    }

    @Test
    public void testGetValueHugeValue() throws IOException {
      try (GeigerApi api = createPlugin()) {
        assertValue(api.getStorage().getValue(NODE_PATH, VALUE_KEY), generateHugeValue());
      }
    }
  }

  @Nested
  class TestAddValue {
    @Test
    public void testAddValue_Existent() throws IOException {
      try (GeigerApi api = createPlugin()) {
        assertThatThrownBy(() -> api.getStorage().addValue(NODE_PATH, createValue()))
          .isInstanceOf(StorageException.class);
      }
    }

    @Test
    public void testAddValue_NonExistent() throws IOException {
      try (GeigerApi api = createPlugin()) {
        NodeValue value = createValue();
        api.getStorage().addValue(NODE_PATH, value);
        assertThat(api.getStorage().getValue(NODE_PATH, VALUE_KEY)).isEqualTo(value);
      }
    }

    @Test
    public void testAddValue_NoNode() throws IOException {
      try (GeigerApi api = createPlugin()) {
        assertThatThrownBy(() -> api.getStorage().addValue(NODE_PATH, createValue()))
          .isInstanceOf(StorageException.class);
      }
    }

    @Test
    public void testAddValueHugeValue() throws IOException {
      try (GeigerApi api = createPlugin()) {
        NodeValue value = createValue(generateHugeValue());
        api.getStorage().addValue(NODE_PATH, value);
        assertThat(api.getStorage().getValue(NODE_PATH, VALUE_KEY)).isEqualTo(value);
      }
    }
  }

  @Nested
  class TestAddOrUpdateValue {
    @Test
    public void testAddOrUpdateValue_Existent() throws IOException {
      try (GeigerApi api = createPlugin()) {
        NodeValue value = api.getStorage().getValue(NODE_PATH, VALUE_KEY);
        value.setValue(value.getValue() + VALUE_VALUE);
        api.getStorage().addOrUpdateValue(NODE_PATH, value);
        assertThat(api.getStorage().getValue(NODE_PATH, VALUE_KEY)).isEqualTo(value);
      }
    }

    @Test
    public void testAddOrUpdateValue_NonExistent() throws IOException {
      try (GeigerApi api = createPlugin()) {
        NodeValue value = createValue();
        api.getStorage().addOrUpdateValue(NODE_PATH, value);
        assertThat(api.getStorage().getValue(NODE_PATH, VALUE_KEY)).isEqualTo(value);
      }
    }

    @Test
    public void testAddOrUpdateValue_NoNode() throws IOException {
      try (GeigerApi api = createPlugin()) {
        assertThatThrownBy(() -> api.getStorage().addOrUpdateValue(NODE_PATH, createValue()))
          .isInstanceOf(StorageException.class);
      }
    }
  }

  @Nested
  class TestUpdateValue {
    @Test
    public void testUpdateValue_Existent() throws IOException {
      try (GeigerApi api = createPlugin()) {
        NodeValue value = api.getStorage().getValue(NODE_PATH, VALUE_KEY);
        value.setValue(value.getValue() + VALUE_VALUE);
        api.getStorage().updateValue(NODE_PATH, value);
        assertThat(api.getStorage().getValue(NODE_PATH, VALUE_KEY)).isEqualTo(value);
      }
    }

    @Test
    public void testUpdateValue_NonExistent() throws IOException {
      try (GeigerApi api = createPlugin()) {
        assertThatThrownBy(() -> api.getStorage().updateValue(NODE_PATH, createValue()))
          .isInstanceOf(StorageException.class);
      }
    }

    @Test
    public void testUpdateValue_NoNode() throws IOException {
      try (GeigerApi api = createPlugin()) {
        assertThatThrownBy(() -> api.getStorage().updateValue(NODE_PATH, createValue()))
          .isInstanceOf(StorageException.class);
      }
    }
  }

  @Nested
  class TestDeleteValue {
    @Test
    public void testDeleteValue_Existent() throws IOException {
      try (GeigerApi api = createPlugin()) {
        assertValue(api.getStorage().deleteValue(NODE_PATH, VALUE_KEY));
      }
    }

    @Test
    public void testDeleteValue_NonExistent() throws IOException {
      try (GeigerApi api = createPlugin()) {
        assertThatThrownBy(() -> api.getStorage().deleteValue(NODE_PATH, VALUE_KEY))
          .isInstanceOf(StorageException.class);
      }
    }

    @Test
    public void testDeleteValue_NoNode() throws IOException {
      try (GeigerApi api = createPlugin()) {
        assertThatThrownBy(() -> api.getStorage().deleteValue(NODE_PATH, VALUE_KEY))
          .isInstanceOf(StorageException.class);
      }
    }
  }

  @Nested
  class TestSearch {
    // TODO: test all cases

    @Test
    public void testSearch() throws IOException {
      try (GeigerApi api = createPlugin()) {
        SearchCriteria criteria = new SearchCriteria();
        criteria.setNodeName(NODE_NAME);
        List<Node> result = api.getStorage().search(criteria);
        assertThat(result).hasSize(1);
        assertNode(result.get(0));
      }
    }
  }

  @Nested
  class TestClose {
    @Test
    public void testClose() throws IOException {
      try (GeigerApi api = createPlugin()) {
        assertThatThrownBy(() -> api.getStorage().close())
          .isInstanceOf(StorageException.class);
      }
    }
  }

  @Nested
  class TestFlush {
    @Test
    public void testFlush() throws IOException {
      try (GeigerApi api = createPlugin()) {
        api.getStorage().flush();
      }
    }
  }

  @Nested
  class TestZap {
    @Test
    public void testZap() throws IOException {
      try (GeigerApi api = createPlugin()) {
        assertThatThrownBy(() -> api.getStorage().zap())
          .isInstanceOf(StorageException.class);
      }
    }
  }

  @Nested
  class TestDump {
    @Test
    public void testDump_Existent() throws IOException {
      try (GeigerApi api = createPlugin()) {
        assertThat(api.getStorage().dump(NODE_PATH))
          .matches(":test\\[owner=plugin,visibility=red,lastModified=\\d+]\\{}");
      }
    }

    @Test
    public void testDump_NonExistent() throws IOException {
      try (GeigerApi api = createPlugin()) {
        assertThatThrownBy(() -> api.getStorage().dump(NODE_PATH))
          .isInstanceOf(StorageException.class);
      }
    }

    @Test
    public void testDump_Tombstone() throws IOException {
      try (GeigerApi api = createPlugin()) {
        assertThat(api.getStorage().dump(NODE_PATH))
          .matches(":test\\[<tombstone>,owner=plugin,visibility=red,lastModified=\\d+]\\{}");
      }
    }

    @Test
    public void testDumpPrefix() throws IOException {
      try (GeigerApi api = createPlugin()) {
        assertThat(api.getStorage().dump(NODE_PATH, "test"))
          .matches("test:test\\[owner=plugin,visibility=red,lastModified=\\d+]\\{}");
      }
    }
  }
}
