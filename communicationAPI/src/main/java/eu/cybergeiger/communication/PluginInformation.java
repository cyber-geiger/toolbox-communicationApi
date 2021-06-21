package eu.cybergeiger.communication;

import ch.fhnw.geiger.serialization.Serializer;
import ch.fhnw.geiger.serialization.SerializerHelper;
import ch.fhnw.geiger.totalcross.ByteArrayInputStream;
import ch.fhnw.geiger.totalcross.ByteArrayOutputStream;
import java.io.IOException;

/**
 * <p>Object for storing vital plugin information.</p>
 */
public class PluginInformation implements Serializer {

  private static final long serialVersionUID = 48032940912340L;

  private final String executable;
  private final int port;
  private CommunicationSecret secret;

  public PluginInformation(String executable, int port) {
    this(executable, port, null);
  }

  /**
   * <p>Constructor for plugin information.</p>
   *
   * @param executable the string required for platform specific wakeup of a plugin
   * @param port       the port of the plugin to be contacted on
   * @param secret     the secret required for communicating (if null a new secret is generated)
   */
  PluginInformation(String executable, int port, CommunicationSecret secret) {
    this.executable = executable;
    this.port = port;
    this.secret = secret;
    if (this.secret == null) {
      this.secret = new CommunicationSecret();
    }
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

    String executable = SerializerHelper.readString(in);
    int port = SerializerHelper.readInt(in);
    CommunicationSecret secret = CommunicationSecret.fromByteArrayStream(in);

    if (SerializerHelper.readLong(in) != serialVersionUID) {
      throw new ClassCastException();
    }

    return new PluginInformation(executable, port, secret);

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
