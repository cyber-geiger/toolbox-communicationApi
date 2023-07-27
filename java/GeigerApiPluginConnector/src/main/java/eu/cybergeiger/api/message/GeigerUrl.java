package eu.cybergeiger.api.message;

import eu.cybergeiger.serialization.Serializable;
import eu.cybergeiger.serialization.SerializerHelper;

import java.io.InputStream;
import java.io.OutputStream;
import java.io.IOException;
import java.net.MalformedURLException;
import java.util.Objects;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * <p>GEIGER communication URL object.</p>
 */
public class GeigerUrl implements Serializable {
  private static final long serialVersionUID = 32411423L;
  public static final String GEIGER_PROTOCOL = "geiger";

  private final String protocol;
  private final String pluginId;
  private final String path;

  private static final Pattern urlPattern = Pattern.compile("(.+?)://([^/]+)/(.*)");

  /**
   * <p>Parse a URL into a GeigerUrl.</p>
   *
   * @param url URL to parse.
   * @throws MalformedURLException If the provided URL is malformed.
   */
  public static GeigerUrl parse(String url) throws MalformedURLException {
    Matcher matcher = urlPattern.matcher(url);
    if (!matcher.matches())
      throw new MalformedURLException("Matcher was unable to match the string \"" + url
        + "\" to regexp " + urlPattern.pattern());
    return new GeigerUrl(matcher.group(1), matcher.group(2), matcher.group(3));
  }

  /**
   * <p>Create a GeigerUrl.</p>
   *
   * @param pluginId the plugin id name, may not be null nor empty
   */
  public GeigerUrl(String pluginId) {
    this(pluginId, "");
  }


  /**
   * <p>Create a GeigerUrl.</p>
   *
   * @param pluginId the plugin id name, may not be null nor empty
   * @param path     the path to call the respective function
   */
  public GeigerUrl(String pluginId, String path) {
    this(GEIGER_PROTOCOL, pluginId, path);
  }

  /**
   * <p>Create a GeigerUrl.</p>
   *
   * @param protocol the protocol name, may not be null nor empty
   * @param pluginId the plugin id name, may not be null nor empty
   * @param path     the path to call the respective function
   */
  public GeigerUrl(String protocol, String pluginId, String path) {
    if (protocol == null)
      throw new IllegalArgumentException("\"protocol\" cannot be null.");
    if (pluginId == null)
      throw new IllegalArgumentException("\"pluginId\" cannot be null.");
    if (path == null)
      throw new IllegalArgumentException("\"path\" cannot be null.");
    if (protocol.isEmpty())
      throw new IllegalArgumentException("\"protocol\" cannot be empty.");
    if (pluginId.isEmpty())
      throw new IllegalArgumentException("\"pluginId\" cannot be empty.");
    this.protocol = protocol;
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
  public void toByteArrayStream(OutputStream out) throws IOException {
    SerializerHelper.writeLong(out, serialVersionUID);
    SerializerHelper.writeString(out, protocol);
    SerializerHelper.writeString(out, pluginId);
    SerializerHelper.writeString(out, path);
    SerializerHelper.writeLong(out, serialVersionUID);
  }

  /**
   * <p>Convert InputStream to GeigerUrl.</p>
   *
   * @param in InputStream to read from
   * @return the converted GeigerUrl
   * @throws IOException if GeigerUrl cannot be read
   */
  public static GeigerUrl fromByteArrayStream(InputStream in) throws IOException {
    if (SerializerHelper.readLong(in) != serialVersionUID)
      throw new ClassCastException();
    GeigerUrl url = new GeigerUrl(
      Objects.requireNonNull(SerializerHelper.readString(in)),
      Objects.requireNonNull(SerializerHelper.readString(in)),
      Objects.requireNonNull(SerializerHelper.readString(in))
    );
    if (SerializerHelper.readLong(in) != serialVersionUID)
      throw new ClassCastException();
    return url;
  }

  @Override
  public boolean equals(Object other) {
    if (this == other) return true;
    if (other == null || getClass() != other.getClass()) return false;
    GeigerUrl url = (GeigerUrl) other;
    return Objects.equals(protocol, url.protocol)
      && Objects.equals(pluginId, url.pluginId)
      && Objects.equals(path, url.path);
  }

  @Override
  public int hashCode() {
    return Objects.hash(protocol, pluginId, path);
  }
}
