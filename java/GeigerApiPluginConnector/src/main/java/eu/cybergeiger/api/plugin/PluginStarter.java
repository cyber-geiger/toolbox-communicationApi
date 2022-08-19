package eu.cybergeiger.api.plugin;

import java.lang.reflect.Proxy;
import java.util.logging.Level;

import eu.cybergeiger.api.GeigerApi;
import eu.cybergeiger.api.utils.Platform;

public class PluginStarter {
  private static final String SERVICE_NAME = "eu.cybergeiger.communication.GeigerService";

  private static Object context;

  public static void setContext(Object context) {
    PluginStarter.context = context;
  }

  public static void startPlugin(PluginInformation pi, boolean inBackground) {
    String[] executables = pi.getExecutable().split(";");
    String packageName = executables[0];
    String componentName = executables[1];
    String windowsExecutable = executables[2];
    try {
      switch (Platform.getPlatform()) {
        case WINDOWS:
          Runtime.getRuntime().exec(windowsExecutable);
          break;
        case LINUX:
          if (context == null)
            throw new RuntimeException("The required context was not provided yet via \"PluginStart.setContext()\".");
          startAndroidPlugin(packageName, componentName, inBackground);
          break;
        default:
          throw new RuntimeException("Current platform unsupported.");
      }
    } catch (Exception e) {
      GeigerApi.logger.log(
        Level.WARNING,
        "Could not start plugin \"" + pi.getId() + "\"",
        e
      );
    }
  }

  private static Object newNoOpProxy(Class<?> classObject) {
    Object dummy = new Object();
    return Proxy.newProxyInstance(
      classObject.getClassLoader(),
      new Class[]{classObject},
      (proxy, method, args) -> {
        switch (method.getName()) {
          case "hashCode":
            return dummy.hashCode();
          case "equals":
            return proxy == args[0] || args[0].equals(proxy);
          case "toString":
            return "NoOp" + classObject.getSimpleName();
          default:
            return null;
        }
      }
    );
  }

  private static void startAndroidPlugin(String packageName, String componentName, boolean inBackground) throws Exception {
    Class<?> intentClass = Class.forName("android.content.Intent");
    Class<?> componentClass = Class.forName("android.content.ComponentName");
    Class<?> serviceConnectionClass = Class.forName("android.content.ServiceConnection");
    Class<?> contextClass = Class.forName("android.content.Context");

    Object intent = intentClass.newInstance();
    Object component = componentClass
      .getConstructor(String.class, String.class)
      .newInstance(packageName, inBackground ? SERVICE_NAME : componentName);
    intentClass
      .getMethod("setComponent", componentClass)
      .invoke(intent, component);
    if (inBackground) {
      Object connection = newNoOpProxy(serviceConnectionClass);
      int flag = (int) contextClass
        .getField("BIND_AUTO_CREATE")
        .get(null);
      boolean wasSuccessful = (boolean) contextClass
        .getMethod("bindService", intentClass, serviceConnectionClass, int.class)
        .invoke(context, intent, connection, flag);
      if (!wasSuccessful)
        GeigerApi.logger.warning("Was not able to bind GeigerService.");
      // TODO: release binding again
    } else {
      int flag = (int) intentClass
        .getField("FLAG_ACTIVITY_NEW_TASK")
        .get(null);
      intentClass
        .getMethod("addFlags", int.class)
        .invoke(intent, flag);
      contextClass
        .getMethod("startActivity", intentClass)
        .invoke(context, intent);
    }
  }
}
