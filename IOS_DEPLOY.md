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

Before the first build edit `ios/ExportOptions.plist` and replace
`YOUR_TEAM_ID` with your Apple Developer Team ID (10-char alphanumeric
from https://developer.apple.com/account → Membership).

---

## 1. Apple Developer account prerequisites

1. Paid Apple Developer Program membership ($99/year).
2. In https://developer.apple.com/account/resources/identifiers/list create
   App ID with Bundle ID `com.gsteamgsgames.gravityrush`
   (matches `ios/Runner.xcodeproj/project.pbxproj`).
   - Capabilities: none needed for the white build.
3. In https://appstoreconnect.apple.com create a new app:
   - Platform: iOS
   - Name: `Gravity Rush`
   - Primary Language: English (U.S.)
   - Bundle ID: `com.gsteamgsgames.gravityrush`
   - SKU: `gravity-rush-ios`

## 2. What is already configured in the repo

- `ios/Runner/Info.plist`
  - `CFBundleDisplayName = Gravity Rush`
  - `CFBundleName = GravityRush`
  - `LSApplicationCategoryType = public.app-category.games`
  - `ITSAppUsesNonExemptEncryption = false` (skips export-compliance prompt on every TestFlight build)
  - `UIRequiresFullScreen = true` (required because the game locks orientation)
  - `UISupportedInterfaceOrientations` = Portrait only
  - `UISupportedInterfaceOrientations~ipad` = Portrait + PortraitUpsideDown
  - `UIStatusBarHidden = true` + `UIViewControllerBasedStatusBarAppearance = false`
    (matches `SystemUiMode.immersiveSticky` used in `lib/app.dart`)
  - `NSHumanReadableCopyright` present
- `ios/Runner/PrivacyInfo.xcprivacy` — Apple's required privacy manifest.
  Declares: no tracking, no data collection, and the required reasons for
  UserDefaults / File timestamp / System boot time / Disk space APIs used
  by `shared_preferences` and `video_player`.
- `ios/Podfile` — sets min deployment target `iOS 13.0`, excludes `arm64` from simulator.
- `ios/ExportOptions.plist` — `app-store-connect` destination.
- `ios/Runner.xcodeproj/project.pbxproj` — bundle id set to
  `com.gsteamgsgames.gravityrush`, privacy manifest added to Resources build phase.

## 3. App icon rules (Apple rejects with alpha channel)

`ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`
**must NOT contain an alpha channel**. Verify on macOS:

```bash
sips -g hasAlpha ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
# If "hasAlpha: yes" -> regenerate without alpha:
dart run flutter_launcher_icons
# or flatten manually:
sips -s format png --matchTo '/System/Library/ColorSync/Profiles/sRGB Profile.icc' \
  ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
```

If needed, regenerate every icon:
```bash
flutter pub run flutter_launcher_icons
```
(config is already in `pubspec.yaml`).

## 4. Signing (one-time in Xcode)

```bash
open ios/Runner.xcworkspace
```
1. Select the `Runner` target → `Signing & Capabilities`.
2. Check `Automatically manage signing`.
3. Pick your Team.
4. Let Xcode create the `iOS App Development` / `App Store` provisioning profile.

## 5. App Store Connect metadata checklist

Apple requires these fields before a build can be submitted for review.

| Field | Value |
| --- | --- |
| App name | Gravity Rush |
| Subtitle | Neon Plinko |
| Category (Primary) | Games → Arcade |
| Category (Secondary) | Games → Casual |
| Age rating | 4+ (no questionable content, no real-money gambling) |
| Price | Free |
| Availability | All territories except where prohibited |
| Privacy policy URL | https://gravittyrush.com/privacy-policy.html |
| Support URL | https://gravittyrush.com/support.html |
| Marketing URL | (optional) |
| Copyright | 2026 Gravity Rush |

### App Privacy ("Data Types")

Answer: **Data Not Collected**.
- The app uses `shared_preferences` only for local in-game balance/skin
  selection. This is on-device storage and does not qualify as data
  collection per Apple's definition.
- No analytics, no crash reporters, no third-party SDKs are included in
  this white build.

### App Review Information

- Sign-in required: No
- Contact: your email / phone
- Notes for reviewer:
  > Gravity Rush is a skill-based neon plinko arcade game. No real-money
  > gambling, no in-app purchases, no advertising, no user accounts, no
  > data collection. All in-game currency is earned by playing and spent
  > only on cosmetic ball skins. Portrait-only. Works offline.

### Age Rating questionnaire

All answers: **None**. The ball-drop mechanics are not "simulated gambling"
under Apple's definition because there is no wagering of real money,
no real prizes, no leaderboards, and no game of chance linked to currency
outside the app.

## 6. Screenshots (required sizes)

Generate on the simulator, Cmd-S to save.

- 6.9" display (iPhone 16 Pro Max) — 1320 × 2868 px — **required**
- 6.5" display (iPhone 11 Pro Max / XS Max) — 1242 × 2688 px
- 5.5" display (iPhone 8 Plus) — 1242 × 2208 px — required if you support iOS < 17
- 13" iPad Pro (M4) — 2064 × 2752 px — required because app supports iPad

Aim for 3-5 screenshots per size: loading → menu → gameplay → game-over → skin shop.

## 7. Build & upload

On macOS with Xcode 15+ and Ruby / CocoaPods installed:

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

After 10-30 min the build appears in App Store Connect → TestFlight.

## 8. Common reject reasons and how this repo avoids them

| Rejection | Mitigation in repo |
| --- | --- |
| 2.1 (app crashes / broken) | Release build tested, offline-capable, no network dependencies |
| 2.3.8 (accurate metadata) | App name, icon, screenshots must match bundled content |
| 2.5.1 (private API) | Flutter SDK only; no private APIs used |
| 3.2.1 (real-money gambling) | No IAP, no real money, skill-based game only |
| 4.0 (design) | Uses LaunchStoryboard, respects safe areas, portrait lock consistent |
| 5.1.1 (data collection) | `PrivacyInfo.xcprivacy` declares zero data collection |
| 5.1.2 (missing privacy policy) | Privacy link present in main menu + filed in App Store Connect |
| Missing privacy manifest | `PrivacyInfo.xcprivacy` is bundled and added to Resources |
| Non-exempt encryption | `ITSAppUsesNonExemptEncryption = false` |
| Icon with alpha channel | See section 3 — run `sips -g hasAlpha` before submitting |
| iPad orientations mismatch | `UIRequiresFullScreen = true` + portrait-only set |

## 9. Version bumps

Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1   # MARKETING_VERSION+BUILD_NUMBER
```
- Bump `+1 -> +2 -> +3 ...` for every new TestFlight build.
- Bump `1.0.0 -> 1.0.1` only when you publicly release a new version.
