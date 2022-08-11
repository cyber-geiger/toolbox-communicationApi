package eu.cybergeiger.api;

import eu.cybergeiger.api.plugin.CommunicationSecret;
import eu.cybergeiger.api.plugin.PluginInformation;
import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Class to test PluginInformation implementation.
 */
public class TestPluginInformation {
  static final String ID = "plugin";
  static final String OTHER_ID = "other_plugin";
  static final String EXECUTABLE = "executable";
  static final String OTHER_EXECUTABLE = "other_executable";
  static final int PORT = 1234;
  static final int OTHER_PORT = 4321;
  static final CommunicationSecret SECRET =
    new CommunicationSecret("test".getBytes(StandardCharsets.UTF_8));
  static final CommunicationSecret OTHER_SECRET =
    new CommunicationSecret("other_test".getBytes(StandardCharsets.UTF_8));

  @Test
  public void testConstructor() {
    PluginInformation info = new PluginInformation(ID, EXECUTABLE, PORT, SECRET);
    assertThat(info.getId()).isEqualTo(ID);
    assertThat(info.getPort()).isEqualTo(PORT);
    assertThat(info.getExecutable()).isEqualTo(EXECUTABLE);
    assertThat(info.getSecret()).isEqualTo(SECRET);
  }

  @Test
  public void testHashCodeSame() {
    assertThat(new PluginInformation(ID, EXECUTABLE, PORT, SECRET).hashCode())
      .isEqualTo(new PluginInformation(ID, EXECUTABLE, PORT, SECRET).hashCode());
  }

  @Test
  public void testHashCodeDifferentId() {
    assertThat(new PluginInformation(ID, EXECUTABLE, PORT, SECRET).hashCode())
      .isEqualTo(new PluginInformation(OTHER_ID, EXECUTABLE, PORT, SECRET).hashCode());
  }

  @Test
  public void testHashCodeDifferentPort() {
    assertThat(new PluginInformation(ID, EXECUTABLE, PORT, SECRET).hashCode())
      .isNotEqualTo(new PluginInformation(ID, EXECUTABLE, OTHER_PORT, SECRET).hashCode());
  }

  @Test
  public void testHashCodeDifferentExecutable() {
    assertThat(new PluginInformation(ID, EXECUTABLE, PORT, SECRET).hashCode())
      .isNotEqualTo(new PluginInformation(ID, OTHER_EXECUTABLE, PORT, SECRET).hashCode());
  }

  @Test
  public void testHashCodeDifferentSecret() {
    assertThat(new PluginInformation(ID, EXECUTABLE, PORT, SECRET).hashCode())
      .isNotEqualTo(new PluginInformation(ID, EXECUTABLE, PORT, OTHER_SECRET).hashCode());
  }

}
