import 'package:flutter/material.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart' as gls;
import 'package:logging/logging.dart';


class StorageView extends StatefulWidget {
  late final String rootNodeKey;
  late final GeigerApi api;
  StorageView(this.rootNodeKey, this.api);
  @override
  StorageViewState createState() => StorageViewState(rootNodeKey,api);
}

class StorageViewState extends State {
  late final GeigerApi api;
  late List<Node> nodes;
  late Node rootNode;
  late TreeViewController _controller;
  final ScrollController _firstController =
      ScrollController(initialScrollOffset: 8);

  StorageViewState(String rootNodeKey, this.api){
    rootNode = Node(key: rootNodeKey, label: rootNodeKey, data: rootNodeKey, children: []);
  }

  @override
  initState() {
    nodes = [rootNode];
    _controller = TreeViewController(children: nodes);
    updateChildren(rootNode.key);
    super.initState();
  }

  updateChildren(String key) async {
    Node parentNode = _controller.getNode(key)!;
    gls.Node storageNode =
        await api.storage.getNodeOrTombstone(parentNode.data);
    print(await storageNode.getValues());
    Map<String, gls.Node> children = await storageNode.getChildren();
    Map<String, List<Node>> childrensChildren =
        await getChildrensChildren(children.keys, storageNode.path);
    List<Node> childrenNodes = children.keys
        .map((k) => Node(
            key: k,
            label: children[k]!.toString(showChildren: false),
            data: children[k]!.path,
            children: childrensChildren[k]!))
        .toList();
    List<Node> updatedNodeList = _controller.updateNode(
        key, parentNode.copyWith(label: storageNode.toString(showChildren: false),children: childrenNodes));
    setState(() {
      _controller = _controller.copyWith(children: updatedNodeList);
    });
  }

  Future<Map<String, List<Node>>> getChildrensChildren(keys, parentPath) async {
    try {
      Map<String, List<Node>> childrensChildren = <String, List<Node>>{};
      for (var key in keys) {
        var path = parentPath + ':' + key;
        if (parentPath == ':') {
          path = parentPath + key;
        }
        gls.Node childParent = await api.storage.getNodeOrTombstone(path);
        Map<String, gls.Node> children = await childParent.getChildren();
        List<Node> childrenNodes = children.keys
            .map((k) =>
                Node(key: k, label: children[k]!.path, data: children[k]!.path))
            .toList();
        childrensChildren[key] = childrenNodes;
      }
      return childrensChildren;
    } catch (e) {
      return <String, List<Node>>{};
    }
  }

  showSensorValues() {}

  showRecomendations() async {
    print("heyoo");
    gls.Node recomandations =
        await api.storage.getNodeOrTombstone(':Global:Recommendations');
    Map<String, gls.Node> childrenNodes = await recomandations.getChildren();
    List<Node> children = childrenNodes.keys
        .map((k) => Node(key: k, label: k, data: childrenNodes[k]!.path))
        .toList();
    Node recomandationNode = Node(
        key: recomandations.name,
        label: recomandations.path,
        data: recomandations.path,
        children: children);
    nodes = [recomandationNode];
    setState(() {
      _controller = _controller.copyWith(children: nodes);
    });
  }

  handleNodeTap(String key) async{
    Node node = _controller.getNode(key)!;
    gls.Node storageNode =
        await api.storage.getNodeOrTombstone(node.data);
    print(await storageNode.getValues());
    List<Node> updatedNodeList = _controller.updateNode(
        key, node.copyWith(label: storageNode.toString(showChildren: false)));
    setState(() {
      _controller = _controller.copyWith(children: updatedNodeList);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(5.0),
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(5)),
      child: Column(
        children: [
          Container(
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    showRecomendations();
                  },
                  child: const Text('Recomendations'),
                ),
                ElevatedButton(
                  onPressed: () {
                    showSensorValues();
                  },
                  child: const Text('Sensore Values'),
                ),
                ElevatedButton(
                  onPressed: () {
                    initState();
                  },
                  child: const Text('Whole DB'),
                ),
              ],
            ),
          ),
          Flexible(
            child: Scrollbar(
              thumbVisibility: true,
              controller: _firstController,
              child: TreeView(
                 controller: _controller,
                shrinkWrap: true,
                onNodeTap: (key) {
                  handleNodeTap(key);
                },
                onExpansionChanged: (key, state) {
                  updateChildren(key);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
