# iOS App Store — Gravity Rush Deployment Guide

## 0. TL;DR build commands (run on macOS)

```bash
cd ios && pod install && cd ..
flutter clean
flutter pub get
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
# result:
#   build/ios/ipa/Runner.ipa           <-- upload via Transporter
#   build/ios/archive/Runner.xcarchive <-- open in Xcode → Organizer → Distribute App
```

Before the first build edit `ios/ExportOptions.plist` and confirm `teamID`
matches the Apple Developer Team ID you own.

---

## 1. Apple Developer account prerequisites

1. Paid Apple Developer Program membership ($99/year).
2. In https://developer.apple.com/account/resources/identifiers/list create
   App ID with Bundle ID `com.gsteamgsgames.gravityrush`.
   - Capabilities: Push Notifications.
3. In https://appstoreconnect.apple.com create the app:
   - Platform: iOS
   - Name: `Gravity Rush`
   - Primary Language: English (U.S.)
   - Bundle ID: `com.gsteamgsgames.gravityrush`
   - SKU: `gravity-rush-ios`
4. Generate an APNs Auth Key (`.p8`) under
   https://developer.apple.com/account/resources/authkeys/list and upload it
   to Firebase → Project Settings → Cloud Messaging → Apple app config.

## 2. What is configured in the repo

### `ios/Runner/Info.plist`

- `CFBundleDisplayName = Gravity Rush`
- `CFBundleName = GravityRush`
- `LSApplicationCategoryType = public.app-category.games`
- `ITSAppUsesNonExemptEncryption = false` (skips export-compliance prompt
  on every TestFlight build)
- `UIRequiresFullScreen = true` (required for the orientation lock + WebView
  layout we use; also avoids iPad multitasking review issues)
- `UISupportedInterfaceOrientations` — all four orientations (TZ requires
  auto-rotate)
- `UIStatusBarHidden = true` + `UIViewControllerBasedStatusBarAppearance = false`
  (matches `SystemUiMode.immersiveSticky` used for the WebView host)
- `NSAppTransportSecurity → NSAllowsArbitraryLoadsInWebContent = true`
  (required because the WebView loads third-party browser content)
- `NSUserTrackingUsageDescription` (required because AppsFlyer SDK is included
  and we explicitly call ATT before init)
- `NSPhotoLibraryUsageDescription` (required because `<input type="file">`
  inside WKWebView opens the Photos picker)
- `UIBackgroundModes = [remote-notification]` (FCM)
- `FirebaseAppDelegateProxyEnabled = true` (lets `firebase_messaging` swizzle
  the AppDelegate and forward APNs token automatically)
- `NSHumanReadableCopyright` present

### `ios/Runner/PrivacyInfo.xcprivacy`

Apple's required privacy manifest. Declares:

- `NSPrivacyTracking = true` (because AppsFlyer SDK is integrated).
- `NSPrivacyTrackingDomains` — the AppsFlyer endpoints we contact.
- `NSPrivacyCollectedDataTypes` — Device ID, Advertising Data, Product
  Interaction, Other Diagnostic Data. Linked to user, used for analytics +
  app functionality + third-party advertising. The first two have
  `NSPrivacyCollectedDataTypeTracking = true`.
- `NSPrivacyAccessedAPITypes` — UserDefaults / File timestamp / System boot
  time / Disk space (required reasons for `shared_preferences` + `video_player`).

### `ios/Podfile`

Sets `iOS 13.0` minimum deployment target, excludes `arm64` from simulator.

### `ios/ExportOptions.plist`

- `method = app-store-connect`
- `signingStyle = automatic`
- `teamID` is set in this repo; replace if your Team ID differs.

### `ios/Runner.xcodeproj/project.pbxproj`

Bundle id is `com.gsteamgsgames.gravityrush`. Privacy manifest is added to
the Resources build phase.

## 3. App icon rules (Apple rejects with alpha channel)

`ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`
**must NOT contain an alpha channel**. Verify on macOS:

```bash
sips -g hasAlpha ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
# If "hasAlpha: yes" -> regenerate without alpha:
flutter pub run flutter_launcher_icons
```

## 4. Signing (one-time in Xcode)

```bash
open ios/Runner.xcworkspace
```

1. Select the `Runner` target → `Signing & Capabilities`.
2. Check `Automatically manage signing`.
3. Pick your Team.
4. Add the `Push Notifications` capability.
5. Let Xcode create the `iOS App Development` / `App Store` provisioning
   profiles.

## 5. App Store Connect metadata checklist

