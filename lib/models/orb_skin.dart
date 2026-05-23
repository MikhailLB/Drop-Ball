import 'dart:ui';
import '../utils/asset_paths.dart';

enum OrbRarity { starter, common, rare, elite, legendary }

class OrbSkin {
  final String id;
  final String label;
  final OrbRarity rarity;
  final String assetPath;
  final Color glowColor;
  final Color accentColor;
  final int particleDensity;
  final double particleLife;
  final double particleSpeed;
  final double glowSize;
  final int cost;

  const OrbSkin({
    required this.id,
    required this.label,
    required this.rarity,
    required this.assetPath,
    required this.glowColor,
    required this.accentColor,
    required this.particleDensity,
    required this.particleLife,
    required this.particleSpeed,
    required this.glowSize,
    this.cost = 0,
  });

  Color get primaryColor => glowColor;

  static const List<OrbSkin> catalog = [
    OrbSkin(
      id: 'frost',
      label: 'Frost',
      rarity: OrbRarity.starter,
      assetPath: AssetPaths.orbFrost,
      glowColor: Color(0xFF4FC3F7),
      accentColor: Color(0xFF0288D1),
      particleDensity: 3,
      particleLife: 0.4,
      particleSpeed: 30,
      glowSize: 0,
      cost: 0,
    ),
    OrbSkin(
      id: 'terra',
      label: 'Terra',
      rarity: OrbRarity.common,
      assetPath: AssetPaths.orbTerra,
      glowColor: Color(0xFFA1887F),
      accentColor: Color(0xFF5D4037),
      particleDensity: 5,
      particleLife: 0.5,
      particleSpeed: 35,
      glowSize: 2,
      cost: 750000,
    ),
    OrbSkin(
      id: 'verdant',
      label: 'Verdant',
      rarity: OrbRarity.common,
      assetPath: AssetPaths.orbVerdant,
      glowColor: Color(0xFF66BB6A),
      accentColor: Color(0xFF2E7D32),
      particleDensity: 6,
      particleLife: 0.6,
      particleSpeed: 45,
      glowSize: 4,
      cost: 1000000,
    ),
    OrbSkin(
      id: 'aqua',
      label: 'Aqua',
      rarity: OrbRarity.common,
      assetPath: AssetPaths.orbAqua,
      glowColor: Color(0xFF26C6DA),
      accentColor: Color(0xFF00838F),
      particleDensity: 9,
      particleLife: 0.7,
      particleSpeed: 55,
      glowSize: 6,
      cost: 2500000,
    ),
    OrbSkin(
      id: 'gale',
      label: 'Gale',
      rarity: OrbRarity.rare,
      assetPath: AssetPaths.orbGale,
      glowColor: Color(0xFFB3E5FC),
      accentColor: Color(0xFF0277BD),
      particleDensity: 12,
      particleLife: 0.65,
      particleSpeed: 75,
      glowSize: 8,
      cost: 4000000,
    ),
    OrbSkin(
      id: 'solar',
      label: 'Solar',
      rarity: OrbRarity.rare,
      assetPath: AssetPaths.orbSolar,
      glowColor: Color(0xFFFFEE58),
      accentColor: Color(0xFFFFA000),
      particleDensity: 10,
      particleLife: 0.8,
      particleSpeed: 60,
      glowSize: 8,
      cost: 5000000,
    ),
    OrbSkin(
      id: 'ember',
      label: 'Ember',
      rarity: OrbRarity.elite,
      assetPath: AssetPaths.orbEmber,
      glowColor: Color(0xFFEF5350),
      accentColor: Color(0xFFFF6D00),
      particleDensity: 15,
      particleLife: 1.0,
      particleSpeed: 80,
      glowSize: 12,
      cost: 15000000,
    ),
    OrbSkin(
      id: 'void',
      label: 'Void',
      rarity: OrbRarity.legendary,
      assetPath: AssetPaths.orbVoid,
      glowColor: Color(0xFFAB47BC),
      accentColor: Color(0xFF7C4DFF),
      particleDensity: 22,
      particleLife: 1.3,
      particleSpeed: 100,
      glowSize: 18,
      cost: 50000000,
    ),
    OrbSkin(
      id: 'blaze',
      label: 'Blaze',
      rarity: OrbRarity.elite,
      assetPath: AssetPaths.orbBlaze,
      glowColor: Color(0xFFFF7043),
      accentColor: Color(0xFFDD2C00),
      particleDensity: 18,
      particleLife: 1.1,
      particleSpeed: 90,
      glowSize: 14,
      cost: 20000000,
    ),
  ];

  static OrbSkin byId(String id) =>
      catalog.firstWhere((s) => s.id == id, orElse: () => catalog[0]);

  static String formatCost(int cost) {
    if (cost >= 1000000) {
      final m = cost / 1000000;
      return m == m.roundToDouble() ? '${m.round()}M' : '${m.toStringAsFixed(1)}M';
    }
    if (cost >= 1000) return '${cost ~/ 1000}K';
    return '$cost';
  }
}
