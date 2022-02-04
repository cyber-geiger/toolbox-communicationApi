library geiger_api;

import 'dart:async';
import 'dart:io';

import "package:android_intent_plus/android_intent.dart";
import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_api/src/communication/communication_helper.dart';

class PluginStarter {
  static Future<void> startPlugin(PluginInformation pi, bool inBackground) async {
    //TODO(mgwerder): to be implemented at least for android (intent) and Windows (call)
    if(inBackground){
      await startPluginInBackground(pi);
    }else {
      await startPluginInForeground(pi);
    }
  }
  static Future<void> startPluginInForeground(PluginInformation pi) async {
    //expected executable String: "package;component Name;windowsExecutable"
    // example: "com.example;com.example.MainActivity;../../plugin.exe"
    var executables = pi.executable?.split(";");
    var package = executables?.elementAt(0);
    var componentName = executables?.elementAt(1);
    var windowsExecutable = executables?.elementAt(2);
    if (Platform.isAndroid) {
      AndroidIntent intent = AndroidIntent(componentName: componentName,package: package);
      await intent.launch();
    } else if (Platform.isWindows) {
      if (windowsExecutable != null) {
        await Process.run(windowsExecutable, ["/foreground"]);
      }
    } else {
      throw Exception("Platform not yet Supported");
    }
  }
  static Future<void> startPluginInBackground(PluginInformation pi) async {}
}

