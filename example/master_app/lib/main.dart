import 'package:flutter/material.dart';
import 'package:geiger_api/geiger_api.dart';

const pluginExecutor = 'com.example.master_app;'
    'com.example.master_app.MainActivity;'
    'TODO';
const clientPluginId = 'client-plugin';

late GeigerApi api;

void callClientPlugin(MessageType type) async {
  Message message = Message(GeigerApi.masterId, clientPluginId, type, null);
  await api.sendMessage(message, clientPluginId);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  api = (await getGeigerApi(pluginExecutor, GeigerApi.masterId))!;
  await api.registerListener([MessageType.allEvents], EventLogger());
  runApp(const App());
}

class EventLogger implements PluginListener {
  @override
  void pluginEvent(GeigerUrl? url, Message msg) {
    print('## Received message: $msg');
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
          children: <Widget>[
            TextButton(
                onPressed: () => callClientPlugin(MessageType.allEvents),
                child: const Text("Call client in background")),
            TextButton(
                onPressed: () => callClientPlugin(MessageType.returningControl),
                child: const Text("Call client in foreground")),
          ],
        ),
      ),
    );
  }
}
