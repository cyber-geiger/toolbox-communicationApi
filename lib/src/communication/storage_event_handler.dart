library geiger_api;

import 'package:geiger_api/src/communication/communication_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import '../../geiger_api.dart';

class _CallProcessor {
  final String name;
  final String errorMessage;
  final Future<void Function(ByteSink)?> Function(ByteStream, Message) process;

  _CallProcessor(this.name, this.errorMessage, this.process);
}

class _SerializerCallProcessor extends _CallProcessor {
  _SerializerCallProcessor(String name, String errorMessage,
      Future<Serializer?> Function(ByteStream, Message) processor)
      : super(name, errorMessage, (stream, msg) async {
          var obj = await processor(stream, msg);
          return (sink) => obj?.toByteArrayStream(sink);
        });
}

class _LambdaStorageListener extends StorageListener {
  final Function(EventType event, Node? oldNode, Node? newNode) callback;

  _LambdaStorageListener(this.callback);

  @override
  void gotStorageChange(EventType event, Node? oldNode, Node? newNode) {
    callback(event, oldNode, newNode);
  }
}

/// [StorageEventHandler] processes StorageEvents accordingly.
class StorageEventHandler with PluginListener {
  final CommunicationApi _api;
  final StorageController _controller;

  final Map<String, _CallProcessor> _processors = {};

  final Map<String, StorageListener> idToListener = {};

  StorageEventHandler(this._api, this._controller) {
    var processors = [
      _SerializerCallProcessor('getNode', 'Could not get node',
          (stream, _) async {
        return _controller.get((await SerializerHelper.readString(stream))!);
      }),
      _SerializerCallProcessor(
          'getNodeOrTombstone', 'Could not get node or tombstone',
          (stream, _) async {
        return _controller
            .getNodeOrTombstone((await SerializerHelper.readString(stream))!);
      }),
      _CallProcessor('addNode', 'Could not add node', (stream, _) async {
        await _controller.add(await NodeImpl.fromByteArrayStream(stream));
      }),
      _CallProcessor('updateNode', 'Could not update node', (stream, _) async {
        await _controller.update(await NodeImpl.fromByteArrayStream(stream));
      }),
      _CallProcessor('addOrUpdateNode', 'Could not add or update node',
          (stream, _) async {
        var updated = await _controller
            .addOrUpdate(await NodeImpl.fromByteArrayStream(stream));
        return (sink) => SerializerHelper.writeInt(sink, updated ? 1 : 0);
      }),
      _SerializerCallProcessor('deleteNode', 'Could not delete node',
          (stream, _) async {
        return _controller.delete((await SerializerHelper.readString(stream))!);
      }),
      _SerializerCallProcessor('getValue', 'Could not get node value',
          (stream, _) async {
        return _controller.getValue(
            (await SerializerHelper.readString(stream))!,
            (await SerializerHelper.readString(stream))!);
      }),
      _CallProcessor('addValue', 'Could not add node value', (stream, _) async {
        await _controller.addValue((await SerializerHelper.readString(stream))!,
            await NodeValueImpl.fromByteArrayStream(stream));
      }),
      _CallProcessor('updateValue', 'Could not update node value',
          (stream, _) async {
        await _controller.updateValue(
            (await SerializerHelper.readString(stream))!,
            await NodeValueImpl.fromByteArrayStream(stream));
      }),
      _CallProcessor('addOrUpdateValue', 'Could not add or update node value',
          (stream, _) async {
        var updated = await _controller.addOrUpdateValue(
            (await SerializerHelper.readString(stream))!,
            await NodeValueImpl.fromByteArrayStream(stream));
        return (sink) => SerializerHelper.writeInt(sink, updated ? 1 : 0);
      }),
      _SerializerCallProcessor('deleteValue', 'Could not delete node value',
          (stream, _) async {
        return _controller.deleteValue(
            (await SerializerHelper.readString(stream))!,
            (await SerializerHelper.readString(stream))!);
      }),
      _CallProcessor('renameNode', 'Could not rename node', (stream, _) async {
        await _controller.rename((await SerializerHelper.readString(stream))!,
            (await SerializerHelper.readString(stream))!);
      }),
      _CallProcessor('searchNodes', 'Could not search nodes',
          (stream, _) async {
        var nodes = await _controller
            .search(await SearchCriteria.fromByteArrayStream(stream));
        return (sink) {
          SerializerHelper.writeInt(sink, nodes.length);
          for (final node in nodes) {
            node.toByteArrayStream(sink);
          }
        };
      }),
      _CallProcessor('close', 'Could not close', (stream, _) async {
        await _controller.close();
      }),
      _CallProcessor('flush', 'Could not flush', (stream, _) async {
        await _controller.flush();
      }),
      _CallProcessor('zap', 'Could not zap', (stream, _) async {
        await _controller.zap();
      }),
      _CallProcessor('dump', 'Could not dump', (stream, _) async {
        var dump = await _controller.dump(
            (await SerializerHelper.readString(stream))!,
            (await SerializerHelper.readString(stream))!);
        return (sink) => SerializerHelper.writeString(sink, dump);
      }),
      _CallProcessor('registerChangeListener', 'Could not register listener',
          (stream, msg) async {
        var criteria = await SearchCriteria.fromByteArrayStream(stream);

        const uuid = Uuid();
        var id = uuid.v4();
        while (idToListener.containsKey(id)) {
          id = uuid.v4();
        }

        var listener = _LambdaStorageListener((event, oldNode, newNode) =>
            sendChangeEvent(msg.sourceId, id, event, oldNode, newNode));
        idToListener[id] = listener;
        await _controller.registerChangeListener(listener, criteria);

        return (sink) => SerializerHelper.writeString(sink, id);
      }),
      _CallProcessor(
          'deregisterChangeListeners', 'Could not deregister listeners',
          (stream, _) async {
        final listenerCount = await SerializerHelper.readInt(stream);
        final ids = <String>[];
        for (int i = 0; i < listenerCount; i++) {
          ids.add((await SerializerHelper.readString(stream))!);
        }
        final listeners = ids.map((id) => idToListener.remove(id));
        for (final listener in listeners) {
          if (listener == null) continue;
          await _controller.deregisterChangeListener(listener);
        }
      })
    ];
    for (var processor in processors) {
      _processors[processor.name] = processor;
    }
  }

