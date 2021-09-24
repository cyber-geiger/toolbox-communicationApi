
import 'java.dart';
/// <p>Class for handling storage events in Plugins.</p>
class PasstroughController with ch_fhnw_geiger_localstorage_StorageController, PluginListener, ch_fhnw_geiger_localstorage_ChangeRegistrar
{
    final LocalApi localApi;
    final String id;
    final Object comm = new Object();
    final java_util_Map<String, Message> receivedMessages = new java_util_HashMap();
    /// <p>Constructor for PasstroughController.</p>
    /// @param api the LocalApi it belongs to
    /// @param id  the PluginId it belongs to
    PasstroughController(LocalApi api, String id)
    {
        this.localApi = api;
        this.id = id;
        localApi.registerListener(new List<MessageType>.from([MessageType_.STORAGE_EVENT, MessageType_.STORAGE_SUCCESS, MessageType_.STORAGE_ERROR]), this);
    }

    Message waitForResult(String command, String identifier)
    {
        String token = ((command + "/") + identifier);
        int start = System.currentTimeMillis();
        while (receivedMessages.get(token) == null) {
            try {
                synchronized(comm, {
                    comm.wait(1000);
                });
            } on InterruptedException catch (e) {
                e.printStackTrace();
            }
            if ((System.currentTimeMillis() - start) > 5000) {
                throw new RuntimeException("Lost communication while waiting for " + token);
            }
        }
        return receivedMessages.get(token);
    }

    ch_fhnw_geiger_localstorage_db_data_Node get(String path)
    {
        String command = "getNode";
        String identifier = String_.valueOf(new java_util_Random().nextInt());
        try {
            localApi.sendMessage(LocalApi_.MASTER, new Message(id, LocalApi_.MASTER, MessageType_.STORAGE_EVENT, new GeigerUrl(id, (((command + "/") + identifier) + "/") + path)));
        } on eu_cybergeiger_totalcross_MalformedUrlException catch (e) {
        }
        Message response = waitForResult(command, identifier);
        try {
            if (response.getType() == MessageType_.STORAGE_ERROR) {
                throw StorageException.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            } else {
                return NodeImpl.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            }
        } on java_io_IOException catch (e) {
            throw new ch_fhnw_geiger_localstorage_StorageException("Could not get Node", e);
        }
    }

    ch_fhnw_geiger_localstorage_db_data_Node getNodeOrTombstone(String path)
    {
        String command = "getNodeOrTombstone";
        String identifier = String_.valueOf(new java_util_Random().nextInt());
        try {
            localApi.sendMessage(LocalApi_.MASTER, new Message(id, LocalApi_.MASTER, MessageType_.STORAGE_EVENT, new GeigerUrl(id, (((command + "/") + identifier) + "/") + path)));
        } on eu_cybergeiger_totalcross_MalformedUrlException catch (e) {
        }
        Message response = waitForResult(command, identifier);
        try {
            if (response.getType() == MessageType_.STORAGE_ERROR) {
                throw StorageException_.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            } else {
                return NodeImpl.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            }
        } on java_io_IOException catch (e) {
            throw new ch_fhnw_geiger_localstorage_StorageException("Could not get Node", e);
        }
    }

    void add(ch_fhnw_geiger_localstorage_db_data_Node node)
    {
        String command = "addNode";
        String identifier = String_.valueOf(new java_util_Random().nextInt());
        try {
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
            node.toByteArrayStream(bos);
            List<int> payload = bos.toByteArray();
            Message m = new Message(id, LocalApi_.MASTER, MessageType_.STORAGE_EVENT, new GeigerUrl(id, (command + "/") + identifier), payload);
            localApi.sendMessage(LocalApi_.MASTER, m);
            Message response = waitForResult(command, identifier);
            if (response.getType() == MessageType_.STORAGE_ERROR) {
                throw StorageException_.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            }
        } on java_io_IOException catch (e) {
            throw new ch_fhnw_geiger_localstorage_StorageException("Could not add Node", e);
        }
    }

    void update(ch_fhnw_geiger_localstorage_db_data_Node node)
    {
        String command = "updateNode";
        String identifier = String_.valueOf(new java_util_Random().nextInt());
        try {
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
            node.toByteArrayStream(bos);
            List<int> payload = bos.toByteArray();
            Message m = new Message(id, LocalApi_.MASTER, MessageType_.STORAGE_EVENT, new GeigerUrl(id, (command + "/") + identifier), payload);
            localApi.sendMessage(LocalApi_.MASTER, m);
            Message response = waitForResult(command, identifier);
            if (response.getType() == MessageType_.STORAGE_ERROR) {
                throw StorageException_.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            }
        } on java_io_IOException catch (e) {
            throw new ch_fhnw_geiger_localstorage_StorageException("Could not update Node", e);
        }
    }

