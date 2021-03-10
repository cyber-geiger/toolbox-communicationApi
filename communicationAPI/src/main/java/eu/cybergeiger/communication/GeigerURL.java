package eu.cybergeiger.communication;

import java.io.Serializable;
import java.net.MalformedURLException;
import java.net.URL;

/**
 * <p>GEIGER communication URL object</p>
 */
public class GeigerURL implements Serializable {

  private String protocol = "geiger";
  private String pluginId = LocalApi.MASTER;
  private String path = "";

  public GeigerURL(String spec) throws MalformedURLException {
    URL url = new URL(spec);
    init(url.getHost(), url.getPath());
  }

  public GeigerURL(String pluginId, String path) {
    init(pluginId, path);
  }

  private final void init(String pluginId, String path) {
    this.pluginId = pluginId;
    this.path = path;
  }

  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append(protocol).append("://").append(pluginId).append('/').append(path);
    return sb.toString();
  }

  public String getPlugin() {
    return pluginId;
  }

  public String getProtocol() {
    return protocol;
  }

  public String getPath() {
    return path;
  }
}
