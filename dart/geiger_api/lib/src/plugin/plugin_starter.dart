library geiger_api;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:geiger_api/geiger_api.dart';

import '../communication/geiger_communicator.dart';

class PluginStarter {
  static const MethodChannel _channel =
      MethodChannel('cyber-geiger.eu/communication');

  // Starts a plugin based on its PluginInformation and whether the event is a background event or not
  //
  static Future<void> startPlugin(
      PluginInformation target, bool inBackground, GeigerApi api) async {
        print(target.id);
    // TODO(mgwerder): write executable spec into communication_api_factory
    // expected executable String: "package;component_name;windows_executable"
    final executables = target.executable?.split(';');
    final packageName = executables?.elementAt(0);
    final componentName = executables?.elementAt(1);
    final windowsExecutable = executables?.elementAt(2); // extract the windows executable link from the executor
    String iosUniversalLink = 'NONE'; // extract the ios universal link from the executor

    
    if (Platform.isAndroid) {
      await _channel.invokeMethod('', {
        'package': packageName!,
        'component': componentName!,
        'inBackground': inBackground
      });
    } else if (Platform.isIOS) {
      iosUniversalLink = executables!.elementAt(3);
      if (inBackground) {
          // if target is master
        if (target.id == GeigerApi.masterId) {
          // launch master and then return to the source plugin since its a background message
          await _channel.invokeMethod('url',
              '${GeigerApi.masterUniversalLink}/launchandreturn?redirect=$iosUniversalLink/returningcontrol');
          // wait a bit to prevent a loop, since activate plugin 
          await Future.delayed(CommunicationApi.masterStartWaitTime);
          // after launching the master, try activating the plugin if it has already been registered
          await api.activatePlugin();
        } else {
          // launch target client and return to master since its a background message
          await _channel.invokeMethod('url',
            '$iosUniversalLink/launchandreturn?redirect=${GeigerApi.masterUniversalLink}/returningcontrol');
          }
      } else {
        if (target.id == GeigerApi.masterId) {
          // bring master to foreground
          await _channel.invokeMethod(
              'url', '${GeigerApi.masterUniversalLink}/returningcontrol');
          // try activate the plugin when switching between
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