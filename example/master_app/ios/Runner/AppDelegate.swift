import UIKit
import Flutter
//import BackgroundTasks
import Foundation
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    //var backgroundTaskId: UIBackgroundTaskIdentifier? = nil
    // lazy var bgQueue: OperationQueue = {
    //     var queue = OperationQueue()
    //     queue.name = "App Refresh"
    //     queue.maxConcurrentOperationCount = 10
    //     return queue
    //   }()
    
    var thread: Thread?;
    
     override func applicationDidEnterBackground(_ application: UIApplication) {
//         if #available(iOS 13.0, *) {
//             scheduleAppRefresh();
//         } else {
//             // Fallback on earlier versions
//         };
         if #available(iOS 10.0, *) {
//             if (thread == nil){
//                 thread = Thread{
//                     var i = 0;
//                     while(UIApplication.shared.backgroundTimeRemaining >= 0.5){
//                         usleep(1000000)
//                         i += 1;
//                         //NSLog("%0.4f", UIApplication.shared.backgroundTimeRemaining)
//                         print(i)
//                     }
//                 }
//                 thread!.start();
//             }
         } else {
             // Fallback on earlier versions
         }
     }

    // func longRunningTask() {
    //     print("to background");
    //       self.backgroundTaskId = UIApplication.shared.beginBackgroundTask(expirationHandler: {
    //           while(UIApplication.shared.backgroundTimeRemaining >= 0.5){
    //               usleep(250000)
    //               NSLog("%0.4f", UIApplication.shared.backgroundTimeRemaining)
              
    //       }
    //           UIApplication.shared.endBackgroundTask(self.backgroundTaskId!);
    //   })
    // }
    
    // @available(iOS 13.0, *)
    // func scheduleAppRefresh() {
    //     print("refresh scheduled");
    //    let request = BGAppRefreshTaskRequest(identifier: "ch.fhnw.geiger.refresh")
    //    // Fetch no earlier than 15 minutes from now.
    //    request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
            
    //    do {
    //       try BGTaskScheduler.shared.submit(request)
    //    } catch {
    //        print("Could not schedule app refresh: \(error.localizedDescription)")
    //    }
    // }
    
    // @available(iOS 13.0, *)
    // @objc func handleAppRefresh(task: BGAppRefreshTask){
    //     print("refresh")
    //     // Schedule a new refresh task.
    //        scheduleAppRefresh()

    //        // Create an operation that performs the main part of the background task.
    //        let operation = RefreshOperation()
           
    //        // Provide the background task with an expiration handler that cancels the operation.
    //        task.expirationHandler = {
    //            while(UIApplication.shared.backgroundTimeRemaining >= 0.5){
    //                usleep(250000)
    //                NSLog("%0.4f", UIApplication.shared.backgroundTimeRemaining)
    //            }
    //           operation.cancel()
    //        }

    //        // Inform the system that the background task is complete
    //        // when the operation completes.
    //        operation.completionBlock = {
    //           task.setTaskCompleted(success: !operation.isCancelled)
    //        }

    //        // Start the operation.
    //        bgQueue.addOperation(operation)
    //     longRunningTask()
    // }

    // @objc func willResignActive(_ notification: Notification) {
    //     print("to background");
    //     longRunningTask();
    // }

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

    
    func playSound(soundName: String){
        print(soundName)
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
            
            
    // if #available(iOS 13.0, *) {
    //            BGTaskScheduler.shared.register(forTaskWithIdentifier: "ch.fhnw.geiger.refresh", using: nil) { task in
    //                self.handleAppRefresh(task: task as! BGAppRefreshTask)
    //            }
    //            NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIScene.willDeactivateNotification, object: nil)
    //        } else {
    //            NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    //        }
            
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
