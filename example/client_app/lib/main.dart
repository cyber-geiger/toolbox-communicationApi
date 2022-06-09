
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

import 'message_logger.dart';

const masterExecutor = 'com.example.master_app;'
    'com.example.master_app.MainActivity;'
    'TODO';
const pluginExecutor = 'com.example.client_app;'
    'com.example.client_app.MainActivity;'
    'TODO';
const pluginId = 'client-plugin';

late GeigerApi api;
final MessageLogger logger = MessageLogger();

///Geiger url recived from Master throug Message
GeigerUrl? url;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GeigerApi.masterExecutor = masterExecutor;
  api = (await getGeigerApi(pluginExecutor, pluginId))!;
  api.registerListener([MessageType.allEvents], logger);

  print("---------- REGISTER & ACTIVATE --------------");
  await api.registerPlugin();
  await api.activatePlugin();
  print("---------- END REGISTER & ACTIVATE--------------");

  runApp(const App());
}

void callMasterPlugin(MessageType type) async {
  /// Save geigerURl in Storage
  if(logger.messages.isNotEmpty) {
    getAndStoreGeigerURLInStorage(logger.messages.last.action);
  }
  // Send Message to master
  Message message = Message(pluginId,GeigerApi.masterId, type, null);
  await api.sendMessage(message, GeigerApi.masterId);

}

/// Save geigerURl in Storage
void getAndStoreGeigerURLInStorage(GeigerUrl? url) async {
  Node node = NodeImpl(":geiger_url_test", GeigerApi.masterId);
  await node.addValue(NodeValueImpl("geigerUrl", url.toString()));
  await api.storage.addOrUpdate(node);
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
            Expanded(child: logger.view()),
            TextButton(
                onPressed: () => callMasterPlugin(MessageType.returningControl),
                child: const Text("Return Control")),
          ],
        ),
      ),
    );
  }
}

