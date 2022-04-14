import 'package:flutter/material.dart';
import 'package:geiger_api/geiger_api.dart';

import 'message_logger.dart';

const masterExecutor = 'C:\\Users\\IMVS1807024\\Projects\\toolbox-communicationApi\\example\\master_app\\build\\windows\\runner\\Debug\\master_app.exe;'
    'com.example.master_app.MainActivity;'
    'TODO';
const pluginExecutor = 'C:\\Users\\IMVS1807024\\Projects\\toolbox-communicationApi\\example\\client_app\\build\\windows\\runner\\Debug\\client_app.exe;'
    'com.example.client_app.MainActivity;'
    'TODO';
const pluginId = 'client-plugin';

late GeigerApi api;
final MessageLogger logger = MessageLogger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GeigerApi.masterExecutor = masterExecutor;
  api = (await getGeigerApi(pluginExecutor, pluginId))!;
  api.registerListener([MessageType.allEvents], logger);
  runApp(const App());
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
            Expanded(child: logger.view())
          ],
        ),
      ),
    );
  }
}
