class AssetPaths {
  AssetPaths._();

  // Elemental orbs
  static const String orbFrost = 'assets/game_assets/orb_frost.webp';
  static const String orbTerra = 'assets/game_assets/orb_terra.webp';
  static const String orbVerdant = 'assets/game_assets/orb_verdant.webp';
  static const String orbAqua = 'assets/game_assets/orb_aqua.webp';
  static const String orbGale = 'assets/game_assets/orb_gale.webp';
  static const String orbSolar = 'assets/game_assets/orb_solar.webp';
  static const String orbEmber = 'assets/game_assets/orb_ember.webp';
  static const String orbVoid = 'assets/game_assets/orb_void.webp';
  static const String orbBlaze = 'assets/game_assets/orb_blaze.webp';

  // Skull marker — used as inert board walls
  static const String skull = 'assets/game_assets/trap_marker.webp';

  // Logos
  static const String logoMark = 'assets/Logo_white.png';
  static const String logoTitle = 'assets/Logo_name.png';
  static const String logoMuted = 'assets/Logo_gray.png';

  static const List<String> allOrbs = [
    orbFrost, orbAqua, orbVerdant, orbTerra, orbGale,
    orbSolar, orbEmber, orbBlaze, orbVoid,
  ];

  static const List<String> preload = [
    ...allOrbs,
    skull,
    logoMark,
    logoTitle,
  ];
}
