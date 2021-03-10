package eu.cybergeiger.communication;

/**
 * <p>The self declaration of the plugin.</p>
 *
 * <p>
 * If a plugin declares data sharing only access to own data is granted. If a plugin declares no sharing full access
 * to all available data is granted.
 * </p>
 */
public enum Declaration {
  DO_NOT_SHARE_DATA("This plugin does not share any device, company, or user related "
      + "data with or without consent to any party within or outside this device."),
  DO_SHARE_DATA("This plugin does share device, company, or user related "
      + "data with consent a other apps or parties within or outside this device.");

  private String declaration;

  Declaration(String declaration) {
    this.declaration = declaration;
  }

  public String getDeclaration() {
    return this.declaration;
  }
}
