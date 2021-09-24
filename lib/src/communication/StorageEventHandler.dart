
import 'java.dart';
/// StorageEventHandler processes StorageEvents accordingly.
/// the GeigerUrl of a response has the form protocol://targetId/command/identifier/result
/// where result is either success or error in all cases
class StorageEventHandler with PluginListener
{
    final LocalApi localApi;
    final ch_fhnw_geiger_localstorage_StorageController storageController;
    bool isMaster = false;
    StorageEventHandler(LocalApi api, ch_fhnw_geiger_localstorage_StorageController sc)
    {
        this.localApi = api;
        this.storageController = sc;
    }

    /// <p>Decides which storage method has been called.</p>
    /// @param msg the received message to process
    void storageEventParser(Message msg)
    {
        if (LocalApi_.MASTER == msg.getTargetId()) {
            isMaster = true;
        }
        List<String> urlParts = msg.getAction().getPath().split("/");
        String action = urlParts[0];
        String identifier = urlParts[1];
        List<String> optionalArgs = Arrays.copyOfRange(urlParts, 2, urlParts.length);
        switch (action) {
            case "getNode":
                getNode(msg, identifier, optionalArgs);
                break;
            case "addNode":
                addNode(msg, identifier, optionalArgs);
                break;
            case "updateNode":
                updateNode(msg, identifier, optionalArgs);
                break;
            case "removeNode":
                deleteNode(msg, identifier, optionalArgs);
                break;
            case "getValue":
                getValue(msg, identifier, optionalArgs);
                break;
            case "addValue":
                addValue(msg, identifier, optionalArgs);
                break;
            case "updateValue":
                updateValue(msg, identifier, optionalArgs);
                break;
            case "removeValue":
                deleteValue(msg, identifier, optionalArgs);
                break;
            case "rename":
                rename(msg, identifier, optionalArgs);
                break;
            case "search":
                search(msg, identifier, optionalArgs);
                break;
            case "registerChangeListener":
                registerChangeListener(msg, identifier, optionalArgs);
                break;
            case "close":
                close(msg, identifier, optionalArgs);
                break;
            case "flush":
                flush(msg, identifier, optionalArgs);
                break;
            case "zap":
                zap(msg, identifier, optionalArgs);
                break;
            default:
                break;
        }
    }

    static String join(String delimiter, List<String> args)
    {
        StringBuilder ret = new StringBuilder();
        for (String arg in args) {
            if (ret.length > 0) {
                ret.append(delimiter);
            }
            ret.append(arg);
        }
        return ret.toString();
    }

