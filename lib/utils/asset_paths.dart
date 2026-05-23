class AssetPaths {
  AssetPaths._();

  // Orb skins
  static const String orbFrost   = 'assets/game_assets/orb_frost.webp';
  static const String orbTerra   = 'assets/game_assets/orb_terra.webp';
  static const String orbVerdant = 'assets/game_assets/orb_verdant.webp';
  static const String orbAqua    = 'assets/game_assets/orb_aqua.webp';
  static const String orbGale    = 'assets/game_assets/orb_gale.webp';
  static const String orbSolar   = 'assets/game_assets/orb_solar.webp';
  static const String orbEmber   = 'assets/game_assets/orb_ember.webp';
  static const String orbVoid    = 'assets/game_assets/orb_void.webp';
  static const String orbBlaze   = 'assets/game_assets/orb_blaze.webp';

  // Trap marker (skull)
  static const String trapMarker = 'assets/game_assets/trap_marker.webp';

  // Loading bar frames
  static const String barEmpty  = 'assets/Loading/loading_bar_empty.webp';
  static const String barHalf   = 'assets/Loading/loading_bar_half.webp';
  static const String barAlmost = 'assets/Loading/loading_bar_almost.webp';
  static const String barFull   = 'assets/Loading/loading_bar_full.webp';

  // Loading videos
  static const String videoPortrait  = 'assets/Loading/9x16_Loading_Screen.mp4';
  static const String videoLandscape = 'assets/Loading/16x9_Loading_Screen.mp4';

  // Logos
  static const String logoMark  = 'assets/Logo_white.png';
  static const String logoTitle = 'assets/Logo_name.png';
  static const String logoMuted = 'assets/Logo_gray.png';

  // No-WiFi screens
  static const String noWifiV = 'assets/NoWifi/9x16_NoWifi_Screen.webp';
  static const String noWifiH = 'assets/NoWifi/16x9_NoWifi_Screen.webp';

  // Notification screens
  static const String notifV = 'assets/Notifications/9x16_Notifications.webp';
  static const String notifH = 'assets/Notifications/16x9_Notifications.webp';

  static const List<String> preloadImages = [
    orbFrost, orbTerra, orbVerdant, orbAqua, orbGale,
    orbSolar, orbEmber, orbVoid, orbBlaze,
    trapMarker,
    barEmpty, barHalf, barAlmost, barFull,
    logoMark, logoTitle, logoMuted,
    noWifiV, noWifiH, notifV, notifH,
  ];
}
