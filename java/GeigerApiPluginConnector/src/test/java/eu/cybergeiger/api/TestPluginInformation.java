package eu.cybergeiger.api;

import eu.cybergeiger.api.plugin.CommunicationSecret;
import eu.cybergeiger.api.plugin.PluginInformation;
import org.junit.Assert;
import org.junit.Ignore;
import org.junit.Test;

/**
 * Class to test PluginInformation implementation.
 */
public class TestPluginInformation {
    // working inputs
    int[] ports = new int[]{1025, 1700, 8000, 12500, 44555, 65535};
    String[] executables = new String[]{"thisApplication.jar", "./thisAccplication", "./../path/to/thisApplication", "C:/path to/this/application", "thisApplication.apk"};
    CommunicationSecret[] secrets = new CommunicationSecret[]{new CommunicationSecret(), new CommunicationSecret()};

    @Test
    @Ignore
    public void testConstructorGetter() {
        for (CommunicationSecret secret : secrets) {
            System.out.println(secret.toString());
        }
        for (int port : ports) {
            for (String executable : executables) {
                for (CommunicationSecret secret : secrets) {
                    // Constructor without secret
                    PluginInformation info = new PluginInformation("", executable, port);
                    Assert.assertEquals("checking Executable", executable, info.getExecutable());
                    Assert.assertEquals("checking port", port, info.getPort());
                    Assert.assertNotNull("checking secret", info.getSecret());
                    System.out.println(secret.toString());
                    // Constructor with secret
                    PluginInformation info2 = new PluginInformation("", executable, port, secret);
                    Assert.assertEquals("checking Executable", executable, info.getExecutable());
                    Assert.assertEquals("checking port", port, info.getPort());
                    Assert.assertArrayEquals("checking secret", secret.getSecret(), info.getSecret().getSecret());
                }
            }
        }
    }

    @Test
    public void testHashCode() {
        for (int port : ports) {
            for (String executable : executables) {
                for (CommunicationSecret secret : secrets) {
                    PluginInformation info = new PluginInformation("", executable, port, secret);
                    PluginInformation info2 = new PluginInformation("", executable, port, secret);
                    Assert.assertEquals("checking Hashcode", info.hashCode(), info2.hashCode());
                }
            }
        }
    }

}