    /// Calls getNode on the GenericController and sends the Node back to the caller.
    /// @param msg          received message to process
    /// @param identifier   used to identify return objects inside the caller
    /// @param optionalArgs string arguments used for the called method
    void getNode(Message msg, String identifier, List<String> optionalArgs)
    {
        String path = join("/", optionalArgs);
        try {
            ch_fhnw_geiger_localstorage_db_data_Node node = storageController.get(path);
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
            node.toByteArrayStream(bos);
            List<int> payload = bos.toByteArray();
            localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(), MessageType.STORAGE_SUCCESS, new GeigerUrl(msg.getSourceId(), (("getNode/" + identifier) + "/") + path), payload));
        } on java_io_IOException catch (e) {
            try {
                ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
                new ch_fhnw_geiger_localstorage_StorageException("Could not get Node" + path, e).toByteArrayStream(bos);
                List<int> payload = bos.toByteArray();
                localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(), MessageType.STORAGE_ERROR, new GeigerUrl(msg.getSourceId(), "getNode/" + identifier), payload));
            } on java_io_IOException catch (ioe) {
            }
        }
    }

    /// Calls addNode on the GenericController or throws StorageException.
    /// @param msg          received message to process
    /// @param identifier   used to identify return objects inside the caller
    /// @param optionalArgs string arguments used for the called method
    void addNode(Message msg, String identifier, List<String> optionalArgs)
    {
        ch_fhnw_geiger_localstorage_db_data_Node node;
        try {
            node = NodeImpl.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(msg.getPayload()));
            storageController.add(node);
        } on Exception catch (e) {
            try {
                ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
                new ch_fhnw_geiger_localstorage_StorageException("Could not add Node", e).toByteArrayStream(bos);
                List<int> payload = bos.toByteArray();
                localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(), MessageType.STORAGE_ERROR, new GeigerUrl(msg.getSourceId(), "addNode/" + identifier), payload));
            } on java_io_IOException catch (ioe) {
            }
        }
    }

    /// Calls updateNode on the GenericController or throws StorageException.
    /// @param msg          received message to process
    /// @param identifier   used to identify return objects inside the caller
    /// @param optionalArgs string arguments used for the called method
    void updateNode(Message msg, String identifier, List<String> optionalArgs)
    {
        ch_fhnw_geiger_localstorage_db_data_Node node;
        try {
            node = NodeImpl.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(msg.getPayload()));
            storageController.update(node);
        } on Exception catch (e) {
            try {
                ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
                new ch_fhnw_geiger_localstorage_StorageException("Could not update Node", e).toByteArrayStream(bos);
                List<int> payload = bos.toByteArray();
                localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(), MessageType.STORAGE_ERROR, new GeigerUrl(msg.getSourceId(), "updateNode/" + identifier), payload));
            } on java_io_IOException catch (ioe) {
            }
        }
    }

    /// Calls removeNode on the GenericController and sends the Node back to the caller.
    /// @param msg          received message to process
    /// @param identifier   used to identify return objects inside the caller
    /// @param optionalArgs string arguments used for the called method
    void deleteNode(Message msg, String identifier, List<String> optionalArgs)
    {
        try {
            ch_fhnw_geiger_localstorage_db_data_Node node = storageController.delete(optionalArgs[0]);
            if (node != null) {
                ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
                node.toByteArrayStream(bos);
                List<int> payload = bos.toByteArray();
                localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(), MessageType.STORAGE_SUCCESS, new GeigerUrl(msg.getTargetId(), "deleteNode/" + identifier), payload));
            } else {
                localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(), MessageType.STORAGE_SUCCESS, new GeigerUrl(msg.getTargetId(), "deleteNode/" + identifier)));
            }
        } on Exception catch (e) {
            try {
                ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
                new ch_fhnw_geiger_localstorage_StorageException("Could not delete Node", e).toByteArrayStream(bos);
                List<int> payload = bos.toByteArray();
                localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(), MessageType.STORAGE_ERROR, new GeigerUrl(msg.getSourceId(), "deleteNode/" + identifier), payload));
            } on java_io_IOException catch (ioe) {
            }
        }
    }

    /// Calls getValue on the GenericController and sends the NodeValue back to the caller.
    /// @param msg          received message to process
    /// @param identifier   used to identify return objects inside the caller
    /// @param optionalArgs string arguments used for the called method
    void getValue(Message msg, String identifier, List<String> optionalArgs)
    {
        try {
            ch_fhnw_geiger_localstorage_db_data_NodeValue nodeValue = storageController.getValue(optionalArgs[0], optionalArgs[1]);
            if (nodeValue != null) {
                ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
                nodeValue.toByteArrayStream(bos);
                List<int> payload = bos.toByteArray();
                localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(), MessageType.STORAGE_SUCCESS, new GeigerUrl(msg.getTargetId(), "getValue/" + identifier), payload));
            } else {
                localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(), MessageType.STORAGE_SUCCESS, new GeigerUrl(msg.getTargetId(), "getValue/" + identifier)));
            }
        } on Exception catch (e) {
            try {
                ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
                new ch_fhnw_geiger_localstorage_StorageException("Could not get NodeValue", e).toByteArrayStream(bos);
                List<int> payload = bos.toByteArray();
                localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(), MessageType.STORAGE_ERROR, new GeigerUrl(msg.getSourceId(), "getValue/" + identifier), payload));
            } on java_io_IOException catch (ioe) {
            }
        }
    }

    /// Calls addValue on the GenericController or throws StorageException.
    /// @param msg          received message to process
    /// @param identifier   used to identify return objects inside the caller
    /// @param optionalArgs string arguments used for the called method
    void addValue(Message msg, String identifier, List<String> optionalArgs)
    {
        ch_fhnw_geiger_localstorage_db_data_NodeValue nodeValue;
        try {
            nodeValue = NodeValueImpl.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(msg.getPayload()));
            storageController.addValue(optionalArgs[0], nodeValue);
        } on Exception catch (e) {
            try {
                ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
                new ch_fhnw_geiger_localstorage_StorageException("Could not add NodeValue", e).toByteArrayStream(bos);
                List<int> payload = bos.toByteArray();
                localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(), MessageType.STORAGE_ERROR, new GeigerUrl(msg.getSourceId(), "addValue/" + identifier), payload));
            } on java_io_IOException catch (ioe) {
            }
        }
    }

    /// UpdateValue on the GenericController or throws StorageException.
    /// @param msg          received message to process
    /// @param identifier   used to identify return objects inside the caller
    /// @param optionalArgs string arguments used for the called method
    void updateValue(Message msg, String identifier, List<String> optionalArgs)
    {
        ch_fhnw_geiger_localstorage_db_data_NodeValue nodeValue;
        try {
            nodeValue = NodeValueImpl.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(msg.getPayload()));
            storageController.updateValue(optionalArgs[0], nodeValue);
        } on Exception catch (e) {
            try {
                ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
                new ch_fhnw_geiger_localstorage_StorageException("Could not update NodeValue", e).toByteArrayStream(bos);
                List<int> payload = bos.toByteArray();
                localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(), MessageType.STORAGE_ERROR, new GeigerUrl(msg.getSourceId(), "updateValue/" + identifier), payload));
            } on java_io_IOException catch (ioe) {
            }
        }
    }

    /// Either calls removeValue on the GenericController and sends the NodeValue back to the caller,
    /// or stores the received NodeValue in the storageEventObject map.
    /// @param msg          received message to process
    /// @param identifier   used to identify return objects inside the caller
    /// @param optionalArgs string arguments used for the called method
    void deleteValue(Message msg, String identifier, List<String> optionalArgs)
    {
        try {
            ch_fhnw_geiger_localstorage_db_data_NodeValue nodeValue = storageController.deleteValue(optionalArgs[0], optionalArgs[1]);
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
            nodeValue.toByteArrayStream(bos);
            List<int> payload = bos.toByteArray();
            localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(), MessageType.STORAGE_SUCCESS, new GeigerUrl(msg.getTargetId(), "deleteNodeValue/" + identifier), payload));
        } on Exception catch (e) {
            try {
                ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
                new ch_fhnw_geiger_localstorage_StorageException("Could not delete NodeValue", e).toByteArrayStream(bos);
                List<int> payload = bos.toByteArray();
                localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(), MessageType.STORAGE_ERROR, new GeigerUrl(msg.getSourceId(), "deleteValue/" + identifier), payload));
            } on java_io_IOException catch (ioe) {
            }
        }
    }

    /// Calls rename on the GenericController or throws StorageException.
    /// @param msg          received message to process
    /// @param identifier   used to identify return objects inside the caller
    /// @param optionalArgs string arguments used for the called method
    void rename(Message msg, String identifier, List<String> optionalArgs)
    {
        try {
            storageController.rename(optionalArgs[0], optionalArgs[1]);
        } on ch_fhnw_geiger_localstorage_StorageException catch (e) {
            try {
                ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
                new ch_fhnw_geiger_localstorage_StorageException("Could not rename Node", e).toByteArrayStream(bos);
                List<int> payload = bos.toByteArray();
                localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(), MessageType.STORAGE_ERROR, new GeigerUrl(msg.getSourceId(), "rename/" + identifier), payload));
            } on java_io_IOException catch (ioe) {
            }
        }
    }

    /// Calls search on the GenericController and sends the List of Nodes back to the caller.
    /// @param msg          received message to process
    /// @param identifier   used to identify return objects inside the caller
    /// @param optionalArgs string arguments used for the called method
    void search(Message msg, String identifier, List<String> optionalArgs)
    {
        try {
            ch_fhnw_geiger_localstorage_SearchCriteria searchCriteria = SearchCriteria_.fromByteArray(msg.getPayload());
            java_util_List<Node> nodes = storageController.search(searchCriteria);
            if (nodes.size() > 0) {
                List<int> payload;
                ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
                for (ch_fhnw_geiger_localstorage_db_data_Node n in nodes) {
                    n.toByteArrayStream(bos);
                }
                payload = bos.toByteArray();
                localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(), MessageType.STORAGE_SUCCESS, new GeigerUrl(msg.getTargetId(), "search/" + identifier), payload));
            } else {
                localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(), MessageType.STORAGE_SUCCESS, new GeigerUrl(msg.getTargetId(), "search/" + identifier)));
            }
        } on Exception catch (e) {
            try {
                ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
                new ch_fhnw_geiger_localstorage_StorageException("Could not search Node", e).toByteArrayStream(bos);
                List<int> payload = bos.toByteArray();
                localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(), MessageType.STORAGE_ERROR, new GeigerUrl(msg.getSourceId(), "search/" + identifier), payload));
            } on java_io_IOException catch (ioe) {
            }
        }
    }

    /// Calls close on the GenericController or throws StorageException.
    /// @param msg          received message to process
    /// @param identifier   used to identify return objects inside the caller
    /// @param optionalArgs string arguments used for the called method
    void close(Message msg, String identifier, List<String> optionalArgs)
    {
        try {
            storageController.close();
        } on ch_fhnw_geiger_localstorage_StorageException catch (e) {
            try {
                ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
                new ch_fhnw_geiger_localstorage_StorageException("Could not close", e).toByteArrayStream(bos);
                List<int> payload = bos.toByteArray();
                localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(), MessageType.STORAGE_ERROR, new GeigerUrl(msg.getSourceId(), "close/" + identifier), payload));
            } on java_io_IOException catch (ioe) {
            }
        }
    }

    /// Calls flush on the GenericController or throws StorageException.
    /// @param msg          received message to process
    /// @param identifier   used to identify return objects inside the caller
    /// @param optionalArgs string arguments used for the called method
    void flush(Message msg, String identifier, List<String> optionalArgs)
    {
        try {
            storageController.flush();
        } on ch_fhnw_geiger_localstorage_StorageException catch (e) {
            try {
                ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
                new ch_fhnw_geiger_localstorage_StorageException("Could not flush", e).toByteArrayStream(bos);
                List<int> payload = bos.toByteArray();
                localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(), MessageType.STORAGE_ERROR, new GeigerUrl(msg.getSourceId(), "flush/" + identifier), payload));
            } on java_io_IOException catch (ioe) {
            }
        }
    }

    /// Calls zap on the GenericController or throws StorageException.
    /// @param msg          received message to process
    /// @param identifier   used to identify return objects inside the caller
    /// @param optionalArgs string arguments used for the called method
    void zap(Message msg, String identifier, List<String> optionalArgs)
    {
        try {
            storageController.zap();
        } on ch_fhnw_geiger_localstorage_StorageException catch (e) {
            try {
                ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
                new ch_fhnw_geiger_localstorage_StorageException("Could not zap", e).toByteArrayStream(bos);
                List<int> payload = bos.toByteArray();
                localApi.sendMessage(msg.getSourceId(), new Message(msg.getTargetId(), msg.getSourceId(), MessageType.STORAGE_ERROR, new GeigerUrl(msg.getSourceId(), "zap/" + identifier), payload));
            } on java_io_IOException catch (ioe) {
            }
        }
    }

    void pluginEvent(GeigerUrl url, Message msg)
    {
        storageEventParser(msg);
    }

    /// Registers a StorageListener.
    /// @param msg the received message
    /// @param identifier the method identifier
    /// @param optionalArgs other arguments from GeigerUrl
    void registerChangeListener(Message msg, String identifier, List<String> optionalArgs)
    {
        msg.getPayload();
        ch_fhnw_geiger_localstorage_StorageListener listener = null;
        ch_fhnw_geiger_localstorage_SearchCriteria criteria = SearchCriteria_.fromByteArray(msg.getPayload());
    }

    List<ch_fhnw_geiger_localstorage_SearchCriteria> deregisterChangeListener(ch_fhnw_geiger_localstorage_StorageListener listener)
    {
        return new List<ch_fhnw_geiger_localstorage_SearchCriteria>(0);
    }

}
