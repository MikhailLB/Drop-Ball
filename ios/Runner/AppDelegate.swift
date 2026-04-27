import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // FirebaseAppDelegateProxyEnabled=YES (Info.plist) lets the Firebase
    // Messaging plugin auto-handle APNs registration and token forwarding,
    // so no manual UNUserNotificationCenter wiring is needed here.
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
