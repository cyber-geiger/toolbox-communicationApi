library geiger_api;

import 'dart:io';
import 'plugin_information.dart';
import 'package:android_intent_plus/flag.dart';
import "package:android_intent_plus/android_intent.dart";

class PluginStarter {
  static Future<void> startPlugin(PluginInformation pi) async {
      //TODO(mgwerder): to be implemented at least for android (intent) and Windows (call)
      var executables = pi.executable?.split(";");
      var componentName= executables?.elementAt(0);
      var package = executables?.elementAt(1);
      var windowsExecutabele = executables?.elementAt(2);
      if(Platform.isAndroid){
        AndroidIntent intent = AndroidIntent(
            package: package,
            componentName: componentName
        );
        intent.launch();
      }
      else if(Platform.isWindows){
        if(windowsExecutabele != null){
          Process.run(windowsExecutabele,["/foreground"]);
        }
      }
      else{
        throw Exception("Platform not yet Supported");
      }
    }
  }
