import 'package:flutter/material.dart';
import 'package:geiger_api/geiger_api.dart';

const pluginExecutor = 'com.example.master_app;'
    'com.example.master_app.MainActivity;'
    'TODO;'
    'https://master.cyber-geiger.eu';
const clientPluginId = 'client-plugin';

late GeigerApi api;
final MessageLogger messageLogger = MessageLogger();
final LoadFromStorageState state = LoadFromStorageState();

/// Send Message to Client Plugin
void callClientPlugin(MessageType type) async {
  ///Geiger URL gets passed to Plugin
  final GeigerUrl url = GeigerUrl(null, clientPluginId, 'null');
  Message message = Message(GeigerApi.masterId, clientPluginId, type, url);
  await api.sendMessage(message, clientPluginId);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// init Master and Add Listeners
  api = (await getGeigerApi(pluginExecutor, GeigerApi.masterId))!;
  api.registerListener([MessageType.allEvents], messageLogger);

  runApp(const App());
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
                onPressed: () => callClientPlugin(MessageType.returningControl),
                child: const Text("Call client in foreground")),
            Expanded(child: DebugToolsView(messageLogger, api))
          ],
        ),
      ),
    );
  }
}
