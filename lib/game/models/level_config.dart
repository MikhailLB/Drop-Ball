import 'package:flutter/material.dart';

class LevelConfig {
  final int number;
  final String name;
  final int pegRows;
  final int pegColsWide;
  final int skullCount;
  final double movingPegChance;
  final double movingPegAmplitude;
  final double minMultiplier;
  final double maxMultiplier;
  final int targetScore;
  final int lives;
  final Color themeColor;
  final String sphereSkinId;

  const LevelConfig({
    required this.number,
    required this.name,
    required this.pegRows,
    required this.pegColsWide,
    required this.skullCount,
    required this.movingPegChance,
    required this.movingPegAmplitude,
    required this.minMultiplier,
    required this.maxMultiplier,
    required this.targetScore,
    required this.lives,
    required this.themeColor,
    required this.sphereSkinId,
  });
}

class Levels {
  Levels._();

  static const List<LevelConfig> all = [
    LevelConfig(
      number: 1,
      name: 'Beginner',
      pegRows: 8,
      pegColsWide: 7,
      skullCount: 1,
      movingPegChance: 0.0,
      movingPegAmplitude: 0.0,
      minMultiplier: 1.0,
      maxMultiplier: 2.0,
      targetScore: 200,
      lives: 3,
      themeColor: Color(0xFF4FC3F7),
      sphereSkinId: 'blue',
    ),
    LevelConfig(
      number: 2,
      name: 'Explorer',
      pegRows: 9,
      pegColsWide: 7,
      skullCount: 1,
      movingPegChance: 0.0,
      movingPegAmplitude: 0.0,
      minMultiplier: 1.0,
      maxMultiplier: 3.0,
      targetScore: 350,
      lives: 3,
      themeColor: Color(0xFF4DB6AC),
      sphereSkinId: 'aqua',
    ),
    LevelConfig(
      number: 3,
      name: 'Naturalist',
      pegRows: 10,
      pegColsWide: 8,
      skullCount: 2,
      movingPegChance: 0.0,
      movingPegAmplitude: 0.0,
      minMultiplier: 1.0,
      maxMultiplier: 4.0,
      targetScore: 500,
      lives: 3,
      themeColor: Color(0xFF81C784),
      sphereSkinId: 'green',
    ),
    LevelConfig(
      number: 4,
      name: 'Earthbound',
      pegRows: 10,
      pegColsWide: 8,
      skullCount: 2,
      movingPegChance: 0.10,
      movingPegAmplitude: 12.0,
      minMultiplier: 1.0,
      maxMultiplier: 5.0,
      targetScore: 700,
      lives: 3,
      themeColor: Color(0xFFA1887F),
      sphereSkinId: 'ground',
    ),
    LevelConfig(
      number: 5,
      name: 'Windrunner',
      pegRows: 11,
      pegColsWide: 9,
      skullCount: 3,
      movingPegChance: 0.15,
      movingPegAmplitude: 14.0,
      minMultiplier: 1.0,
      maxMultiplier: 6.0,
      targetScore: 1000,
      lives: 3,
      themeColor: Color(0xFFB0BEC5),
      sphereSkinId: 'air',
    ),
    LevelConfig(
      number: 6,
      name: 'Sunstrike',
      pegRows: 11,
      pegColsWide: 9,
      skullCount: 3,
      movingPegChance: 0.20,
      movingPegAmplitude: 15.0,
      minMultiplier: 1.5,
      maxMultiplier: 7.0,
      targetScore: 1400,
      lives: 3,
      themeColor: Color(0xFFFFD54F),
      sphereSkinId: 'yellow',
    ),
    LevelConfig(
      number: 7,
      name: 'Inferno',
      pegRows: 12,
      pegColsWide: 9,
      skullCount: 4,
      movingPegChance: 0.25,
      movingPegAmplitude: 16.0,
      minMultiplier: 2.0,
      maxMultiplier: 9.0,
      targetScore: 1800,
      lives: 3,
      themeColor: Color(0xFFFF7043),
      sphereSkinId: 'fire',
    ),
    LevelConfig(
      number: 8,
      name: 'Crimson Tide',
      pegRows: 12,
      pegColsWide: 9,
      skullCount: 4,
      movingPegChance: 0.30,
      movingPegAmplitude: 17.0,
      minMultiplier: 2.0,
      maxMultiplier: 11.0,
      targetScore: 2400,
      lives: 3,
      themeColor: Color(0xFFEF5350),
      sphereSkinId: 'red',
    ),
    LevelConfig(
      number: 9,
      name: 'Void Gate',
      pegRows: 12,
      pegColsWide: 9,
      skullCount: 5,
      movingPegChance: 0.35,
      movingPegAmplitude: 18.0,
      minMultiplier: 2.5,
      maxMultiplier: 13.0,
      targetScore: 3000,
      lives: 3,
      themeColor: Color(0xFFAB47BC),
      sphereSkinId: 'purple',
    ),
    LevelConfig(
      number: 10,
      name: 'Elemental Apex',
      pegRows: 12,
      pegColsWide: 9,
      skullCount: 5,
      movingPegChance: 0.40,
      movingPegAmplitude: 20.0,
      minMultiplier: 3.0,
      maxMultiplier: 15.0,
      targetScore: 4000,
      lives: 3,
      themeColor: Color(0xFFE040FB),
      sphereSkinId: 'purple',
    ),
  ];

  static LevelConfig get(int levelNumber) {
    final idx = (levelNumber - 1).clamp(0, all.length - 1);
    return all[idx];
  }

  static int get count => all.length;
}
