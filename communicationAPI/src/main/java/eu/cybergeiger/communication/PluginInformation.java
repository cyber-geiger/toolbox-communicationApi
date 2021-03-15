package eu.cybergeiger.communication;

import java.io.Serializable;

/**
 * <p>Object for storing vital plugin information.</p>
 */
public class PluginInformation implements Serializable {

  private static final long serialVersionUID = 48032940912340L;

  private String executable;
  private int port;
  private CommunicationSecret secret;

  public PluginInformation(String executable, int port) {
    this(executable,port,null);
  }

  /**
   * <p>Constructor for plugin information.</p>
   *
   * @param executable the string required for platform specific wakeup of a plugin
   * @param port the port of the plugin to be contacted on
   * @param secret the secret required for communicating (if null a new secret is generated)
   */
  public PluginInformation(String executable, int port, CommunicationSecret secret) {
    this.executable = executable;
    this.port = port;
    this.secret = secret;
    if(this.secret==null) {
      this.secret=new CommunicationSecret();
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

}
