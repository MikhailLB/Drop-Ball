import 'dart:io';
import 'route_vault.dart';
import 'signal_data.dart';
import 'page_links.dart';

abstract final class FlowConfig {
  // ── iOS App Store numeric ID ──────────────────────────────
  static const String iosStoreId = '6771137735';

  // ── Android/iOS bundle / package ID ──────────────────────
  static const String bundleId = 'com.neonfall.dropball';

  // ── Display name used in debug logs ──────────────────────
  static const String appLabel = 'DropBall: Neon Edition';

  // ── Timing constants ─────────────────────────────────────
  /// Seconds before push opt-in screen re-appears after Skip.
  static const int pushCooldownSecs = 259200; // 3 days

  /// Seconds to retry GCD when AppsFlyer reports Organic.
  static const int organicRetrySecs = 6;

  /// Hard boot timeout — gray flow falls back to game after this.
  static const int bootBudgetSecs = 20;

  // ── Derived ──────────────────────────────────────────────
  static String get configEndpoint    => routeEndpointUrl();
  static String get installKey        => appsflyerKey();
  static String get firebaseNumber    => firebaseProjectNum();
  static String get privacyPage       => brandPrivacyUrl;
  static String get supportPage       => brandSupportUrl;
  static String get platformStoreId   =>
      Platform.isIOS ? 'id$iosStoreId' : bundleId;
  static String get analyticsId       =>
      Platform.isIOS ? iosStoreId : bundleId;
}
