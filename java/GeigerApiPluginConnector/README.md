# GeigerApiPluginConnector

Java client-only implementation of the Geiger API protocol based of the [Dart reference implementation](/dart/geiger_api/). Also contains a Java versions of Geiger's [storage system](https://github.com/cyber-geiger/toolbox-storage).

## Quick start

To create and register a plugin initialize the `PluginApi` class directly:

```Java
GeigerApi api = new PluginApi(
  "<android package id>;<android component id>;<windows executable path>",
  "<plugin id>",
  Declaration.DO_NOT_SHARE_DATA
);
```

Depending on your plugins functionality you will have to change the declaration to `Declaration.DO_SHARE_DATA`. The interface of `GeigerApi` is the same as in the Dart version.

## Example

An example android project can be found under [`java/ClientExample/`](/java/ClientExample/).
