# iOS

## Prerequisites

    - An Apple Mac device with Flutter installed 
    - Android Studio with the Flutter extension and or XCode
    - A Domain / Subdomain name 
    - An Apple Developer Account

<br />

## Create a new Flutter iOS project

<br />

### using Android Studio

1. Click on New Flutter Project
2. On the project creation wizard, make sure iOS is ticked as a Platform
3. Follow the rest of the creation dialog

<br />

### using the Console

```
flutter create --org com.example your_app_name
```

<br />

## Add iOS support to an existing Android project

run 
```
    flutter create --platforms=android,ios .
```

in the project root and it will add the required files for all platforms

<br />

## Replace the AppDelegate with the following one

In the project root, navigate to ios > Runner > AppDelegate.swift and replace the files content with the the following content:

(In XCode, the file can be found in the project navigator under Runner > Runner > AppDelegate)

```swift

import UIKit
import Flutter
import Foundation
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    var controller: FlutterViewController?;
    var messageChannel: FlutterMethodChannel?;
    var dispatchQueue: DispatchQueue = DispatchQueue.global();
    
    // Function to open a URL
    func openUrl(toOpen: String?){
        if let url = URL(string: toOpen!) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url);
            }
        }
    }
    
    
    // Gets called when the app gets restored from background
    override func application(_ application: UIApplication,
                              continue userActivity: NSUserActivity,
                              restorationHandler: @escaping ([UIUserActivityRestoring]) -> Void) -> Bool
    {
        // Get URL components from the incoming user activity.
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL,
              let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else {
            return false
        }
        
        // Check for redirect URL query component.
        if components.path != nil {
            if let params = components.queryItems {
                if let data = params.first(where: { $0.name == "redirect" })?.value {
                    openUrl(toOpen: String(data));
                    return true
                }
            }
        }
        return true;
    }
    
    
    // Gets called when the app was fully closed.
    // Sets up the flutter method channel for communication
    // Flutter calls with the method "url" open the URL passed on to it
    override func application(_ application: UIApplication,
                              didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        controller = window?.rootViewController as? FlutterViewController
        messageChannel = FlutterMethodChannel(name: "cyber-geiger.eu/communication", binaryMessenger: controller!.binaryMessenger)
        
        messageChannel!.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            if (call.method == "url") {
                let args = call.arguments as! Optional<String>
                self.openUrl(toOpen: args);
                result(nil);
            }
        });
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

```

<br />

## Create an App ID in the Apple Developer Portal

On the Apple Developer website, navigte to [Identifiers](https://developer.apple.com/account/resources/identifiers/list) and click on Add (+)
 - Select App IDs
 - Select App
 - Add a Description and fill out Bundel Identifier with your Bundle identifier
 - Select the Capability `Associated Domains` and any other Capabilites you need.
 - Click Register
 - Click on the created AppID and copy the app id prefix

<br />

## Create an apple associated Domain


Note: Make sure the domain uses SSL / https

Create a file named `apple-app-site-association` in the root of your website and add the following to it:
```
{
  "applinks": {
    "apps": [],
    "details": [
    {
      "appID": "APP_ID.BUNDLE_IDENTIFIER",
      "paths": ["*"]
    }
    ]
  }
}
```

Replace `APP_ID` with the app id prefix from the previously created App ID
Replace `BUNDLE_IDENTIFIER` with the bundle identifier used in the previously created App ID

You must host the file using https:// with a valid certificate and with no redirects.

Make sure that if you visit https://yourdomain.com/apple-app-site-association that your file is served. (replace "yourdomain.com" with the domain used)

<br />

## Add the capability and associated domains entitlement to your app

Open the ios > Runner.xcworkspace in XCode in XCode

Click on the project "Runner" (may also be called "Runner project", blue XCode icon) on the left in the Project Navigator

In the Project Window, click on the target "Runner" under the "Targets" list on the left (right next to the Project Navigator)

Open the target’s "Signing & Capabilities" tab

Click on Add (+) at the top left next to the profiles where it should say "All", "Debug", "Release" and "Profile"

In the popup search for the "Associated Domains" capability and add it by clicking twice on it

A new Capability should show up in the middle, underneath "Signing"

Under Associated Domain click Add (+) at the bottom of the Domains table and replace the placeholder with the following

`applinks:yourdomain.com` 

Here you would replace "yourdomain.com" with your domain that is a valid apple associated domain.

An example would be: `applinks:client.cyber-geiger.eu`

<br />

## Add the Dart package

In the pubspec.yml in the project root add `geiger_api` as a dependency and run `flutter pub get` in the terminal in your project root

<br />

## Install iOS dependencies (CocoaPods)

Using the terminal, navigate to the ios folder of the app and run the following command: `pod install`

Optionally run `pod update` to update the dependecies

<br />

## Dart Geiger API Usage

Make sure you add your apple associated domain as a 4th value onto the executor
and chose a unique plugin id
```Dart
const pluginExecutor = 'com.example.client_app;'
    'com.example.client_app.MainActivity;'
    'TODO;'
    'https://client.cyber-geiger.eu';

const pluginId = 'my-plugin';
```

In the example above, 'https://client.cyber-geiger.eu' is the associated domain

Then you can get the geiger api and register / activate the plugin:

```Dart
GeigerApi? api = await getGeigerApi(pluginExecutor, pluginId)

// Regsister / activate the plugin after registering any listeners as these listeners won't receive the first few events otherwise
await api!.registerPlugin();
await api.activatePlugin();
```

In your dartcode you can now use the geiger api as you always would

<br />

## Examples

<br />

### Register Plugin and Listener

```Dart
final MessageLogger logger = MessageLogger();
// ...
// ...
// ...
GeigerApi? api = await getGeigerApi(pluginExecutor, pluginId)

api!.registerListener([MessageType.allEvents], logger); // Register the message logger as a event listener and listen to all Events

// AFTER registering the listener, the plugin has to be registered and activated
await api.registerPlugin();
await api.activatePlugin();
```

<br />

```Dart

```
