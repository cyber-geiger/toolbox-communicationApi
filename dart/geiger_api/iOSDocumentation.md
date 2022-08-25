# iOS

## Prerequisites

    - An Apple Mac device with Flutter installed 
    - Android Studio with the Flutter extension and or XCode
    - A Domain / Subdomain name 
    - An Apple Developer Account

## Create a new Flutter iOS project

### using Android Studio

1. Click on New Flutter Project
2. On the project creation wizard, make sure iOS is ticked as a Platform
3. Follow the rest of the creation dialog

### using the Console

```
flutter create --org com.example your_app_name
```

## Add iOS support to an existing Android project

run 
```
    flutter create --platforms=android,ios .
```

in the project root and it will add the required files for all platforms

## Replace the AppDelegate with the following one


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
    
    func openUrl(toOpen: String?){
        if let url = URL(string: toOpen!) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url);
            }
        }
    }

    
    // when the app gets restored from background
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

        // Check for specific URL components.
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
    
    
    //when the app was fully closed
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
## Create an App ID in the Apple Developer Portal

On the Apple Developer website, navigte to [Identifiers](https://developer.apple.com/account/resources/identifiers/list) and click on Add (+)
 - Select App IDs
 - Select App
 - Add a Description and fill out Bundel Identifier with your Bundle identifier
 - Select the Capability `Associated Domains` and any other Capabilites you need.
 - Click Register
 - Click on the created AppID and copy the app id prefix


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

Make sure that if you visit https://yourdomain.com/apple-app-site-association that your file is served. (replace yourdomain with the domain used)


## Add the capability and associated domains entitlement to your app

Open the iOS workspace in XCode

Click on the Runner Target (dark blue icon) on the left

Open the target’s Signing & Capabilities tab

Click on Add (+) at the top left next to the profiles

Add the Associated Domains capability

Under Associated Domain click Add (+) at the bottom of the Domains table and replace the placeholder with the following

`applinks:yourdomain.com` where you would replace yourdomain.com with your domain that is a valid apple associated domain.

an example would be: `applinks:client.cyber-geiger.eu`


## Add the Dart package

In the pubspec.yml add `geiger_api` as a dependency


## Dart Geiger API Usage

Make sure you add your apple associated domain as a 4th value onto the executor
and chose a unique plugin id
```
const pluginExecutor = 'com.example.client_app;'
    'com.example.client_app.MainActivity;'
    'TODO;'
    'https://client.cyber-geiger.eu';

const pluginId = 'my-plugin';
```

and then get the geiger api:

```
await getGeigerApi(pluginExecutor, pluginId)
```

In your dartcode you can now use the geiger api as you always would




