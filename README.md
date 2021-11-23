# toolbox-communicationApi
This package contains the public interface to communicate in the GEIGER ecosystem.

# Quick start

To get an own API the first call should be:

```Dart
GeigerApi? api = await getGeigerApi('<unspecified>', 'myPluginIdentifier');
```

The specification of the executor is not clear yet but it is there so that code remains functional 
when the feature is implemented. The plugin ID ('myPluginIdentifier') needs to be unique in the 
ecosystem. Failure to choose a unique ID will result in unreliable communication behavior. 