  Future<void> sendChangeEvent(String pluginId, String listenerId,
      EventType event, Node? oldNode, Node? newNode) async {
    var sink = ByteSink();
    SerializerHelper.writeString(sink, listenerId);
    SerializerHelper.writeString(sink, event.toValueString());
    SerializerHelper.writeInt(
        sink, (oldNode != null ? 1 : 0) + (newNode != null ? 2 : 0));
    oldNode?.toByteArrayStream(sink);
    newNode?.toByteArrayStream(sink);
    sink.close();

    await _api.sendMessage(Message(_api.id, pluginId, MessageType.storageEvent,
        GeigerUrl(null, pluginId, 'changeEvent'), await sink.bytes));
  }

  @override
  Future<void> pluginEvent(GeigerUrl? url, Message msg) async {
    String? name = msg.action?.path;
    _CallProcessor? processor = _processors[name];
    if (processor == null) {
      ByteSink sink = ByteSink();
      StorageException('Could not find specified function.')
          .toByteArrayStream(sink);
      sink.close();
      await _api.sendMessage(Message(_api.id, msg.sourceId,
          MessageType.storageError, null, await sink.bytes, msg.requestId));
      return;
    }

    try {
      final serializer =
          await processor.process(ByteStream(null, msg.payload), msg);
      ByteSink? sink;
      if (serializer != null) {
        sink = ByteSink();
        serializer(sink);
        sink.close();
      }
      _api.sendMessage(Message(_api.id, msg.sourceId,
          MessageType.storageSuccess, null, await sink?.bytes, msg.requestId));
    } on Exception catch (e) {
      try {
        ByteSink sink = ByteSink();
        StorageException(processor.errorMessage, null, e)
            .toByteArrayStream(sink);
        sink.close();
        await _api.sendMessage(Message(_api.id, msg.sourceId,
            MessageType.storageError, null, await sink.bytes, msg.requestId));
      } on Exception catch (e) {
        GeigerApi.logger.log(Level.SEVERE, 'got unexpected Exception', e);
      }
    }
  }
}
