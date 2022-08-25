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
    override func application(
    _ application: UIApplication,
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

