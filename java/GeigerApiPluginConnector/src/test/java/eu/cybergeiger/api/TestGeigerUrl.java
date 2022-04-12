package eu.cybergeiger.api;

import static org.junit.Assert.fail;

import java.net.MalformedURLException;

import eu.cybergeiger.api.message.GeigerUrl;
import org.junit.Assert;
import org.junit.Test;

/**
 * Class to test the GeigerUrl implementation.
 */
public class TestGeigerUrl {

    // working strings
    String[] protocols = new String[]{"geiger", "some-protocol", "protocol/subprotocol",
            "protocol°+*ç%&/()=?`èà£!é_:;"};
    String[] plugins = new String[]{"plugin", "some-plugin", "plugin-?!subplugin",
            "plugin°+*ç%&()=?`èà£!é_:;", "plugin?some-plugin+some%path"};
    String[] paths = new String[]{"path", "some-path", "path/subpath", "some/path/to/something",
            "path°+*ç%&/()=?`èà£!é_:;", "path://somepath/subpath", "", null};

    @Test
    public void testSpecConstructor() {
        for (String protocol : protocols) {
            for (String plugin : plugins) {
                for (String path : paths) {
                    GeigerUrl url = new GeigerUrl(protocol + "://" + plugin + "/" + path);
                    Assert.assertEquals("checking protocol", protocol, url.getProtocol());
                    Assert.assertEquals("checking plugin", plugin, url.getPlugin());
                    // handle special case where path = null
                    if (path == null) {
                        path = "";
                    }
                    Assert.assertEquals("checking path", path, url.getPath());
                }
            }
        }
        // Negative tests
        // missing colon
        String protocol = "geiger";
        String plugin = "plugin";
        String path = "path";
        Assert.assertThrows(MalformedURLException.class, () ->
                new GeigerUrl(protocol + "//" + plugin + "/" + path));
        // missing slash
        Assert.assertThrows(MalformedURLException.class, () ->
                new GeigerUrl(protocol + ":/" + plugin + "/" + path));
        // missing protocol
        Assert.assertThrows(MalformedURLException.class, () ->
                new GeigerUrl("://" + plugin + "/" + path));
        // missing plugin + path
        Assert.assertThrows(MalformedURLException.class, () ->
                new GeigerUrl(protocol + "://"));
    }

    @Test
    public void testPluginPathConstructor() {
        String protocol = "geiger";
        for (String plugin : plugins) {
            for (String path : paths) {
                GeigerUrl url = new GeigerUrl(plugin, path);
                Assert.assertEquals("checking protocol", protocol, url.getProtocol());
                Assert.assertEquals("checking plugin", plugin, url.getPlugin());
                // handle special case where path = null
                if (path == null) {
                    path = "";
                }
                Assert.assertEquals("checking path", path, url.getPath());
            }
        }

        // negative tests
        // empty plugin
        String path = "path";
        String longPath = "some/path/to/something";
        Assert.assertThrows(MalformedURLException.class, () -> new GeigerUrl("", path));
        Assert.assertThrows(MalformedURLException.class, () -> new GeigerUrl("", longPath));
        Assert.assertThrows(MalformedURLException.class, () -> new GeigerUrl(null, path));
        Assert.assertThrows(MalformedURLException.class, () -> new GeigerUrl(null, longPath));
    }

    @Test
    public void testProtocolPluginPathConstructor() {
        for (String protocol : protocols) {
            for (String plugin : plugins) {
                for (String path : paths) {
                    GeigerUrl url = new GeigerUrl(protocol, plugin, path);
                    Assert.assertEquals("checking protocol", protocol, url.getProtocol());
                    Assert.assertEquals("checking plugin", plugin, url.getPlugin());
                    // handle special case where path = null
                    if (path == null) {
                        path = "";
                    }
                    Assert.assertEquals("checking path", path, url.getPath());
                }
            }
        }

        // negative tests
        String protocol = "geiger";
        String plugin = "plugin";
        String path = "path";
        // protocol null or empty
        Assert.assertThrows(MalformedURLException.class, () ->
                new GeigerUrl(null, plugin, path));
        Assert.assertThrows(MalformedURLException.class, () ->
                new GeigerUrl("", plugin, path));
        // plugin null or empty
        Assert.assertThrows(MalformedURLException.class, () ->
                new GeigerUrl(protocol, null, path));
        Assert.assertThrows(MalformedURLException.class, () ->
                new GeigerUrl(protocol, "", path));
    }

