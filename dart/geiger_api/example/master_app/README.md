# Master Geiger App

App with the master Geiger plugin at which other plugins can register themselves.

## Windows Support

When running in Debug mode the master can only be run in its own source code directory.

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
                     <desktop:ExecutionAlias Alias="geiger-master-example.exe"/>
                  </uap3:AppExecutionAlias>
               </uap3:Extension>
            </Extensions>
         </Application>
      </Applications>
   </Package>
   ```
3. Package into MSIX: `flutter pub run msix:pack`
4. Install the package located at `build/windows/runner/Release/master_app.msix`.

Now the application is available globally using the `geiger-master-example.exe` command.