    bool addOrUpdate(ch_fhnw_geiger_localstorage_db_data_Node node)
    {
        String command = "addOrUpdateNode";
        String identifier = String_.valueOf(new java_util_Random().nextInt());
        try {
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
            node.toByteArrayStream(bos);
            List<int> payload = bos.toByteArray();
            Message m = new Message(id, LocalApi_.MASTER, MessageType_.STORAGE_EVENT, new GeigerUrl(id, (command + "/") + identifier), payload);
            localApi.sendMessage(LocalApi_.MASTER, m);
            Message response = waitForResult(command, identifier);
            if (response.getType() == MessageType_.STORAGE_ERROR) {
                throw StorageException_.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            }
            return true;
        } on java_io_IOException catch (e) {
            throw new ch_fhnw_geiger_localstorage_StorageException("Could not add or update Node", e);
        }
    }

    ch_fhnw_geiger_localstorage_db_data_Node delete(String path)
    {
        String command = "deleteNode";
        String identifier = String_.valueOf(new java_util_Random().nextInt());
        try {
            localApi.sendMessage(LocalApi_.MASTER, new Message(id, LocalApi_.MASTER, MessageType_.STORAGE_EVENT, new GeigerUrl(id, (((command + "/") + identifier) + "/") + path)));
        } on eu_cybergeiger_totalcross_MalformedUrlException catch (e) {
        }
        Message response = waitForResult(command, identifier);
        try {
            if (response.getType() == MessageType_.STORAGE_ERROR) {
                throw StorageException_.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            } else {
                return NodeImpl.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            }
        } on java_io_IOException catch (e) {
            throw new ch_fhnw_geiger_localstorage_StorageException("Could not delete Node", e);
        }
    }

    ch_fhnw_geiger_localstorage_db_data_NodeValue getValue(String path, String key)
    {
        String command = "getValue";
        String identifier = String_.valueOf(new java_util_Random().nextInt());
        try {
            localApi.sendMessage(LocalApi_.MASTER, new Message(id, LocalApi_.MASTER, MessageType_.STORAGE_EVENT, new GeigerUrl(id, (((((command + "/") + identifier) + "/") + path) + "/") + key)));
        } on eu_cybergeiger_totalcross_MalformedUrlException catch (e) {
        }
        Message response = waitForResult(command, identifier);
        try {
            if (response.getType() == MessageType_.STORAGE_ERROR) {
                throw StorageException_.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            } else {
                return NodeValueImpl.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            }
        } on java_io_IOException catch (e) {
            throw new ch_fhnw_geiger_localstorage_StorageException("Could not get Value", e);
        }
    }

    void addValue(String path, ch_fhnw_geiger_localstorage_db_data_NodeValue value)
    {
        String command = "addValue";
        String identifier = String_.valueOf(new java_util_Random().nextInt());
        try {
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
            value.toByteArrayStream(bos);
            List<int> payload = bos.toByteArray();
            Message m = new Message(id, LocalApi_.MASTER, MessageType_.STORAGE_EVENT, new GeigerUrl(id, (((command + "/") + identifier) + "/") + path), payload);
            localApi.sendMessage(LocalApi_.MASTER, m);
            Message response = waitForResult(command, identifier);
            if (response.getType() == MessageType_.STORAGE_ERROR) {
                throw StorageException_.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            }
        } on java_io_IOException catch (e) {
            throw new ch_fhnw_geiger_localstorage_StorageException("Could not add NodeValue", e);
        }
    }

    void updateValue(String nodeName, ch_fhnw_geiger_localstorage_db_data_NodeValue value)
    {
        String command = "updateValue";
        String identifier = String_.valueOf(new java_util_Random().nextInt());
        try {
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
            value.toByteArrayStream(bos);
            List<int> payload = bos.toByteArray();
            Message m = new Message(id, LocalApi_.MASTER, MessageType_.STORAGE_EVENT, new GeigerUrl(id, (((command + "/") + identifier) + "/") + nodeName), payload);
            localApi.sendMessage(LocalApi_.MASTER, m);
            Message response = waitForResult(command, identifier);
            if (response.getType() == MessageType_.STORAGE_ERROR) {
                throw StorageException_.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            }
        } on java_io_IOException catch (e) {
            throw new ch_fhnw_geiger_localstorage_StorageException("Could not update NodeValue", e);
        }
    }

