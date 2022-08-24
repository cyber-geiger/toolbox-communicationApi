# toolbox-communicationApi
This package contains the public interface to communicate in the GEIGER ecosystem.

# Quick start

To get an own API the first call should be:

```Dart
GeigerApi? api = await getGeigerApi('<unspecified>', 'myPluginIdentifier');
```

followed by

```Dart
api!.registerPlugin();
api!.activatePlugin();
```

If you want to register an event listener, you will have to do that before reigstering / activating the plugin.

```Dart
final MessageLogger logger = MessageLogger();
// ...
// ...
// ...
api!.registerListener([MessageType.allEvents], logger); // Register the message logger as an event listener and listen to all Events
```
<br />

The specification of the executor is not clear yet but it is there so that code remains functional 
when the feature is implemented. The plugin ID ('myPluginIdentifier') needs to be unique in the 
ecosystem. Failure to choose a unique ID will result in unreliable communication behavior.

<br />

### Running tests

Run tests with `--concurrency=1`. Else some tests will try to get the same port simultaneously.

<br />

### iOS

To get started with iOS, checkout the [iOS documentation](iOSDocumentation.md)