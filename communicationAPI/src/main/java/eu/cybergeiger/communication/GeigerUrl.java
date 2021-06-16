package eu.cybergeiger.communication;

import ch.fhnw.geiger.serialization.Serializer;
import ch.fhnw.geiger.serialization.SerializerHelper;
import ch.fhnw.geiger.totalcross.ByteArrayInputStream;
import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;
import eu.cybergeiger.totalcross.MalformedUrlException;
import eu.cybergeiger.totalcross.Matcher;
import java.io.IOException;
import java.util.Objects;

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
  private static final Matcher urlPattern = Matcher.compile("(.+?)://([^/]+)/(.*)");

  /**
   * <p>GeigerUrl constructor.</p>
   *
   * @param spec a well formed URI
   * @throws MalformedUrlException if a malformed URL was received
   */
  public GeigerUrl(String spec) throws MalformedUrlException {
    try {
      Matcher m = urlPattern.matcher(spec);
      if (!m.matches()) {
        throw new MalformedUrlException("Matcher was unable to match the string \"" + spec
            + "\" to regexp " + urlPattern.pattern());
      }
      this.protocol = m.group(1);
      init(m.group(2), m.group(3));
    } catch (IllegalStateException e) {
      throw new MalformedUrlException("Matcher was unable to match the string \"" + spec
          + "\" to regexp " + urlPattern.pattern());
    }
  }

  public GeigerUrl(String pluginId, String path) throws MalformedUrlException {
    init(pluginId, path);
  }

  /**
   * Constructor to define every part of a GeigerUrl.
   *
   * @param protocol the name of the protocol
   * @param pluginId the name of the receiving plugin
   * @param path the path denoting the action and any other arguments
   * @throws MalformedUrlException if protocol or plugin is null
   */
  public GeigerUrl(String protocol, String pluginId, String path) throws MalformedUrlException {
    if (protocol == null || "".equals(protocol)) {
      throw new MalformedUrlException("protocol cannot be null nor empty");
    }
    init(pluginId, path);
    this.protocol = protocol;
  }

  private final void init(String pluginId, String path) throws MalformedUrlException {
    if (pluginId == null || pluginId.equals("")) {
      throw new MalformedUrlException("pluginId cannot be null nor empty");
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