    ch_fhnw_geiger_localstorage_db_data_NodeValue deleteValue(String path, String key)
    {
        String command = "deleteValue";
        String identifier = String_.valueOf(new java_util_Random().nextInt());
        try {
            localApi.sendMessage(LocalApi_.MASTER, new Message(id, LocalApi_.MASTER, MessageType_.STORAGE_EVENT, new GeigerUrl(id, (((((command + "/") + identifier) + "/") + path) + "/") + key)));
        } on eu_cybergeiger_totalcross_MalformedUrlException catch (e) {
        }
        Message response = waitForResult(command, identifier);
        try {
            if (response.getType() == MessageType_.STORAGE_ERROR) {
                throw StorageException_.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            } else {
                return NodeValueImpl.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            }
        } on java_io_IOException catch (e) {
            throw new ch_fhnw_geiger_localstorage_StorageException("Could not delete Value", e);
        }
    }

    void rename(String oldPath, String newPathOrName)
    {
        String command = "deleteValue";
        String identifier = String_.valueOf(new java_util_Random().nextInt());
        try {
            localApi.sendMessage(LocalApi_.MASTER, new Message(id, LocalApi_.MASTER, MessageType_.STORAGE_EVENT, new GeigerUrl(id, (((((command + "/") + identifier) + "/") + oldPath) + "/") + newPathOrName)));
        } on eu_cybergeiger_totalcross_MalformedUrlException catch (e) {
        }
        Message response = waitForResult(command, identifier);
        if (response.getType() == MessageType_.STORAGE_ERROR) {
            try {
                throw StorageException_.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            } on java_io_IOException catch (e) {
                throw new ch_fhnw_geiger_localstorage_StorageException("Could not rename Node", e);
            }
        }
    }

