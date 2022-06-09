import 'package:flutter/material.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';

import 'main.dart';


class StorageView extends StatefulWidget{
  @override
  StorageViewState createState() => StorageViewState();
}

class StorageViewState extends State {
  changeText(String text) {

    setState(()  {
    });

  }
  getNodes() async {
    String dbDump = await api.storage.dump(":", ";");
    print(dbDump);
    List<String> dumpSplited = dbDump.split(";");
    int elem = 0;
    for (var element in dumpSplited) {
      print(elem++);
      print(element);
    }
  }

  @override
  Widget build(BuildContext context) {
    getNodes();
    return Scaffold(
      body: Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TreeView(nodes: [
              TreeNode(content: Text("root1")),
              TreeNode(
                content: Text("root2"),
                children: [
                  TreeNode(content: Text("child21")),
                  TreeNode(content: Text("child22")),
                  TreeNode(
                    content: Text("root23"),
                    children: [
                      TreeNode(content: Text("child231")),
                    ],
                  ),
                ],
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
