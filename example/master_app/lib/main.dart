

import 'package:flutter/material.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';


import 'message_logger.dart';

const pluginExecutor = 'com.example.master_app;'
    'com.example.master_app.MainActivity;'
    'TODO';
const clientPluginId = 'client-plugin';

late GeigerApi api;
final MessageLogger logger = MessageLogger();
final loadFromStorageState state = loadFromStorageState();
final SimpleStorageListener storageListener = SimpleStorageListener("stoargeListener", state);

void callClientPlugin(MessageType type) async {
  final GeigerUrl url = GeigerUrl(null, clientPluginId, 'null');
  Message message = Message(GeigerApi.masterId, clientPluginId, type, url);
  await api.sendMessage(message, clientPluginId);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  api = (await getGeigerApi(pluginExecutor, GeigerApi.masterId))!;
  api.registerListener([MessageType.allEvents], logger);
  api.registerListener([MessageType.storageEvent], storageListener);
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
      body: loadFromStorage()
    );
  }
}

class loadFromStorage extends StatefulWidget{
  loadFromStorageState createState() => state;
}

class SimpleStorageListener implements PluginListener {

  final String _id;
  final loadFromStorageState _state;

  SimpleStorageListener(this._id, this._state);

  @override
  Future<void> pluginEvent(GeigerUrl? url, Message msg) async {
    if(msg.type == MessageType.storageEvent){
      Node node = await api.storage.get(":geiger_url_test");
      String? nodeValue = (await node.getValue("geigerURL"))?.value;
      if(nodeValue!=null){
        _state.changeText(nodeValue);
      }
    }
  }
}

class loadFromStorageState extends State {

  String textHolder = "not Loaded From Storage";

  changeText(String text) {

    setState(()  {
      textHolder = text;
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(textHolder),
            TextButton(
                onPressed: () => callClientPlugin(MessageType.ping),
                child: const Text("Call client in background")),
            TextButton(
                onPressed: () => callClientPlugin(MessageType.returningControl),
                child: const Text("Call client in foreground")),
            Expanded(child: logger.view())
          ],
        ),
      ),
    );
  }
}
