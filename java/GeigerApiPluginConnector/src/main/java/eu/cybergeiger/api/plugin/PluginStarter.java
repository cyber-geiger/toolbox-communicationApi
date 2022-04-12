package eu.cybergeiger.api.plugin;

public class PluginStarter {

  public static void startPlugin(PluginInformation pi, boolean inBackground) {
    // TODO(mgwerder): write executable spec into communication_api_factory
    // expected executable String: "package;component_name;windows_executable"
    String[] executables = pi.getExecutable().split(";");
    String packageName = null;
    String componentName = null;
    String windowsExecutable = null;
    try {
      packageName = executables[0];
      componentName = executables[1];
      windowsExecutable = executables[2];
    } catch (Exception ignored) {
    }
    // TODO: add windows and android support
    throw new RuntimeException("Platform not yet supported.");
  }

}
