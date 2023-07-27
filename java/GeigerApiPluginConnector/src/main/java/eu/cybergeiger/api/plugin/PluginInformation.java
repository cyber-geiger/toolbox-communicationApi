package eu.cybergeiger.api.plugin;

import eu.cybergeiger.serialization.Serializable;
import eu.cybergeiger.serialization.SerializerHelper;

import java.io.*;
import java.util.Objects;

/**
 * <p>Object for storing vital plugin information.</p>
 */
public class PluginInformation implements Serializable {
  private static final long serialVersionUID = 48032940912340L;

  private final String id;
  private final String executable;
  private final int port;
  private final Declaration declaration;
  private final CommunicationSecret secret;

  /**
   * <p>Constructor for plugin information.</p>
   *
   * @param id          ID of the plugin this information is about
   * @param executable  the string required for platform specific wakeup of a plugin
   * @param port        the port of the plugin to be contacted on
   * @param declaration Declaration how this plugins shares the data it receives.
   */
  public PluginInformation(String id, String executable, int port, Declaration declaration) {
    this(id, executable, port, declaration, null);
  }

  /**
   * <p>Constructor for plugin information.</p>
   *
   * @param id          ID of the plugin this information is about
   * @param executable  the string required for platform specific wakeup of a plugin
   * @param port        the port of the plugin to be contacted on
   * @param declaration Declaration how this plugins shares the data it receives.
   * @param secret      the secret required for communicating (if null a new secret is generated)
   */
  public PluginInformation(String id, String executable, int port, Declaration declaration, CommunicationSecret secret) {
    this.id = id;
    this.executable = executable;
    this.port = port;
    this.declaration = declaration;
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

  public Declaration getDeclaration() {
    return declaration;
  }

  /**
   * <p>The communication secret required for sending securely between two instances.</p>
   *
   * @return the requested secret
   */
  public CommunicationSecret getSecret() {
    return this.secret;
  }

  public PluginInformation withSecret(CommunicationSecret secret) {
    return new PluginInformation(id, executable, port, declaration, secret);
  }

  @Override
  public void toByteArrayStream(OutputStream out) throws IOException {
    SerializerHelper.writeLong(out, serialVersionUID);
    SerializerHelper.writeString(out, id);
    SerializerHelper.writeString(out, executable);
    SerializerHelper.writeInt(out, port);
    SerializerHelper.writeInt(out, declaration.equals(Declaration.DO_NOT_SHARE_DATA) ? 0 : 1);
    secret.toByteArrayStream(out);
    SerializerHelper.writeLong(out, serialVersionUID);
  }

  /**
   * <p>Reads objects from InputStream and stores them in map.</p>
   *
   * @param in InputStream to be used
   * @return the deserialized Storable String
   * @throws IOException if value cannot be read
   */
  public static PluginInformation fromByteArrayStream(InputStream in) throws IOException {
    SerializerHelper.testMarker(in, serialVersionUID);
    String id = SerializerHelper.readString(in);
    String executable = SerializerHelper.readString(in);
    int port = SerializerHelper.readInt(in);
    Declaration declaration = SerializerHelper.readInt(in) == 0
      ? Declaration.DO_NOT_SHARE_DATA
      : Declaration.DO_SHARE_DATA;
    CommunicationSecret secret = CommunicationSecret.fromByteArrayStream(in);
    SerializerHelper.testMarker(in, serialVersionUID);
    return new PluginInformation(id, executable, port, declaration, secret);
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
      return fromByteArrayStream(new ByteArrayInputStream(buf));
    } catch (IOException ioe) {
      ioe.printStackTrace();
      return null;
    }
  }

  @Override
  public int hashCode() {
    return Objects.hash(id, executable, port, declaration, secret);
  }

}