| Field | Value |
| --- | --- |
| App name | Gravity Rush |
| Subtitle | Neon Plinko |
| Category (Primary) | Games → Arcade |
| Category (Secondary) | Games → Casual |
| Age rating | 4+ |
| Price | Free |
| Privacy policy URL | https://gravittyrush.com/privacy-policy.html |
| Support URL | https://gravittyrush.com/support.html |
| Copyright | 2026 Gravity Rush |

> The privacy and support URLs **must return HTTP 200** at review time.
> Apple rejects under guideline 1.5 / 5.1.1 if they 404, redirect to a
> domain parking page, or load a placeholder.

### App Privacy ("Data Types") — **must match `PrivacyInfo.xcprivacy`**

The build includes Firebase Core, Firebase Messaging, Firebase App Check
and AppsFlyer. Therefore "Data Not Collected" is **not** a valid answer.
Fill the App Store Connect privacy questionnaire as follows:

| Data category | Linked? | Tracking? | Purposes |
| --- | --- | --- | --- |
| **Device ID** (AppsFlyer ID, FCM token) | Yes | Yes | Analytics, App Functionality, Third-Party Advertising |
| **Advertising Data** (campaign, ad source) | Yes | Yes | Analytics, Third-Party Advertising |
| **Product Interaction** | Yes | No | Analytics, App Functionality |
| **Other Diagnostic Data** | Yes | No | App Functionality, Analytics |

### App Tracking Transparency

The app calls `AppTrackingTransparency.requestTrackingAuthorization()`
before initializing AppsFlyer (see `lib/services/attribution_gateway.dart`).
On first launch the system ATT prompt is shown; AppsFlyer waits up to
10 seconds for the user's decision before sending events.

### App Review Information

- Sign-in required: No
- Notes for reviewer:
  > Gravity Rush is a skill-based neon plinko arcade game. The app uses
  > AppsFlyer for marketing attribution and Firebase Cloud Messaging for
  > push notifications. The first-launch flow requests tracking
  > authorization (App Tracking Transparency) before AppsFlyer is
  > initialized.

### Age Rating questionnaire

Answer for the arcade build: ball-drop arcade with no real-money wagering.

## 6. Screenshots (required sizes)

- 6.9" display (iPhone 16 Pro Max) — 1320 × 2868 px — **required**
- 6.5" display (iPhone 11 Pro Max / XS Max) — 1242 × 2688 px
- 13" iPad Pro (M4) — 2064 × 2752 px — **required because app supports iPad**

Aim for 3-5 screenshots per size.

## 7. Build & upload

```bash
cd /path/to/GravityRush
flutter clean
flutter pub get
cd ios && pod install --repo-update && cd ..
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
```

Then upload:

- **Option A:** open `Xcode → Window → Organizer`, select the archive,
  click `Distribute App → App Store Connect → Upload`.
- **Option B:** use `Transporter.app` from the Mac App Store and drop
  `build/ios/ipa/Runner.ipa` onto it.

## 8. Common reject reasons and how this repo avoids them

| Rejection | Mitigation in repo |
| --- | --- |
| 2.1 (app crashes) | Release build tested, offline-capable, retry screen, conversion timeouts |
| 2.3.1 (accurate metadata) | Privacy answers must match `PrivacyInfo.xcprivacy` (table above) |
| 2.5.1 (private API) | Flutter SDK + standard plugins only |
| 2.5.4 (unused background modes) | `UIBackgroundModes` only contains `remote-notification` (used by FCM) |
| 4.0 (design / iPad multitasking) | `UIRequiresFullScreen = true`, safe-area JS shim in WebView |
| 5.1.1 (privacy policy missing) | Privacy + Support links present in main menu and in App Store Connect |
| 5.1.2 (data declarations mismatch) | `PrivacyInfo.xcprivacy` honestly declares tracking + collected data |
| 5.1.5 (data minimization) | `NSPhotoLibraryAddUsageDescription` removed (we do not save to album) |
| Missing privacy manifest | `PrivacyInfo.xcprivacy` is bundled and added to Resources |
| Non-exempt encryption | `ITSAppUsesNonExemptEncryption = false` |
| Icon with alpha channel | See section 3 — run `sips -g hasAlpha` before submitting |
| ATT prompt missing | `app_tracking_transparency` plugin called before AppsFlyer init |

## 9. Version bumps

Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1   # MARKETING_VERSION+BUILD_NUMBER
```
- Bump `+1 -> +2 -> +3 ...` for every new TestFlight build.
- Bump `1.0.0 -> 1.0.1` only when you publicly release a new version.
