library geiger_api;

import 'package:geiger_api/src/communication/communication_api.dart';
import 'package:geiger_localstorage/geiger_localstorage.dart';
import 'package:logging/logging.dart';

import 'geiger_url.dart';
import 'message.dart';
import 'message_type.dart';
import 'plugin_listener.dart';

class _CallProcessor {
  final String name;
  final String errorMessage;
  final Future<void Function(ByteSink)?> Function(ByteStream) process;

  _CallProcessor(this.name, this.errorMessage, this.process);
}

class _SerializerCallProcessor extends _CallProcessor {
  _SerializerCallProcessor(String name, String errorMessage,
      Future<Serializer?> Function(ByteStream) processor)
      : super(name, errorMessage, (stream) async {
          var obj = await processor(stream);
          return (sink) => obj?.toByteArrayStream(sink);
        });
}

/// [StorageEventHandler] processes StorageEvents accordingly.
class StorageEventHandler with PluginListener {
  final CommunicationApi _api;
  final StorageController _controller;

  static final Logger log = Logger("GeigerApi");

  final Map<String, _CallProcessor> _processors = {};

  StorageEventHandler(this._api, this._controller) {
    var processors = [
      _SerializerCallProcessor('getNode', 'Could not get node', (stream) async {
        return _controller.get((await SerializerHelper.readString(stream))!);
      }),
      _SerializerCallProcessor(
          'getNodeOrTombstone', 'Could not get node or tombstone',
          (stream) async {
        return _controller
            .getNodeOrTombstone((await SerializerHelper.readString(stream))!);
      }),
      _CallProcessor('addNode', 'Could not add node', (stream) async {
        await _controller.add(await NodeImpl.fromByteArrayStream(stream));
      }),
      _CallProcessor('updateNode', 'Could not update node', (stream) async {
        await _controller.update(await NodeImpl.fromByteArrayStream(stream));
      }),
      _CallProcessor('addOrUpdateNode', 'Could not add or update node',
          (stream) async {
        var updated = await _controller
            .addOrUpdate(await NodeImpl.fromByteArrayStream(stream));
        return (sink) => SerializerHelper.writeInt(sink, updated ? 1 : 0);
      }),
      _SerializerCallProcessor('deleteNode', 'Could not delete node',
          (stream) async {
        return _controller.delete((await SerializerHelper.readString(stream))!);
      }),
      _SerializerCallProcessor('getValue', 'Could not get node value',
          (stream) async {
        return _controller.getValue(
            (await SerializerHelper.readString(stream))!,
            (await SerializerHelper.readString(stream))!);
      }),
      _CallProcessor('addValue', 'Could not add node value', (stream) async {
        await _controller.addValue((await SerializerHelper.readString(stream))!,
            await NodeValueImpl.fromByteArrayStream(stream));
      }),
      _CallProcessor('updateValue', 'Could not update node value',
          (stream) async {
        await _controller.updateValue(
            (await SerializerHelper.readString(stream))!,
            await NodeValueImpl.fromByteArrayStream(stream));
      }),
      _CallProcessor('addOrUpdateValue', 'Could not add or update node value',
          (stream) async {
        var updated = await _controller.addOrUpdateValue(
            (await SerializerHelper.readString(stream))!,
            await NodeValueImpl.fromByteArrayStream(stream));
        return (sink) => SerializerHelper.writeInt(sink, updated ? 1 : 0);
      }),
      _SerializerCallProcessor('deleteValue', 'Could not delete node value',
          (stream) async {
        return _controller.deleteValue(
            (await SerializerHelper.readString(stream))!,
            (await SerializerHelper.readString(stream))!);
      }),
      _CallProcessor('renameNode', 'Could not rename node', (stream) async {
        await _controller.rename((await SerializerHelper.readString(stream))!,
            (await SerializerHelper.readString(stream))!);
      }),
      _CallProcessor('searchNodes', 'Could not search nodes', (stream) async {
        var nodes = await _controller
            .search(await SearchCriteria.fromByteArrayStream(stream));
        return (sink) {
          SerializerHelper.writeInt(sink, nodes.length);
          for (final node in nodes) {
            node.toByteArrayStream(sink);
          }
        };
      }),
      _CallProcessor('close', 'Could not close', (stream) async {
        await _controller.close();
      }),
      _CallProcessor('flush', 'Could not flush', (stream) async {
        await _controller.flush();
      }),
      _CallProcessor('zap', 'Could not zap', (stream) async {
        await _controller.zap();
      }),
      _CallProcessor('dump', 'Could not dump', (stream) async {
        var dump = await _controller.dump(
            (await SerializerHelper.readString(stream))!,
            (await SerializerHelper.readString(stream))!);
        return (sink) => SerializerHelper.writeString(sink, dump);
      })
    ];
    for (var processor in processors) {
      _processors[processor.name] = processor;
    }
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
      final serializer = await processor.process(ByteStream(null, msg.payload));
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
        log.log(Level.SEVERE, 'got unexpected Exception', e);
      }
    }
  }
}
