# Client Geiger App

App that registers itself as a plugin on the master Geiger app.
Is preconfigured to work with the `master_app` example.

## Windows Support

When running in Debug mode, the plugin and master need to be run in their source code directories and
a debug build of the master has to exist. One can be generated using the following command:

```sh
flutter build windows --debug
```

When running in Release mode, the plugin assumes both applications are installed as MSIX packages.

### MSIX Package

To test the application when installed as a MSIX application do the following:

1. Generate MSIX files: `flutter pub run msix:build`
2. Add the following section to `build/windows/runner/Release/AppxManifest.xml`:
   ```xml
   <Package>
      <!-- ... -->
      <Applications>
         <Application>
            <!-- ... -->
            <!-- Add the following section: -->
            <Extensions>
               <uap3:Extension Category="windows.appExecutionAlias" EntryPoint="Windows.FullTrustApplication">
                  <uap3:AppExecutionAlias>
                     <desktop:ExecutionAlias Alias="geiger-client-example.exe"/>
                  </uap3:AppExecutionAlias>
               </uap3:Extension>
            </Extensions>
         </Application>
      </Applications>
   </Package>
   ```
3. Package into MSIX: `flutter pub run msix:pack`
4. Install the package located at `build/windows/runner/Release/client_app.msix`.

Now the application is available globally using the `geiger-client-example.exe` command.