    java_util_List<Node> search(ch_fhnw_geiger_localstorage_SearchCriteria criteria)
    {
        String command = "search";
        String identifier = String_.valueOf(new java_util_Random().nextInt());
        try {
            ch_fhnw_geiger_totalcross_ByteArrayOutputStream bos = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
            criteria.toByteArrayStream(bos);
            List<int> payload = bos.toByteArray();
            Message m = new Message(id, LocalApi_.MASTER, MessageType_.STORAGE_EVENT, new GeigerUrl(id, (command + "/") + identifier), payload);
            localApi.sendMessage(LocalApi_.MASTER, m);
            Message response = waitForResult(command, identifier);
            if (response.getType() == MessageType_.STORAGE_ERROR) {
                throw StorageException_.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            } else {
                List<int> receivedPayload = response.getPayload();
                int numNodes = GeigerCommunicator.byteArrayToInt(Arrays.copyOfRange(receivedPayload, 0, 4));
                List<int> receivedNodes = Arrays.copyOfRange(receivedPayload, 5, receivedPayload.length);
                java_util_List<Node> nodes = new java_util_ArrayList();
                for (int i = 0; i < numNodes; (++i)) {
                    nodes.add(NodeImpl.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(receivedNodes)));
                }
                return nodes;
            }
        } on java_io_IOException catch (e) {
            throw new ch_fhnw_geiger_localstorage_StorageException("Could not start Search", e);
        }
    }

    void close()
    {
        String command = "close";
        String identifier = String_.valueOf(new java_util_Random().nextInt());
        try {
            localApi.sendMessage(LocalApi_.MASTER, new Message(id, LocalApi_.MASTER, MessageType_.STORAGE_EVENT, new GeigerUrl(id, (command + "/") + identifier)));
        } on eu_cybergeiger_totalcross_MalformedUrlException catch (e) {
        }
        Message response = waitForResult(command, identifier);
        if (response.getType() == MessageType_.STORAGE_ERROR) {
            try {
                throw StorageException_.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            } on java_io_IOException catch (e) {
                throw new ch_fhnw_geiger_localstorage_StorageException("Could not close", e);
            }
        }
    }

    void flush()
    {
        String command = "flush";
        String identifier = String_.valueOf(new java_util_Random().nextInt());
        try {
            localApi.sendMessage(LocalApi_.MASTER, new Message(id, LocalApi_.MASTER, MessageType_.STORAGE_EVENT, new GeigerUrl(id, (command + "/") + identifier)));
        } on eu_cybergeiger_totalcross_MalformedUrlException catch (e) {
        }
        Message response = waitForResult(command, identifier);
        if (response.getType() == MessageType_.STORAGE_ERROR) {
            try {
                throw StorageException_.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            } on java_io_IOException catch (e) {
                throw new ch_fhnw_geiger_localstorage_StorageException("Could not flush", e);
            }
        }
    }

    void zap()
    {
        String command = "zap";
        String identifier = String_.valueOf(new java_util_Random().nextInt());
        try {
            localApi.sendMessage(LocalApi_.MASTER, new Message(id, LocalApi_.MASTER, MessageType_.STORAGE_EVENT, new GeigerUrl(id, (command + "/") + identifier)));
        } on eu_cybergeiger_totalcross_MalformedUrlException catch (e) {
        }
        Message response = waitForResult(command, identifier);
        if (response.getType() == MessageType_.STORAGE_ERROR) {
            try {
                throw StorageException_.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            } on java_io_IOException catch (e) {
                throw new ch_fhnw_geiger_localstorage_StorageException("Could not zap", e);
            }
        }
    }

    void pluginEvent(GeigerUrl url, Message msg)
    {
        synchronized(receivedMessages, {
            receivedMessages.put(url.getPath(), msg);
        });
        synchronized(comm, {
            comm.notifyAll();
        });
    }

    /// Register a StorageListener for a Node defined by SearchCriteria.
    /// @param listener StorageListener to be registered
    /// @param criteria SearchCriteria to search for the Node
    /// @throws StorageException if the listener could not be registered
    void registerChangeListener(ch_fhnw_geiger_localstorage_StorageListener listener, ch_fhnw_geiger_localstorage_SearchCriteria criteria)
    {
        String command = "registerChangeListener";
        String identifier = String_.valueOf(new java_util_Random().nextInt());
        ch_fhnw_geiger_totalcross_ByteArrayOutputStream byteArrayOutputStream = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
        byteArrayOutputStream.write(criteria.toByteArray());
        try {
            localApi.sendMessage(LocalApi_.MASTER, new Message(id, LocalApi_.MASTER, MessageType_.STORAGE_EVENT, new GeigerUrl(LocalApi_.MASTER, (command + "/") + identifier), byteArrayOutputStream.toByteArray()));
        } on eu_cybergeiger_totalcross_MalformedUrlException catch (e) {
        }
        Message response = waitForResult(command, identifier);
        if (response.getType() == MessageType_.STORAGE_ERROR) {
            try {
                throw StorageException_.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            } on java_io_IOException catch (e) {
                throw new ch_fhnw_geiger_localstorage_StorageException("Could not rename Node", e);
            }
        }
    }

    /// Deregister a StorageListener from the Storage.
    /// @param listener the listener to Deregister
    /// @return the SearchCriteria that were deregistered
    /// @throws StorageException if listener could not be deregistered
    List<ch_fhnw_geiger_localstorage_SearchCriteria> deregisterChangeListener(ch_fhnw_geiger_localstorage_StorageListener listener)
    {
        String command = "deregisterChangeListener";
        String identifier = String_.valueOf(new java_util_Random().nextInt());
        ch_fhnw_geiger_totalcross_ByteArrayOutputStream byteArrayOutputStream = new ch_fhnw_geiger_totalcross_ByteArrayOutputStream();
        try {
            localApi.sendMessage(LocalApi_.MASTER, new Message(id, LocalApi_.MASTER, MessageType_.STORAGE_EVENT, new GeigerUrl(LocalApi_.MASTER, (command + "/") + identifier), byteArrayOutputStream.toByteArray()));
        } on eu_cybergeiger_totalcross_MalformedUrlException catch (e) {
        }
        Message response = waitForResult(command, identifier);
        if (response.getType() == MessageType_.STORAGE_ERROR) {
            try {
                throw StorageException_.fromByteArrayStream(new ch_fhnw_geiger_totalcross_ByteArrayInputStream(response.getPayload()));
            } on java_io_IOException catch (e) {
                throw new ch_fhnw_geiger_localstorage_StorageException("Could not rename Node", e);
            }
        } else {
            SearchCriteria_.fromByteArray(response.getPayload());
            return new List<ch_fhnw_geiger_localstorage_SearchCriteria>(0);
        }
    }

}
