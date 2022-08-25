import 'package:flutter/material.dart';
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:logging/logging.dart';

import 'main.dart';

class StorageView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => StorageViewState();
}

class StorageViewState extends State<StorageView> {
  final log = Logger('StorageViewStateLogger');

  initTree() async {}

  getNodeChildren(String key) async {
    Node node = await api.storage.getNodeOrTombstone(key);
    Map<String, Node> children = await node.getChildren();
    return children.keys
        .map((k) => TreeNode(content: Text(children[k]!.name), children: []))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Expanded(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TreeView(nodes: [
                TreeNode(
                  content: Text("root2"),
                  children: [
                    TreeNode(content: Text("child21")),
                    TreeNode(content: Text("child22")),
                  ],
                ),
                TreeNode(content: Text(":"), children: [])
              ])
            ]),
      ),
    );
  }
}
