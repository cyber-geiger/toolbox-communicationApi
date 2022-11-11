library geiger_api;

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:path_provider/path_provider.dart';

class PluginStarter {
  static const MethodChannel _channel =
      MethodChannel('cyber-geiger.eu/communication');

  // Starts a plugin based on its PluginInformation and whether the event is a background event or not
  //
  static Future<void> startPlugin(
      PluginInformation target, bool inBackground, GeigerApi api) async {
    // TODO(mgwerder): write executable spec into communication_api_factory
    // Should be
    // 0: <android package name>
    // 1: <android component name>
    // 2: <windows foreground script>
    // 3: <ios link>
    // 4: <windows background script>"
    final executables = target.executable!.split(';');
    if (Platform.isAndroid) {
      await _startPluginAndroid(
          executables.elementAt(0), executables.elementAt(1), inBackground);
    } else if (Platform.isIOS) {
      await _startPluginIos(
          api, target, executables.elementAt(3), inBackground);
    } else if (Platform.isWindows) {
      await _startPluginWindows(
          inBackground ? executables.elementAt(4) : executables.elementAt(2));
    } else {
      throw Exception('Platform not yet Supported');
    }
  }

  static Future<void> _startPluginAndroid(
      String package, String component, bool inBackground) async {
    await _channel.invokeMethod('', {
      'package': package,
      'component': component,
      'inBackground': inBackground
    });
  }

  static Future<void> _startPluginIos(GeigerApi api, PluginInformation target,
      String link, bool inBackground) async {
    // TODO: remove client master differentiation
    if (inBackground) {
      // if target is master
      if (target.id == GeigerApi.masterId) {
        // launch master and then return to the source plugin since its a background message
        await _channel.invokeMethod('url',
            '${GeigerApi.masterUniversalLink}/launchandreturn?redirect=$link/returningcontrol');
        // wait a bit to prevent a loop, since activate plugin
        await Future.delayed(CommunicationApi.masterStartWaitTime);
        // after launching the master, try activating the plugin if it has already been registered
        await api.activatePlugin();
      } else {
        // launch target client and return to master since its a background message
        await _channel.invokeMethod('url',
            '$link/launchandreturn?redirect=${GeigerApi.masterUniversalLink}/returningcontrol');
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
        await _channel.invokeMethod('url', '$link/returningcontrol');
      }
    }
  }

  static Completer? windowsLock;

  static Future<void> _startPluginWindows(String script) async {
    // Temporary batch file is unique to this process.
    // To avoid conflicts this function should not
    // be executed concurrently in the same process.
    while (windowsLock != null) {
      await windowsLock!.future;
    }
    final lock = windowsLock = Completer();

    final tempDir = await getTemporaryDirectory();
    final startFile = File(
        tempDir.path + Platform.pathSeparator + 'start_geiger_plugin_$pid.bat');
    try {
      await startFile.create();
    } catch (_) {}
    await startFile.writeAsString(script);
    await Process.run(
      'explorer.exe',
      [startFile.path],
      runInShell: true,
    );
    // Give explorer time to execute file
    await Future.delayed(const Duration(milliseconds: 500));
    await startFile.delete();

    windowsLock = null;
    lock.complete();
  }
}
