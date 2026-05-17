import 'dart:ui';
import '../utils/media_paths.dart';

enum SkinGrade { basic, common, rare, epic, legendary }

class BallSkin {
  final String id;
  final String name;
  final SkinGrade tier;
  final String assetPath;
  final Color primaryColor;
  final Color secondaryColor;
  final int particleDensity;
  final double particleLifespan;
  final double particleSpeed;
  final double glowRadius;
  final int price;

  const BallSkin({
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

  static const List<BallSkin> allSkins = [
    BallSkin(
      id: 'blue',
      name: 'Azure',
      tier: SkinGrade.basic,
      assetPath: MediaPaths.blueSphere,
      primaryColor: Color(0xFF4FC3F7),
      secondaryColor: Color(0xFF0288D1),
      particleDensity: 3,
      particleLifespan: 0.4,
      particleSpeed: 30,
      glowRadius: 0,
      price: 0,
    ),
    BallSkin(
      id: 'ground',
      name: 'Terra',
      tier: SkinGrade.common,
      assetPath: MediaPaths.groundSphere,
      primaryColor: Color(0xFFA1887F),
      secondaryColor: Color(0xFF5D4037),
      particleDensity: 5,
      particleLifespan: 0.5,
      particleSpeed: 35,
      glowRadius: 2,
      price: 750000,
    ),
    BallSkin(
      id: 'green',
      name: 'Emerald',
      tier: SkinGrade.common,
      assetPath: MediaPaths.greenSphere,
      primaryColor: Color(0xFF66BB6A),
      secondaryColor: Color(0xFF2E7D32),
      particleDensity: 6,
      particleLifespan: 0.6,
      particleSpeed: 45,
      glowRadius: 4,
      price: 1000000,
    ),
    BallSkin(
      id: 'aqua',
      name: 'Tidal',
      tier: SkinGrade.common,
      assetPath: MediaPaths.aquaSphere,
      primaryColor: Color(0xFF26C6DA),
      secondaryColor: Color(0xFF00838F),
      particleDensity: 9,
      particleLifespan: 0.7,
      particleSpeed: 55,
      glowRadius: 6,
      price: 2500000,
    ),
    BallSkin(
      id: 'air',
      name: 'Tempest',
      tier: SkinGrade.rare,
      assetPath: MediaPaths.airSphere,
      primaryColor: Color(0xFFB3E5FC),
      secondaryColor: Color(0xFF0277BD),
      particleDensity: 12,
      particleLifespan: 0.65,
      particleSpeed: 75,
      glowRadius: 8,
      price: 4000000,
    ),
    BallSkin(
      id: 'yellow',
      name: 'Solar',
      tier: SkinGrade.rare,
      assetPath: MediaPaths.yellowSphere,
      primaryColor: Color(0xFFFFEE58),
      secondaryColor: Color(0xFFFFA000),
      particleDensity: 10,
      particleLifespan: 0.8,
      particleSpeed: 60,
      glowRadius: 8,
      price: 5000000,
    ),
    BallSkin(
      id: 'red',
      name: 'Inferno',
      tier: SkinGrade.epic,
      assetPath: MediaPaths.redSphere,
      primaryColor: Color(0xFFEF5350),
      secondaryColor: Color(0xFFFF6D00),
      particleDensity: 15,
      particleLifespan: 1.0,
      particleSpeed: 80,
      glowRadius: 12,
      price: 15000000,
    ),
    BallSkin(
      id: 'purple',
      name: 'Nebula',
      tier: SkinGrade.legendary,
      assetPath: MediaPaths.purpleSphere,
      primaryColor: Color(0xFFAB47BC),
      secondaryColor: Color(0xFF7C4DFF),
      particleDensity: 22,
      particleLifespan: 1.3,
      particleSpeed: 100,
      glowRadius: 18,
      price: 50000000,
    ),
  ];

  static BallSkin getById(String id) {
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
