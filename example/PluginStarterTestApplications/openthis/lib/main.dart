import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geiger_api/geiger_api.dart';

CommunicationApi? pluginGeiger;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initialzePlugin();
  runApp(const MyApp());
}

Future<void> initialzePlugin() async {
  List<MessageType> allEvents = [MessageType.allEvents];
  pluginGeiger = (await getGeigerApi(
      'com.pleas.openthis;com.pleas.openthis.MainActivity; windowspath.exe',
      'testPlugin',
      Declaration.doShareData))! as CommunicationApi;
  SimpleEventListener pluginListener = SimpleEventListener('plugin');
  await pluginGeiger?.registerListener(allEvents, pluginListener);
  WidgetsBinding.instance?.addObserver(LifecycleEventHandler());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  get _counter{
    return pluginGeiger?.communicator.port ?? 0;
  }

  void _incrementCounter() async {
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'PLUGINNNN',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class SimpleEventListener implements PluginListener {
  List<Message> events = [];

  final String _id;

  SimpleEventListener(this._id);

  @override
  void pluginEvent(GeigerUrl? url, Message msg) {
    events.add(msg);
    //print('## SimpleEventListener "$_id" received event ${msg.type} it currently has: ${events.length.toString()} events');
  }

  List<Message> getEvents() {
    return events;
  }

  @override
  String toString() {
    String ret = '';
    ret += 'Eventlistener "$_id" contains {\r\n';
    getEvents().forEach((element) {
      ret += '  ${element.toString()}\r\n';
    });
    ret += '}\r\n';
    return ret;
  }
}

class LifecycleEventHandler extends WidgetsBindingObserver {

//  @override
//  Future<bool> didPopRoute()

//  @override
//  void didHaveMemoryPressure()

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        await pluginGeiger?.deactivatePlugin();
        break;
      case AppLifecycleState.resumed:
        await pluginGeiger?.activatePlugin();
        break;
    }
  }
}
