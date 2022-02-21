## 0.6.4 Security features added (incomplete but functional)
Added:
- Custom message type ```CUSTOM_EVENT``` for plugins to send messages to the UI (or vice versa)
- Added call ```authorizePlugin(...)```
- Added ownerEnforcerWrapper to guarantee that plugins get only data destined for them

Fixed:
- Exceptions stacktraces are now properly deserialized

Known bugs:
- example project does not start in the background
- Storage events may leak unaccessible information when nodes are modified.

## 0.6.3 Bugfix Release
Added:
- Improved example code.

## 0.6.2 Bugfix Release (Minor breaking changes)
Minor breaking changes:
- registerChange listener is new async (BEWARE)
- ```activatePlugin``` now determines the port automatically and specification of the port is no longer required.

Fixes:
- Github Issue #7 (Get a Storage from an external plugin)
- Github issue #8 (StorageException:Whoops... error while upgrading database (offending: ALTER TABLE storage_node ADD COLUMN last_modified TEXT CHECK( LENGTH(last_modified) <= 20);)

Known bugs:
- There seems to be an intermitend issue with external change listeners missing changes
- example project does not start in the background

# 0.6.0 External communication release
This is the first release of the external capabilities. From this point on external communication should work.

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
