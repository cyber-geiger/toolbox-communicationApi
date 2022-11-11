import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:window_manager/window_manager.dart';

final currentPath = Directory.current.path;
final pluginExecutor = 'com.example.master_app;'
    'com.example.master_app.MainActivity;'
    'cd /d $currentPath\nstart .\\build\\windows\\runner\\Debug\\master_app.exe;'
    'https://master.cyber-geiger.eu;'
    'cd /d $currentPath\nstart .\\build\\windows\\runner\\Debug\\master_app.exe hidden';
const clientPluginId = 'client-plugin';

late GeigerApi api;
final MessageLogger messageLogger = MessageLogger();
final LoadFromStorageState state = LoadFromStorageState();

/// Send Message to Client Plugin
Future<void> callClientPlugin(MessageType type) async {
  ///Geiger URL gets passed to Plugin
  final GeigerUrl url = GeigerUrl(null, clientPluginId, 'null');
  Message message = Message(GeigerApi.masterId, clientPluginId, type, url);
  await api.sendMessage(message, clientPluginId);
}

void main(List<String> args) async {
  if (Platform.isWindows && !Directory.current.path.endsWith('master_app')) {
    print('App must run in it\'s source code directory.');
    exit(1);
  }
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    if (!(args.isNotEmpty && args.first == 'hidden')) {
      unawaited(
          windowManager.waitUntilReadyToShow(null, () => windowManager.show()));
    }
  }

  /// init Master and Add Listeners
  api = (await getGeigerApi(pluginExecutor, GeigerApi.masterId))!;
  if (Platform.isWindows) ReturnControlListener(api);
  api.registerListener([MessageType.allEvents], messageLogger);

  runApp(const App());
}

class ReturnControlListener extends PluginListener {
  final _type = MessageType.returningControl;

  ReturnControlListener(GeigerApi api) {
    api.registerListener([_type], this);
  }

  @override
  void pluginEvent(GeigerUrl? url, Message msg) {
    if (msg.type != _type) return;
    windowManager.show();
  }
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Geiger Master App',
      home: HomePage(title: 'Geiger Master App'),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: LoadFromStorage());
  }
}

// Flutter statefull Widget to update Text on Storage event
class LoadFromStorage extends StatefulWidget {
  @override
  LoadFromStorageState createState() => LoadFromStorageState();
}

class LoadFromStorageState extends State {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            TextButton(
                onPressed: () => callClientPlugin(MessageType.ping),
                child: const Text("Call client in background")),
            TextButton(
                onPressed: () async {
                  await callClientPlugin(MessageType.returningControl);
                  if (Platform.isWindows) await windowManager.blur();
                },
                child: const Text("Call client in foreground")),
            Expanded(child: DebugToolsView(messageLogger, api))
          ],
        ),
      ),
    );
  }
}
