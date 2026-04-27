import 'dart:ui';
import '../utils/asset_paths.dart';

enum SkinTier { basic, common, rare, epic, legendary }

class SkinData {
  final String id;
  final String name;
  final SkinTier tier;
  final String assetPath;
  final Color primaryColor;
  final Color secondaryColor;
  final int particleDensity;
  final double particleLifespan;
  final double particleSpeed;
  final double glowRadius;
  final int price;

  const SkinData({
    required this.id,
    required this.name,
    required this.tier,
    required this.assetPath,
    required this.primaryColor,
    required this.secondaryColor,
    required this.particleDensity,
    required this.particleLifespan,
    required this.particleSpeed,
    required this.glowRadius,
    this.price = 0,
  });

  static const List<SkinData> allSkins = [
    SkinData(
      id: 'blue',
      name: 'Azure',
      tier: SkinTier.basic,
      assetPath: AssetPaths.blueSphere,
      primaryColor: Color(0xFF4FC3F7),
      secondaryColor: Color(0xFF0288D1),
      particleDensity: 3,
      particleLifespan: 0.4,
      particleSpeed: 30,
      glowRadius: 0,
      price: 0,
    ),
    SkinData(
      id: 'ground',
      name: 'Terra',
      tier: SkinTier.common,
      assetPath: AssetPaths.groundSphere,
      primaryColor: Color(0xFFA1887F),
      secondaryColor: Color(0xFF5D4037),
      particleDensity: 5,
      particleLifespan: 0.5,
      particleSpeed: 35,
      glowRadius: 2,
      price: 750000,
    ),
    SkinData(
      id: 'green',
      name: 'Emerald',
      tier: SkinTier.common,
      assetPath: AssetPaths.greenSphere,
      primaryColor: Color(0xFF66BB6A),
      secondaryColor: Color(0xFF2E7D32),
      particleDensity: 6,
      particleLifespan: 0.6,
      particleSpeed: 45,
      glowRadius: 4,
      price: 1000000,
    ),
    SkinData(
      id: 'aqua',
      name: 'Tidal',
      tier: SkinTier.common,
      assetPath: AssetPaths.aquaSphere,
      primaryColor: Color(0xFF26C6DA),
      secondaryColor: Color(0xFF00838F),
      particleDensity: 9,
      particleLifespan: 0.7,
      particleSpeed: 55,
      glowRadius: 6,
      price: 2500000,
    ),
    SkinData(
      id: 'air',
      name: 'Tempest',
      tier: SkinTier.rare,
      assetPath: AssetPaths.airSphere,
      primaryColor: Color(0xFFB3E5FC),
      secondaryColor: Color(0xFF0277BD),
      particleDensity: 12,
      particleLifespan: 0.65,
      particleSpeed: 75,
      glowRadius: 8,
      price: 4000000,
    ),
    SkinData(
      id: 'yellow',
      name: 'Solar',
      tier: SkinTier.rare,
      assetPath: AssetPaths.yellowSphere,
      primaryColor: Color(0xFFFFEE58),
      secondaryColor: Color(0xFFFFA000),
      particleDensity: 10,
      particleLifespan: 0.8,
      particleSpeed: 60,
      glowRadius: 8,
      price: 5000000,
    ),
    SkinData(
      id: 'red',
      name: 'Inferno',
      tier: SkinTier.epic,
      assetPath: AssetPaths.redSphere,
      primaryColor: Color(0xFFEF5350),
      secondaryColor: Color(0xFFFF6D00),
      particleDensity: 15,
      particleLifespan: 1.0,
      particleSpeed: 80,
      glowRadius: 12,
      price: 15000000,
    ),
    SkinData(
      id: 'purple',
      name: 'Nebula',
      tier: SkinTier.legendary,
      assetPath: AssetPaths.purpleSphere,
      primaryColor: Color(0xFFAB47BC),
      secondaryColor: Color(0xFF7C4DFF),
      particleDensity: 22,
      particleLifespan: 1.3,
      particleSpeed: 100,
      glowRadius: 18,
      price: 50000000,
    ),
  ];

  static SkinData getById(String id) {
    return allSkins.firstWhere((s) => s.id == id, orElse: () => allSkins[0]);
  }

  static String formatPrice(int price) {
    if (price >= 1000000) {
      final m = price / 1000000;
      return m == m.roundToDouble()
          ? '${m.round()}M'
          : '${m.toStringAsFixed(1)}M';
    }
    if (price >= 1000) return '${price ~/ 1000}K';
    return '$price';
  }
}
