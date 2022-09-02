import 'dart:developer';

import 'package:client_app/second_screen.dart';
import 'package:flutter/material.dart';
import 'package:geiger_api/geiger_api.dart';

const masterExecutor = 'com.example.master_app;'
    'com.example.master_app.MainActivity;'
    'TODO;'
    'https://master.cyber-geiger.eu';
const pluginExecutor = 'com.example.client_app;'
    'com.example.client_app.MainActivity;'
    'TODO;'
    'https://client.cyber-geiger.eu';

const pluginId = 'client-plugin';

late GeigerApi api;
final MessageLogger logger = MessageLogger();

///Geiger url received from Master through Message
GeigerUrl? url;
String geigerURLValue = ''; // To keep track of the data sent by the master app

/// To handle the returning control message from the master app
class PluginEventListener implements PluginListener {
  @override
  void pluginEvent(GeigerUrl? url, Message msg) {
    geigerURLValue =
        '${url.toString()}-${DateTime.now().millisecondsSinceEpoch}'; // Keep track the data sent by the master app - adding the timestamp to diffirenciate between tests
    log('geigerURL: $url');
    log('message: ${msg.toString()}');
    log('Going to a special screen');
    navigatorKey.currentState?.pushNamed(
        '/second-screen'); // GO TO THE SECOND SCREEN ON THE CLIENT APP
  }
}

PluginEventListener returningControlListener = PluginEventListener();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<
    NavigatorState>(); // Special key for navigating without the build context

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GeigerApi.masterExecutor = masterExecutor;
  api = (await getGeigerApi(pluginExecutor, pluginId))!;
  // api.registerListener([MessageType.allEvents], logger);
  api.registerListener([
    MessageType.returningControl
  ], returningControlListener); // Listening to the returning control from the master app

  // IMPORTANT: register and activate plugin after registering event listeners
  await api.registerPlugin();
  await api.activatePlugin();
  runApp(const App());
}

void callMasterPlugin(MessageType type) async {
  // Send Message to master
  Message message = Message(pluginId, GeigerApi.masterId, type, null);
  await api.sendMessage(message, GeigerApi.masterId);
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Geiger Client App',
      // home: HomePage(title: 'Geiger Client App'),
      navigatorKey: navigatorKey,
      routes: {
        '/': (_) => HomePage(
              title: 'Home Page',
            ), // You can also use MaterialApp's `home` property instead of '/'
        '/second-screen': (_) =>
            SecondScreen(), // No way to pass an argument to FooPage.
      },
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
  String receivedData =
      geigerURLValue; // To visualize the value of data sent from the master app
  @override
  Widget build(BuildContext context) {
    if (receivedData.isNotEmpty) {
      return SecondScreen();
    }
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
              onPressed: () => callMasterPlugin(MessageType.returningControl),
              child: const Text("Return Control"),
            ),
            TextButton(
              onPressed: () => navigatorKey.currentState?.pushNamed(
                  '/second-screen'), // Simply testing the navigating to the second screen - manually
              child: const Text("Go to Second Screen"),
            ),
            Text(
                'GeigerURL value: $receivedData'), // Show the data recieved from the master app via returning control event
            TextButton(
              onPressed: () => setState(() {
                receivedData =
                    geigerURLValue; // Manually update the data received from the master app via returning control event
              }),
              child: const Text("Update Received URL"),
            ),
          ],
        ),
      ),
    );
  }
}
