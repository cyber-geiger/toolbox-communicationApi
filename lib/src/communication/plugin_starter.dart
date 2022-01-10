library geiger_api;

import 'dart:io';
import 'plugin_information.dart';
import 'package:android_intent_plus/flag.dart';
import "package:android_intent_plus/android_intent.dart";

class PluginStarter {
  static Future<void> startPlugin(PluginInformation pi) async {
    //TODO(mgwerder): to be implemented at least for android (intent) and Windows (call)
    //expected executable String: "package;component Name;windowsExecutable"
    // example: "com.example;com.example.MainActivity;../../plugin.exe"
    var executables = pi.executable?.split(";");
    var package= executables?.elementAt(0);
    var componentName = executables?.elementAt(1);
    var windowsExecutable = executables?.elementAt(2);
    if(Platform.isAndroid){
      AndroidIntent intent = AndroidIntent(
          package: package,
          componentName: componentName
      );
      intent.launch();
    }
    else if(Platform.isWindows){
      if(windowsExecutable != null){
        Process.run(windowsExecutable,["/foreground"]);
      }
    }
    else{
      throw Exception("Platform not yet Supported");
    }
  }
  static Future<void> startPluginInBackground(PluginInformation pi) async {

  }
}

