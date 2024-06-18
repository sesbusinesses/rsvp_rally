import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = ProcessInfo.processInfo.environment["GMS_API_KEY"] {
      GMSServices.provideAPIKey(apiKey)
    }

    let controller = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "app/channel", binaryMessenger: controller.binaryMessenger)
    channel.setMethodCallHandler { (call, result) in
      if call.method == "getGMSApiKey" {
        result(ProcessInfo.processInfo.environment["GMS_API_KEY"])
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
