import 'package:flutter/material.dart';
import 'package:flutter_treeview/flutter_treeview.dart';
import 'package:geiger_api/geiger_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart' as gls;


class DBTreeView extends StatefulWidget {
  /// RootKey the StartPoint(Top Parent Node)
  late final String rootNodeKey;
  ///Communication api of the app this widget is displayed in
  late final GeigerApi api;
  DBTreeView(this.rootNodeKey, this.api);
  @override
  DBTreeViewState createState() => DBTreeViewState(rootNodeKey,api);
}

class DBTreeViewState extends State {
  late final GeigerApi api;
  late List<Node> nodes;
  late Node rootNode;
  late TreeViewController _controller;
  final ScrollController _firstController =
      ScrollController(initialScrollOffset: 8);

  DBTreeViewState(String rootNodeKey,  this.api){
    ///Init Rootnode
    rootNode = Node(key: rootNodeKey, label: rootNodeKey, data: rootNodeKey, children: []);
  }

  @override
  initState() {
    ///create array with root node and init the TreeViewController
    nodes = [rootNode];
    _controller = TreeViewController(children: nodes);
    ///Load Noadvalue and get children
    updateChildren(rootNode.key);
    super.initState();
  }

  ///Update opend Node(Deskeletonize and load children skeleton nodes
  updateChildren(String key) async {
    Node parentNode = _controller.getNode(key)!;
    gls.Node storageNode =
        await api.storage.getNodeOrTombstone(parentNode.data);
    ///get Children from the StorageNode
    Map<String, gls.Node> children = await storageNode.getChildren();
    ///Preload ChildrensChildren so the node is extandable
    Map<String, List<Node>> childrensChildren =
        await getChildrensChildren(children.keys, storageNode.path);
    ///Map GeigerStorage Node to TreeView Node
    List<Node> childrenNodes = children.keys
        .map((k) => Node(
            key: k,
            label: children[k]!.toString(showChildren: true),
            data: children[k]!.path,
            children: childrensChildren[k]!))
        .toList();
    ///Store Updated Node back in the List
    List<Node> updatedNodeList = _controller.updateNode(
        key, parentNode.copyWith(label: storageNode.toString(showChildren: false),children: childrenNodes));
    setState(() {
      _controller = _controller.copyWith(children: updatedNodeList);
    });
  }

  Future<Map<String, List<Node>>> getChildrensChildren(keys, parentPath) async {
    try {
      ///Map with Parant Key  as Key and Children List
      Map<String, List<Node>> childrensChildren = <String, List<Node>>{};
      for (var key in keys) {
        var path = parentPath + ':' + key;
        if (parentPath == ':') {
          path = parentPath + key;
        }
        gls.Node childParent = await api.storage.getNodeOrTombstone(path);
        Map<String, gls.Node> children = await childParent.getChildren();
        ///Map Children GeigerStorageNodes to TreeView Nodes
        List<Node> childrenNodes = children.keys
            .map((k) =>
                Node(key: k, label: children[k]!.path, data: children[k]!.path))
            .toList();
        ///Store List in Map at with Parant Key as Key
        childrensChildren[key] = childrenNodes;
      }
      return childrensChildren;
    } catch (e) {
      return <String, List<Node>>{};
    }
  }


  ///TODO(MauriceMeier): Filter
  showSensorValues() {}

  showRecomendations() async {
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

  ///Deskeletonize Node with no Children on beeing Taped
  handleNodeTap(String key) async{
    Node node = _controller.getNode(key)!;
    gls.Node storageNode =
        await api.storage.getNodeOrTombstone(node.data);
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
