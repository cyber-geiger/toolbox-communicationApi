import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:window_manager/window_manager.dart';

final currentPath = Directory.current.path;
final masterExecutor = 'com.example.master_app;'
    'com.example.master_app.MainActivity;'
    'cd /d $currentPath\\..\\master_app\nstart .\\build\\windows\\runner\\Debug\\master_app.exe;'
    'https://master.cyber-geiger.eu;'
    'cd /d $currentPath\\..\\master_app\nstart .\\build\\windows\\runner\\Debug\\master_app.exe hidden';
final pluginExecutor = 'com.example.client_app;'
    'com.example.client_app.MainActivity;'
    'cd /d $currentPath\nstart .\\build\\windows\\runner\\Debug\\client_app.exe;'
    'https://client.cyber-geiger.eu;'
    'cd /d $currentPath\nstart .\\build\\windows\\runner\\Debug\\client_app.exe hidden';

const pluginId = 'client-plugin';

late GeigerApi api;
final MessageLogger logger = MessageLogger();

///Geiger url received from Master through Message
GeigerUrl? url;

void main(List<String> args) async {
  if (Platform.isWindows && !Directory.current.path.endsWith('client_app')) {
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

  GeigerApi.masterExecutor = masterExecutor;
  api = (await getGeigerApi(pluginExecutor, pluginId))!;
  if (Platform.isWindows) ReturnControlListener(api);
  api.registerListener([MessageType.allEvents], logger);

  // IMPORTANT: register and activate plugin after registering event listeners
  await api.registerPlugin();
  await api.activatePlugin();
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

Future<void> callMasterPlugin(MessageType type) async {
  // Send Message to master
  Message message = Message(pluginId, GeigerApi.masterId, type, null);
  await api.sendMessage(message, GeigerApi.masterId);
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Geiger Client App',
      home: HomePage(title: 'Geiger Client App'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Connected to master.'),
            Expanded(child: DebugToolsView(logger, api)),
            TextButton(
                onPressed: () async {
                  await callMasterPlugin(MessageType.returningControl);
                  if (Platform.isWindows) await windowManager.blur();
                },
                child: const Text("Return Control")),
          ],
        ),
      ),
    );
  }
}
