# Geiger API

This repository contains implementations of the Geiger API protocol providing local-only communication between Geiger
plugins.

## Links

- [General documentation](https://github.com/cyber-geiger/toolbox-communicationApi/wiki)
- [Change log](dart/geiger_api/CHANGELOG.md)

## Versions

There are several implementations in different languages:

| Language |                        Name                         | Notes                    | Source                                                             | Example                                              |
|:--------:|:---------------------------------------------------:|:-------------------------|:-------------------------------------------------------------------|:-----------------------------------------------------|
|   Dart   | [`geiger_api`](https://pub.dev/packages/geiger_api) | Reference implementation | [`dart/geiger_api/`](dart/geiger_api/)                             | [`dart/geiger_api/example`](dart/geiger_api/example) |
|   Java   |             `GeigerApiPluginConnector`              | Client-only              | [`java/GeigerApiPluginConnector/`](java/GeigerApiPluginConnector/) | [`java/ClientExample/`](java/ClientExample/)         |
