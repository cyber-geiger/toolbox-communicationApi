package eu.cybergeiger.api.plugin;

import eu.cybergeiger.serialization.Serializable;
import eu.cybergeiger.serialization.SerializerHelper;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;

/**
 * <p>Object for storing vital plugin information.</p>
 */
public class PluginInformation implements Serializable {

  private static final long serialVersionUID = 48032940912340L;

  private final String id;
  private final String executable;
  private final int port;
  private final CommunicationSecret secret;

  public PluginInformation(String id, String executable, int port) {
    this(id, executable, port, null);
  }

  /**
   * <p>Constructor for plugin information.</p>
   *
   * @param id         ID of the plugin this information is about
   * @param executable the string required for platform specific wakeup of a plugin
   * @param port       the port of the plugin to be contacted on
   * @param secret     the secret required for communicating (if null a new secret is generated)
   */
  public PluginInformation(String id, String executable, int port, CommunicationSecret secret) {
    this.id = id;
    this.executable = executable;
    this.port = port;
    this.secret = secret == null ? new CommunicationSecret() : secret;
  }

  public String getId() {
    return this.id;
  }

  /**
   * <p>Gets the port of the plugin.</p>
   *
   * @return the port an active plugin may be reached on
   */
  public int getPort() {
    return this.port;
  }

  /**
   * <p>The executable string required for starting the plugin.</p>
   *
   * @return the executable string
   */
  public String getExecutable() {
    return this.executable;
  }

  /**
   * <p>The communication secret required for sending securely between two instances.</p>
   *
   * @return the requested secret
   */
  public CommunicationSecret getSecret() {
    return this.secret;
  }

  @Override
  public void toByteArrayStream(ByteArrayOutputStream out) throws IOException {
    SerializerHelper.writeLong(out, serialVersionUID);
    SerializerHelper.writeString(out, id);
    SerializerHelper.writeString(out, executable);
    SerializerHelper.writeInt(out, port);
    secret.toByteArrayStream(out);
    SerializerHelper.writeLong(out, serialVersionUID);
  }

  /**
   * <p>Reads objects from ByteArrayInputStream and stores them in map.</p>
   *
   * @param in ByteArrayInputStream to be used
   * @return the deserialized Storable String
   * @throws IOException if value cannot be read
   */
  public static PluginInformation fromByteArrayStream(ByteArrayInputStream in) throws IOException {
    if (SerializerHelper.readLong(in) != serialVersionUID) {
      throw new ClassCastException();
    }
    String id = SerializerHelper.readString(in);
    String executable = SerializerHelper.readString(in);
    int port = SerializerHelper.readInt(in);
    CommunicationSecret secret = CommunicationSecret.fromByteArrayStream(in);
    if (SerializerHelper.readLong(in) != serialVersionUID) {
      throw new ClassCastException();
    }
    return new PluginInformation(id, executable, port, secret);
  }

  /**
   * <p>Wrapper function to simplify serialization.</p>
   *
   * @return the serializer object as byte array
   */
  public byte[] toByteArray() {
    try {
      ByteArrayOutputStream out = new ByteArrayOutputStream();
      toByteArrayStream(out);
      return out.toByteArray();
    } catch (IOException e) {
      return null;
    }
  }

  /**
   * <p>Wrapper function to simplify deserialization.</p>
   *
   * @param buf the buffer to be read
   * @return the deserialized object
   */
  public static PluginInformation fromByteArray(byte[] buf) {
    try {
      ByteArrayInputStream in = new ByteArrayInputStream(buf);
      return fromByteArrayStream(in);
    } catch (IOException ioe) {
      ioe.printStackTrace();
      return null;
    }
  }

  @Override
  public int hashCode() {
    return (executable + ":" + port + ":" + secret.toString()).hashCode();
  }

}