    @Test
    public void testToString() {
        for (String protocol : protocols) {
            for (String plugin : plugins) {
                for (String path : paths) {
                    GeigerUrl url = new GeigerUrl(protocol, plugin, path);
                    // handle special case where path = null
                    if (path == null) {
                        path = "";
                    }
                    String expectedFormat = protocol + "://" + plugin + "/" + path;
                    Assert.assertEquals("checking toString", expectedFormat, url.toString());

                    GeigerUrl url2 = new GeigerUrl(expectedFormat);
                    Assert.assertEquals("checking toString", expectedFormat, url2.toString());
                }
            }
        }
        // checking toString of constructor without protocol
        for (String plugin : plugins) {
            for (String path : paths) {

                GeigerUrl url = new GeigerUrl(plugin, path);
                // handle special case where path = null
                if (path == null) {
                    path = "";
                }
                String expectedFormat = "geiger://" + plugin + "/" + path;
                Assert.assertEquals("checking toString", expectedFormat, url.toString());
            }
        }
    }


    @Test
    public void testEquals() {
        for (String protocol : protocols) {
            for (String plugin : plugins) {
                for (String path : paths) {
                    GeigerUrl url = new GeigerUrl(protocol, plugin, path);
                    // handle special case where path = null
                    if (path == null) {
                        path = "";
                    }
                    String expectedFormat = protocol + "://" + plugin + "/" + path;
                    GeigerUrl url2 = new GeigerUrl(expectedFormat);
                    Assert.assertEquals(url, url2);
                }
            }
        }
        // checking equals with fixed protocol
        for (String plugin : plugins) {
            for (String path : paths) {

                GeigerUrl url = new GeigerUrl(plugin, path);
                // handle special case where path = null
                if (path == null) {
                    path = "";
                }
                String expectedFormat = "geiger://" + plugin + "/" + path;
                GeigerUrl url2 = new GeigerUrl(expectedFormat);
                Assert.assertEquals(url, url2);
            }
        }
        // Negative tests
        // varying protocol
        GeigerUrl url = new GeigerUrl("geiger://plugin/path");
        GeigerUrl url2 = new GeigerUrl("gei-ger://plugin/path");
        Assert.assertNotEquals(url, url2);
        // varying plugin
        GeigerUrl url3 = new GeigerUrl("geiger://plugin/path");
        GeigerUrl url4 = new GeigerUrl("geiger://plug-in/path");
        Assert.assertNotEquals(url3, url4);
        // varying path
        GeigerUrl url5 = new GeigerUrl("geiger://plugin/path");
        GeigerUrl url6 = new GeigerUrl("geiger://plugin/path/something/else");
        Assert.assertNotEquals(url5, url6);
    }

    @Test
    public void testHashCode() {
        for (String protocol : protocols) {
            for (String plugin : plugins) {
                for (String path : paths) {
                    GeigerUrl url = new GeigerUrl(protocol, plugin, path);
                    // handle special case where path = null
                    if (path == null) {
                        path = "";
                    }
                    String expectedFormat = protocol + "://" + plugin + "/" + path;
                    GeigerUrl url2 = new GeigerUrl(expectedFormat);
                    Assert.assertEquals(url.hashCode(), url2.hashCode());
                }
            }
        }
        // checking equals with fixed protocol
        for (String plugin : plugins) {
            for (String path : paths) {

                GeigerUrl url = new GeigerUrl(plugin, path);
                // handle special case where path = null
                if (path == null) {
                    path = "";
                }
                String expectedFormat = "geiger://" + plugin + "/" + path;
                GeigerUrl url2 = new GeigerUrl(expectedFormat);
                Assert.assertEquals(url.hashCode(), url2.hashCode());
            }
        }
        // Negative tests
        // varying protocol
        GeigerUrl url = new GeigerUrl("geiger://plugin/path");
        GeigerUrl url2 = new GeigerUrl("gei-ger://plugin/path");
        Assert.assertNotEquals(url.hashCode(), url2.hashCode());
        // varying plugin
        GeigerUrl url3 = new GeigerUrl("geiger://plugin/path");
        GeigerUrl url4 = new GeigerUrl("geiger://plug-in/path");
        Assert.assertNotEquals(url.hashCode(), url4.hashCode());
        // varying path
        GeigerUrl url5 = new GeigerUrl("geiger://plugin/path");
        GeigerUrl url6 = new GeigerUrl("geiger://plugin/path/something/else");
        Assert.assertNotEquals(url.hashCode(), url6.hashCode());
    }
}
