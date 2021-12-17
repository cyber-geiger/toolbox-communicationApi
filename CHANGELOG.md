## 0.5.5
Fixes:
- Flutter analyze issues detected by the new flutter framework release
- Upgrades dependencies

Adds:
- Many internal things. Mainly prep-work for the EoY release. 

## 0.5.4
- Fixes Github issue #4 (FileSystemException: Cannot open file, path = 'GeigerApi.miCyberrangePlugin.state' (OS Error: Read-only file system, errno = 30)).
- Extends capabilities and boosts to the most recent localstore
- Fixes some dependencies (however - All mitigations for getting rid of Flutter in favor of Dart failed)

## 0.5.3 
Added support for autodetection of the storage location. Warning: This breaks dart compatibility due 
to the requirement of path_provider. From here we have 'Flutter only'. Anyone knowing a sensible 
alternative is warmly welcomed.  

## 0.5.2
Added PluginListener to the list of exported APIs.

## 0.5.1
Added support for always traceable replies in the Message class. Required for replication and waiting for related, subsequent messages.

## 0.5.0

- Initial version (covers only local plugin communication)
