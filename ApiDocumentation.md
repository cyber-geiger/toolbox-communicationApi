
# Fields

<br />

    id 
    
    Indentifier of the Plugin
    - get
    - 
  
<br />

    declaration

    Data sharing Declaration
    - get

<br />

    storage

    StorageController to access the master storage
    - get
<br />

# Functions

<br />

# initialize

    Initialize asynchornous parts of the plugin
    Must be called once after the construction!
    
### Returns: 
- Future\<void>

<br />

### Example

```Dart
    CommunicationApi api = CommunicationApi(executorOrId, id,
    GeigerApi, masterId == id, declaration);

     await api.initialize();
```

<br />
    
# getStorage

    DEPRECATED! use the storage getter
    Retireve the StorageController to access the master storage

### Returns: 
- StorageController
### Throws: 
- StorageException in case allocation of storage backend fails

<br />

# getRegisteredPlugins
    
    Get the PluginInformation of all registered plugins.
    For security reasons all PluginInformation secrets are empty.

### Parameters:

  - startId: String?
    
    Only the plugins with startId are returned if startId is pecified
### Returns:
  - Future \<List\<PluginInformation\>\>

### Example
```Dart
// get all
List<PluginInformation> plugins = await api.getRegisteredPlugins();

// or

//get all where the id starts with 'ch.geiger'
List<PluginInformation> plugins = await api.getRegisteredPlugins("ch.geiger")
```

<br />

# registerListener

    Register the listener from speific events locally.

### Parameters:

  - List\<MessageType>
    
    List of MessageTypes to listen to
    Message.allEvents to register to all event types
        
    <br />

  - PluginListener
    
    An instance of PluginListener to register 
    <br />

### Returns: 
  - void 
### Example
```dart
final MessageLogger logger = MessageLogger();
//
//
//
GeigerApi api = (await getGeigerApi(pluginExecutor, pluginId))!;
  api.registerListener([MessageType.allEvents], logger);
```

<br />

# deregisterListener

    Remove the listener from specific events locally.

### Parameters:

  - List\<MessageType>\?
    
    List of MessageTypes to derigster
    
    Set events to `null` to remove the listener from all events.

<br />
  
  - PluginListener
        An instance of PluginListener to deregister 

 ### Returns: 
    - void

### Example

```dart
// Listener myListener = ...

List<MessageType> responseTypes = const [
    MessageType.comapiSuccess,
    MessageType.comapiError,
    MessageType.authError
];

api.deregisterListener(responseTypes, myListener);


// to unsubscribe from all events

api.deregisterListener(null, myListener);
```

<br />

# sendMessage

    Send a message to another plugin

### Parameters
- message: Message
  
  If plugin is not provided, message.targetId is used to retrieve the registered plugin information.

  <br />
- pluginId: String?
  
  Plugin id of the target plugin

  <br />
- plugin: PluginInformation?


### Returns
- Future\<void>

### Example

```Dart
// Message Types: 

// registerPlugin,
// deregisterPlugin,
// authorizePlugin,
// activatePlugin,
// deactivatePlugin,
// registerMenu,
// menuPressed,
// enableMenu,
// disableMenu,
// deregisterMenu,
// scanPressed,
// scanCompleted,
// returningControl,
// customEvent,
// ping,
// pong,
// storageEvent,
// storageSuccess,
// storageError,
// comapiSuccess,
// comapiError,
// authSuccess,
// authError


// ping

// String targetPluginId = ...
final GeigerUrl url = GeigerUrl(null, targetPluginId, 'null');
Message message = Message(GeigerApi.masterId, targetPluginId, MessageType.ping, url);
await api.sendMessage(message, targetPluginId);

// auth error
await sendMessage(
    Message(id, msg.sourceId, MessageType.authError, null, null, msg.requestId)
);
```

<br />

# menuPressed

    Notify the plguin about a MenuItem with a specific url being pressed.

### Parameters
- url: GeigerUrl

### Returns
- Future\<void>

### Example

```Dart
    // GeigerApi masterAPI = (await getGeigerApi(...)!);
    // GeigerApi plugin = (await getGeigerApi(...)!);
    // final MenuItem menu = ...
    // await plugin.registerMenu(menu);
    await masterAPI.menuPressed(GeigerUrl(null, 'plugin1', 'testMenu'));
```

<br />

# getMenuList

    Get a list of all registered MenutItem's

### Returns
- List\<MenuItem>

<br />

# scanButtonPressed

    Notify all the plugins that the scan button was pressed

### Returns
- Future\<void>

### Example

```Dart
new IconButton(
  icon: new Icon(Icons.autorenew),
  onPressed: () { api.scanButtonPressed(); },
);
```

<br />

# zapState

    Reset the GeigerApi by removing all registered plgins and MenuItem's.
    Mostly used for testing.

### Returns
- Future\<void>

<br />

# close

    Release all resources

### Returns
- Future\<void>

<br />
