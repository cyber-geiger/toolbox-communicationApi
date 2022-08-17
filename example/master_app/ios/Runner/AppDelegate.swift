import UIKit
import Flutter
import Foundation
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    var thread: Thread?;
    var controller: FlutterViewController?;
    var messageChannel: FlutterMethodChannel?;
    var dispatchQueue: DispatchQueue?;
    var session: AVAudioSession?;
    
    func openUrl(toOpen: String?){
        if let url = URL(string: toOpen!) {
            if UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10.0, *) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                        UIApplication.shared.openURL(url);
                }
            }
        }
    }

    override func application(_ application: UIApplication,
                         continue userActivity: NSUserActivity,
                         restorationHandler: @escaping ([UIUserActivityRestoring]) -> Void) -> Bool
    {
        dispatchQueue = DispatchQueue.global()
        dispatchQueue!.async(execute: {
                do{
                    self.session = AVAudioSession.sharedInstance()

                    try self.session!.setCategory(AVAudioSession.Category.playback)
                    try self.session!.setActive(true)
                }
                catch{
                    print("\(error)")
                }
        });
        
        // Get URL components from the incoming user activity.
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let incomingURL = userActivity.webpageURL,
            let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true) else {
            return false
        }
        
        // Check for specific URL components
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
    
    override func application(_ application: UIApplication,
                     open url: URL,
                              options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {
        // Process the URL.
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
              let _ = components.path else {
            return false
        }
        
        if let params = components.queryItems {
            if let data = params.first(where: { $0.name == "redirect" })?.value {
                usleep(500000) // 500ms
                openUrl(toOpen: String(data));
                return true
            }
        }
        return true;
    }
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
        ) -> Bool {
            dispatchQueue = DispatchQueue.global()
            dispatchQueue!.async(execute: {
                    do{
                        self.session = AVAudioSession.sharedInstance()

                        try self.session!.setCategory(AVAudioSession.Category.playback)
                        try self.session!.setActive(true)
                    }
                    catch{
                        print("\(error)")
                    }
            });
            
            controller = window?.rootViewController as? FlutterViewController
            messageChannel = FlutterMethodChannel(name: "cyber-geiger.eu/communication", binaryMessenger: controller!.binaryMessenger)

            messageChannel?.setMethodCallHandler({
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
