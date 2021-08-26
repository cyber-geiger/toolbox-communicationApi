package eu.cybergeiger.communication;

import ch.fhnw.geiger.serialization.Serializer;
import ch.fhnw.geiger.serialization.SerializerHelper;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
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
  // pluginId must be unique and must not contain any slashes "/"
  private String pluginId = LocalApi.MASTER;
  private String path = "";

  // at least protocol and plugin must be present
  private static final Pattern urlPattern = Pattern.compile("(.+?)://([^/]+)/(.*)");

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
      this.protocol = m.group(1);
      init(m.group(2), m.group(3));
    } catch (IllegalStateException e) {
      throw new MalformedURLException("Matcher was unable to match the string \"" + spec
          + "\" to regexp " + urlPattern.pattern());
    }
  }

  /**
   * <p>Constructor to create a GEIGER url from id and path.</p>
   *
   * @param pluginId the plugin id name, may not be null nor empty
   * @param path     the path to call the respective function
   * @throws MalformedURLException if the resulting URL is not fulfilling the minimum requirements
   */
  public GeigerUrl(String pluginId, String path) throws MalformedURLException {
    init(pluginId, path);
  }

  /**
   * <p>Constructor to create a GEIGER url from id and path.</p>
   *
   * @param protocol the protocol name, may not be null nor empty
   * @param pluginId the plugin id name, may not be null nor empty
   * @param path     the path to call the respective function
   * @throws MalformedURLException if the resulting URL is not fulfilling the minimum requirements
   */
  public GeigerUrl(String protocol, String pluginId, String path) throws MalformedURLException {
    if (protocol == null || "".equals(protocol)) {
      throw new MalformedURLException("protocol cannot be null nor empty");
    }
    init(pluginId, path);
    this.protocol = protocol;
  }

  private void init(String pluginId, String path) throws MalformedURLException {
    if (pluginId == null || pluginId.equals("")) {
      throw new MalformedURLException("pluginId cannot be null nor empty");
    }
    // in order to reduce null value checks for subsequent access, path will be set to empty string
    if (path == null || "null".equals(path)) {
      path = "";
    }
    this.pluginId = pluginId;
    this.path = path;
  }

  /**
   * <p>Get the string representation of a geiger URL.</p>
   *
   * @return the string representation
   */
  public String toString() {
    return protocol + "://" + pluginId + '/' + path;
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
    if (this == o) {
      return true;
    }
    if (o == null || getClass() != o.getClass()) {
      return false;
    }
    GeigerUrl geigerUrl = (GeigerUrl) o;
    return Objects.equals(protocol, geigerUrl.protocol)
        && Objects.equals(pluginId, geigerUrl.pluginId)
        && Objects.equals(path, geigerUrl.path);
  }

  @Override
  public int hashCode() {
    return Objects.hash(protocol, pluginId, path);
  }
}