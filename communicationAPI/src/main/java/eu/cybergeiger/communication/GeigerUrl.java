package eu.cybergeiger.communication;

import ch.fhnw.geiger.serialization.Serializer;
import ch.fhnw.geiger.serialization.SerializerHelper;
import ch.fhnw.geiger.totalcross.ByteArrayInputStream;
import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;
import java.io.IOException;
import java.net.MalformedURLException;
import java.util.Objects;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * <p>GEIGER communication URL object.</p>
 */
public class GeigerUrl implements Serializer {

  private static final long serialVersionUID = 32411423L;

  private String protocol = "geiger";
  private String pluginId = LocalApi.MASTER;
  private String path = "";

  private static final Pattern urlPattern = Pattern.compile("(.*)://([^/]*)/(.*)");

  /**
   * <p>GeigerUrl constructor.</p>
   *
   * @param spec a well formed URI
   * @throws MalformedURLException if a malformed URL was received
   */
  public GeigerUrl(String spec) throws MalformedURLException {
    try {
      Matcher m = urlPattern.matcher(spec);
      if (!m.matches()) {
        throw new MalformedURLException("Matcher was unable to match the string \"" + spec
            + "\" to regexp " + urlPattern.pattern());
      }
      init(m.group(2), m.group(3));
    } catch (IllegalStateException e) {
      throw new MalformedURLException("Matcher was unable to match the string \"" + spec
          + "\" to regexp " + urlPattern.pattern());
    }
  }

  public GeigerUrl(String pluginId, String path) {
    init(pluginId, path);
  }

  public GeigerUrl(String protocol, String pluginId, String path) {
    init(pluginId, path);
    this.protocol = protocol;
  }

  private final void init(String pluginId, String path) {
    this.pluginId = pluginId;
    this.path = path;
  }

  /**
   * <p>Get the string representation of a geiger URL.</p>
   *
   * @return the string representation
   */
  public String toString() {
    StringBuilder sb = new StringBuilder();
    sb.append(protocol).append("://").append(pluginId).append('/').append(path);
    return sb.toString();
  }

  /**
   * <p>Gets the plugin id.</p>
   *
   * @return the plugin id
   */
  public String getPlugin() {
    return pluginId;
  }

  /**
   * <p>Gets the protocol of the URL.</p>
   *
   * @return the protocol prefix
   */
  public String getProtocol() {
    return protocol;
  }

  /**
   * <p>Gets the path part of the URL.</p>
   *
   * @return the path of the URL
   */
  public String getPath() {
    return path;
  }

  @Override
  public void toByteArrayStream(ByteArrayOutputStream out) throws IOException {
    SerializerHelper.writeLong(out, serialVersionUID);
    if (protocol == null) {
      SerializerHelper.writeInt(out, 0);
    } else {
      SerializerHelper.writeInt(out, 1);
      SerializerHelper.writeString(out, protocol);
    }
    if (pluginId == null) {
      SerializerHelper.writeInt(out, 0);
    } else {
      SerializerHelper.writeInt(out, 1);
      SerializerHelper.writeString(out, pluginId);
    }
    if (path == null) {
      SerializerHelper.writeInt(out, 0);
    } else {
      SerializerHelper.writeInt(out, 1);
      SerializerHelper.writeString(out, path);
    }
  }

  /**
   * <p>Convert ByteArrayInputStream to GeigerUrl.</p>
   *
   * @param in ByteArrayInputStream to read from
   * @return the converted GeigerUrl
   * @throws IOException if GeigerUrl cannot be read
   */
  public static GeigerUrl fromByteArrayStream(ByteArrayInputStream in) throws IOException {
    if (SerializerHelper.readLong(in) != serialVersionUID) {
      throw new ClassCastException();
    }
    return new GeigerUrl(
        (SerializerHelper.readInt(in) == 1 ? SerializerHelper.readString(in) : null),
        (SerializerHelper.readInt(in) == 1 ? SerializerHelper.readString(in) : null),
        (SerializerHelper.readInt(in) == 1 ? SerializerHelper.readString(in) : null)
    );
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    GeigerUrl geigerUrl = (GeigerUrl) o;
    return Objects.equals(protocol, geigerUrl.protocol) && Objects.equals(pluginId, geigerUrl.pluginId) && Objects.equals(path, geigerUrl.path);
  }

  @Override
  public int hashCode() {
    return Objects.hash(protocol, pluginId, path);
  }
}
