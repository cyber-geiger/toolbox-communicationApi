library geiger_api;

import 'dart:io';

import "package:android_intent_plus/android_intent.dart";
import 'package:geiger_api/geiger_api.dart';

class PluginStarter {
  static Future<void> startPlugin(PluginInformation pi) async {
    // TODO(mgwerder): write executable spec into communication_api_factory
    //expected executable String: "package;component Name;windowsExecutable"
    // example: "com.example;com.example.MainActivity;../../plugin.exe"
    var executables = pi.executable?.split(";");
    var package = executables?.elementAt(0);
    var componentName = executables?.elementAt(1);
    var windowsExecutable = executables?.elementAt(2);
    if (Platform.isAndroid) {
      AndroidIntent intent =
          AndroidIntent(package: package, componentName: componentName);
      intent.launch();
    } else if (Platform.isWindows) {
      if (windowsExecutable != null) {
        Process.run(windowsExecutable, ["/foreground"]);
      }
    } else {
      throw Exception("Platform not yet Supported");
    }
  }

  static Future<PluginInformation> startPluginInBackground(
      PluginInformation pi, GeigerApi api) async {
    var executables = pi.executable?.split(";");
    var package = executables?.elementAt(0);
    var componentName = executables?.elementAt(1);
    var windowsExecutable = executables?.elementAt(2);

    if (Platform.isAndroid) {
      // send intent
      AndroidIntent intent =
          AndroidIntent(package: package, componentName: componentName);
      intent.launch();
    } else if (Platform.isWindows) {
      if (windowsExecutable != null) {
        Process.run(windowsExecutable, ["/background"]);
      }
    } else {
      throw Exception("Platform not yet Supported");
    }

    // wait for activated message
    // TODO(unassigned)

    // retrieve new pluginInformation
    List<PluginInformation> pin = (await api.getRegisteredPlugins(pi.id));
    if (pin.isEmpty) {
      return pi;
    } else {
      return pin[0];
    }
  }
}
