package eu.cybergeiger.api;

import java.net.MalformedURLException;

import eu.cybergeiger.api.message.GeigerUrl;

import static org.assertj.core.api.Assertions.*;

import org.junit.jupiter.api.Test;

/**
 * Class to test the GeigerUrl implementation.
 */
public class TestGeigerUrl {
  static final String standardProtocol = "geiger";
  static final String standardPlugin = "plugin";
  static final String standardPath = "path";

  static final String[] protocols = new String[]{
    "geiger", "some-protocol",
    "protocol/subprotocol", "protocol°+*ç%&/()=?`èà£!é_:;"
  };
  static final String[] plugins = new String[]{
    "plugin", "some-plugin",
    "plugin-?!subplugin", "plugin°+*ç%&()=?`èà£!é_:;",
    "plugin?some-plugin+some%path"
  };
  static final String[] paths = new String[]{
    "path", "some-path",
    "path/subpath", "some/path/to/something",
    "path°+*ç%&/()=?`èà£!é_:;", "path://somepath/subpath",
    ""
  };

  @Test
  public void testParse() throws MalformedURLException {
    for (String protocol : protocols) {
      for (String plugin : plugins) {
        for (String path : paths) {
          GeigerUrl url = GeigerUrl.parse(protocol + "://" + plugin + "/" + path);
          assertThat(url.getProtocol()).isEqualTo(protocol);
          assertThat(url.getPlugin()).isEqualTo(plugin);
          assertThat(url.getPath()).isEqualTo(path);
        }
      }
    }

    // Missing colon
    assertThatThrownBy(() -> GeigerUrl.parse(standardProtocol + "//" + standardPlugin + "/" + standardPath))
      .isInstanceOf(MalformedURLException.class);
    // Missing slash
    assertThatThrownBy(() -> GeigerUrl.parse(standardProtocol + ":/" + standardPlugin + "/" + standardPath))
      .isInstanceOf(MalformedURLException.class);
    // Missing protocol
    assertThatThrownBy(() -> GeigerUrl.parse("://" + standardPlugin + "/" + standardPath))
      .isInstanceOf(MalformedURLException.class);
    // Missing plugin + path
    assertThatThrownBy(() -> GeigerUrl.parse(standardProtocol + "://"))
      .isInstanceOf(MalformedURLException.class);
  }

  @Test
  public void testImplicitProtocolConstructor() {
    for (String plugin : plugins) {
      for (String path : paths) {
        GeigerUrl url = new GeigerUrl(plugin, path);
        assertThat(url.getProtocol()).isEqualTo(GeigerUrl.GEIGER_PROTOCOL);
        assertThat(url.getPlugin()).isEqualTo(plugin);
        assertThat(url.getPath()).isEqualTo(path);
      }
    }

    assertThatThrownBy(() -> new GeigerUrl("", standardPath))
      .isInstanceOf(IllegalArgumentException.class);
    assertThatThrownBy(() -> new GeigerUrl(null, standardPath))
      .isInstanceOf(IllegalArgumentException.class);
  }

  @Test
  public void testProtocolPluginPathConstructor() {
    for (String protocol : protocols) {
      for (String plugin : plugins) {
        for (String path : paths) {
          GeigerUrl url = new GeigerUrl(protocol, plugin, path);
          assertThat(url.getProtocol()).isEqualTo(protocol);
          assertThat(url.getPlugin()).isEqualTo(plugin);
          assertThat(url.getPath()).isEqualTo(path);
        }
      }
    }

    assertThatThrownBy(() -> new GeigerUrl(null, standardPlugin, standardPath))
      .isInstanceOf(IllegalArgumentException.class);
    assertThatThrownBy(() -> new GeigerUrl("", standardPlugin, standardPath))
      .isInstanceOf(IllegalArgumentException.class);
    assertThatThrownBy(() -> new GeigerUrl(standardProtocol, null, standardPath))
      .isInstanceOf(IllegalArgumentException.class);
    assertThatThrownBy(() -> new GeigerUrl(standardProtocol, "", standardPath))
      .isInstanceOf(IllegalArgumentException.class);
    assertThatThrownBy(() -> new GeigerUrl(standardProtocol, standardPlugin, null))
      .isInstanceOf(IllegalArgumentException.class);
  }

  @Test
  public void testToString() throws MalformedURLException {
    for (String protocol : protocols) {
      for (String plugin : plugins) {
        for (String path : paths) {
          String expected = protocol + "://" + plugin + "/" + path;
          assertThat(new GeigerUrl(protocol, plugin, path).toString()).isEqualTo(expected);
          assertThat(GeigerUrl.parse(expected).toString()).isEqualTo(expected);
        }
      }
    }
  }


  @Test
  public void testEquals() throws MalformedURLException {
    for (String protocol : protocols) {
      for (String plugin : plugins) {
        for (String path : paths) {
          assertThat(new GeigerUrl(protocol, plugin, path))
            .isEqualTo(GeigerUrl.parse(protocol + "://" + plugin + "/" + path));
        }
      }
    }

    GeigerUrl url = GeigerUrl.parse("geiger://plugin/path");
    // Different protocol
    assertThat(url).isNotEqualTo(GeigerUrl.parse("gei-ger://plugin/path"));
    // Different plugin
    assertThat(url).isNotEqualTo(GeigerUrl.parse("geiger://plug-in/path"));
    // Different path
    assertThat(url).isNotEqualTo(GeigerUrl.parse("geiger://plugin/path/something/else"));
  }

  @Test
  public void testHashCode() throws MalformedURLException {
    for (String protocol : protocols) {
      for (String plugin : plugins) {
        for (String path : paths) {
          assertThat(new GeigerUrl(protocol, plugin, path).hashCode())
            .isEqualTo(GeigerUrl.parse(protocol + "://" + plugin + "/" + path).hashCode());
        }
      }
    }

    GeigerUrl url = GeigerUrl.parse("geiger://plugin/path");
    // Different protocol
    assertThat(url.hashCode()).isNotEqualTo(GeigerUrl.parse("gei-ger://plugin/path").hashCode());
    // Different plugin
    assertThat(url.hashCode()).isNotEqualTo(GeigerUrl.parse("geiger://plug-in/path").hashCode());
    // Different path
    assertThat(url.hashCode()).isNotEqualTo(GeigerUrl.parse("geiger://plugin/path/something/else").hashCode());
  }
}
