library geiger_api;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:geiger_api/geiger_api.dart';

class PluginStarter {
  static const MethodChannel _channel =
      MethodChannel('cyber-geiger.eu/communication');

  static Future<void> startPlugin(
      PluginInformation pi, bool inBackground) async {
    // TODO(mgwerder): write executable spec into communication_api_factory
    // expected executable String: "package;component_name;windows_executable"
    final executables = pi.executable?.split(';');
    final packageName = executables?.elementAt(0);
    final componentName = executables?.elementAt(1);
    final windowsExecutable = executables?.elementAt(2);
    if (Platform.isAndroid) {
      await _channel.invokeMethod('', {
        'package': packageName!,
        'component': componentName!,
        'inBackground': inBackground
      });
    } else if (Platform.isWindows) {
      await Process.run(windowsExecutable!, []);
    } else {
      throw Exception('Platform not yet Supported');
    }
  }
}
