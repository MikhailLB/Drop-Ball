import Flutter
import UIKit
import UserNotifications

/// Scene-based iOS apps (UIApplicationSceneManifest in Info.plist) DO NOT
/// receive cold-start notification responses through the traditional
/// `application(_:didFinishLaunchingWithOptions:)` launchOptions[remoteNotification]
/// path that Firebase Messaging's swizzle relies on. Instead, when the user taps
/// a push while the app is killed, iOS launches the app and delivers the tap
/// via `scene(_:willConnectTo:options:)` in `connectionOptions.notificationResponse`.
///
/// Because Firebase swizzle never sees this response, `FirebaseMessaging.instance
/// .getInitialMessage()` returns nil for scene-based apps on cold-start tap. This
/// is a long-standing FlutterFire issue (firebase/flutterfire#8896) that affects
/// every Flutter iOS app generated with the modern scene template.
///
/// To fix this iron-clad we capture the notification response here ourselves,
/// pull the destination URL out of its userInfo, and stash it into UserDefaults
/// under a `flutter.`-prefixed key — which is exactly the namespace the
/// `shared_preferences` Flutter plugin uses on iOS. Dart reads it back through
/// SharedPreferences without any MethodChannel registration timing race.
class SceneDelegate: FlutterSceneDelegate {
  /// UserDefaults key that mirrors the Dart-side native cold-start slot.
  /// Read by `lib/services/native_push_bridge.dart#consumeColdStartUrl`.
  ///
  /// The `flutter.` prefix is mandatory: the Flutter `shared_preferences`
  /// plugin on iOS namespaces all keys with `flutter.` and would silently
  /// ignore anything written without it. This way the Dart side reads the
  /// value directly through SharedPreferences without needing any
  /// MethodChannel handshake.
  static let coldStartUrlKey = "flutter.gr_native_cold_start_url"

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    if let response = connectionOptions.notificationResponse,
       let url = SceneDelegate.extractUrl(
         from: response.notification.request.content.userInfo
       )
    {
      SceneDelegate.persist(url: url, source: "cold-start")
    }
  }

  /// Tries every key the gray backend might use for the destination URL.
  /// Mirrors the Dart-side `_extractUrl` in `cloud_push_client.dart` so a
  /// payload that opens correctly in foreground/background also opens on
  /// cold start.
  static func extractUrl(from userInfo: [AnyHashable: Any]) -> String? {
    let candidates: [String] = ["url", "link", "target", "deeplink", "deep_link"]

    func scan(_ map: [AnyHashable: Any]) -> String? {
      for key in candidates {
        if let raw = map[key] as? String,
           !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
          return raw.trimmingCharacters(in: .whitespacesAndNewlines)
        }
      }
      return nil
    }

    if let direct = scan(userInfo) { return direct }
    if let nested = userInfo["payload"] as? [AnyHashable: Any] {
      return scan(nested)
    }
    return nil
  }

  static func persist(url: String, source: String) {
    NSLog("[GR.NATIVE] cold-start url captured (\(source)) -> \(url)")
    let defaults = UserDefaults.standard
    defaults.set(url, forKey: coldStartUrlKey)
    defaults.synchronize()
  }
}
