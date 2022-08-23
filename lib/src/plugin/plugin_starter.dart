library geiger_api;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:geiger_api/geiger_api.dart';

class PluginStarter {
  static const MethodChannel _channel =
      MethodChannel('cyber-geiger.eu/communication');

  static Future<void> startPlugin(
      PluginInformation pi, bool inBackground, GeigerApi api) async {
    // TODO(mgwerder): write executable spec into communication_api_factory
    // expected executable String: "package;component_name;windows_executable"
    final executables = pi.executable?.split(';');
    final packageName = executables?.elementAt(0);
    final componentName = executables?.elementAt(1);
    final windowsExecutable = executables?.elementAt(2);
    final iosUniversalLink = executables?.elementAt(3);

    if (Platform.isAndroid) {
      await _channel.invokeMethod('', {
        'package': packageName!,
        'component': componentName!,
        'inBackground': inBackground
      });
    } else if (Platform.isIOS) {
      if (inBackground) {
        if (pi.id == GeigerApi.masterId) {
          // if target is master
          // launch master and then return to the source plugin since its a background message
          await _channel.invokeMethod('url',
              '${GeigerApi.masterUniversalLink}/launchandreturn?redirect=$iosUniversalLink/returningcontrol');
          await api.activatePlugin();
        } else {
          // launch target client and return to master since its a background message
          await _channel.invokeMethod('url',
              '$iosUniversalLink/launchandreturn?redirect=${GeigerApi.masterUniversalLink}/returningcontrol');
        }
      } else {
        if (pi.id == GeigerApi.masterId) {
          // bring master to foreground
          await _channel.invokeMethod(
              'url', '${GeigerApi.masterUniversalLink}/returningcontrol');
          await api.activatePlugin();
        } else {
          // bring target client to foreground
          await _channel.invokeMethod(
              'url', '$iosUniversalLink/returningcontrol');
        }
      }
    } else if (Platform.isWindows) {
      await Process.run(windowsExecutable!, []);
    } else {
      throw Exception('Platform not yet Supported');
    }
  }
}
