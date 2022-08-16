import UIKit
import Flutter
import Foundation
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    func openUrl(toOpen: String?){
        if let url = URL(string: toOpen!) {
            if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                    UIApplication.shared.openURL(url);
            }
        }
    }
    
    override func application(_ application: UIApplication,
                     open url: URL,
                              options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {

        // Determine who sent the URL.
        let sendingAppID = options[.sourceApplication]
        print("source application = \(sendingAppID ?? "Unknown")")

        // Process the URL.
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
              let path = components.path else {
            print("something went wrong...")
            return false
        }
        
        if let params = components.queryItems {
            if let data = params.first(where: { $0.name == "redirect" })?.value {
                print("path = \(path)");
                print("data = \(data)");
                usleep(500000)
                openUrl(toOpen: String(data));
                return true
            } else {
                print("No Data")
                return false
            }
        }
        
        return true;
    }
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      
      let dispatchQueue = DispatchQueue.global()
      dispatchQueue.async(execute: {
              do{
                  let session = AVAudioSession.sharedInstance()

                  try session.setCategory(AVAudioSession.Category.playback)
                  try session.setActive(true)
              }
              catch{
                  print("\(error)")
              }
      });
      
      let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
      let messageChannel = FlutterMethodChannel(name: "geiger.fhnw.ch/messages", binaryMessenger: controller.binaryMessenger)

      messageChannel.setMethodCallHandler({
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

