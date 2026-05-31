import 'dart:ui';

import '../utils/asset_paths.dart';

/// A collectible elemental orb. Orbs are purely cosmetic: the chosen orb is
/// the glyph that lights up across every puzzle. They unlock as the player
/// accumulates stars — there is no currency, no purchase and no chance.
class OrbSkin {
  final String id;
  final String label;
  final String element;
  final String assetPath;
  final Color glowColor;
  final Color accentColor;

  /// Total stars required to unlock this orb (0 = available from the start).
  final int unlockStars;

  const OrbSkin({
    required this.id,
    required this.label,
    required this.element,
    required this.assetPath,
    required this.glowColor,
    required this.accentColor,
    required this.unlockStars,
  });

  Color get primaryColor => glowColor;
  bool get isStarter => unlockStars == 0;

  static const List<OrbSkin> catalog = [
    OrbSkin(
      id: 'frost',
      label: 'Frost',
      element: 'Ice',
      assetPath: AssetPaths.orbFrost,
      glowColor: Color(0xFF4FC3F7),
      accentColor: Color(0xFF0288D1),
      unlockStars: 0,
    ),
    OrbSkin(
      id: 'aqua',
      label: 'Aqua',
      element: 'Water',
      assetPath: AssetPaths.orbAqua,
      glowColor: Color(0xFF26C6DA),
      accentColor: Color(0xFF00838F),
      unlockStars: 3,
    ),
    OrbSkin(
      id: 'verdant',
      label: 'Verdant',
      element: 'Nature',
      assetPath: AssetPaths.orbVerdant,
      glowColor: Color(0xFF66BB6A),
      accentColor: Color(0xFF2E7D32),
      unlockStars: 8,
    ),
    OrbSkin(
      id: 'terra',
      label: 'Terra',
      element: 'Earth',
      assetPath: AssetPaths.orbTerra,
      glowColor: Color(0xFFA1887F),
      accentColor: Color(0xFF5D4037),
      unlockStars: 14,
    ),
    OrbSkin(
      id: 'gale',
      label: 'Gale',
      element: 'Wind',
      assetPath: AssetPaths.orbGale,
      glowColor: Color(0xFFB3E5FC),
      accentColor: Color(0xFF0277BD),
      unlockStars: 20,
    ),
    OrbSkin(
      id: 'solar',
      label: 'Solar',
      element: 'Light',
      assetPath: AssetPaths.orbSolar,
      glowColor: Color(0xFFFFEE58),
      accentColor: Color(0xFFFFA000),
      unlockStars: 26,
    ),
    OrbSkin(
      id: 'ember',
      label: 'Ember',
      element: 'Storm',
      assetPath: AssetPaths.orbEmber,
      glowColor: Color(0xFFEF5350),
      accentColor: Color(0xFFFF6D00),
      unlockStars: 32,
    ),
    OrbSkin(
      id: 'blaze',
      label: 'Blaze',
      element: 'Fire',
      assetPath: AssetPaths.orbBlaze,
      glowColor: Color(0xFFFF7043),
      accentColor: Color(0xFFDD2C00),
      unlockStars: 38,
    ),
    OrbSkin(
      id: 'void',
      label: 'Void',
      element: 'Cosmos',
      assetPath: AssetPaths.orbVoid,
      glowColor: Color(0xFFAB47BC),
      accentColor: Color(0xFF7C4DFF),
      unlockStars: 45,
    ),
  ];

  static OrbSkin byId(String id) =>
      catalog.firstWhere((s) => s.id == id, orElse: () => catalog[0]);
}
