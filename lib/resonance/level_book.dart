import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Defines which neighbours a tap flips. Every rule is an involution (tapping a
/// cell twice cancels out), so generating a board by scrambling the solved
/// state stays guaranteed-solvable regardless of the rule.
enum ToggleRule {
  /// Self + 4 orthogonal neighbours (classic).
  cross,

  /// Self + 4 diagonal neighbours.
  diagonal,

  /// Self + all 8 surrounding neighbours.
  star,
}

extension ToggleRuleInfo on ToggleRule {
  String get glyph => switch (this) {
        ToggleRule.cross => '+',
        ToggleRule.diagonal => '✕',
        ToggleRule.star => '✦',
      };

  String get label => switch (this) {
        ToggleRule.cross => 'CROSS',
        ToggleRule.diagonal => 'DIAGONAL',
        ToggleRule.star => 'STAR',
      };
}

/// A single Resonance puzzle definition. Boards are generated deterministically
/// from [seed] + [scramble] so every player sees the same puzzle and the
/// computed par is meaningful.
class LevelSpec {
  final int number;
  final String title;
  final int rows;
  final int cols;
  final int seed;
  final int scramble;

  /// Flat row-major indices that are inert "skull" walls (board shaping).
  final List<int> walls;

  /// Accent colour used for this level's UI tint (inherited from its chapter).
  final Color tint;

  /// Index of the owning chapter (0-based).
  final int chapter;

  /// Which neighbours a tap flips.
  final ToggleRule rule;

  const LevelSpec({
    required this.number,
    required this.title,
    required this.rows,
    required this.cols,
    required this.seed,
    required this.scramble,
    required this.tint,
    required this.chapter,
    this.walls = const [],
    this.rule = ToggleRule.cross,
  });
}

class Chapter {
  final int index;
  final String name;
  final Color tint;
  final String orbId;

  const Chapter({
    required this.index,
    required this.name,
    required this.tint,
    required this.orbId,
  });
}

/// The campaign: 6 themed chapters × 8 levels = 48 puzzles. Difficulty grows
/// via larger grids, deeper scrambles and skull walls that carve shapes.
class LevelBook {
  LevelBook._();

  static const int levelsPerChapter = 8;

  static const List<Chapter> chapters = [
    Chapter(index: 0, name: 'FROST REACHES', tint: Color(0xFF4FC3F7), orbId: 'frost'),
    Chapter(index: 1, name: 'TIDAL HOLLOW', tint: Color(0xFF26C6DA), orbId: 'aqua'),
    Chapter(index: 2, name: 'VERDANT WILDS', tint: Color(0xFF66BB6A), orbId: 'verdant'),
    Chapter(index: 3, name: 'EMBERFORGE', tint: Color(0xFFFF7043), orbId: 'blaze'),
    Chapter(index: 4, name: 'STORMSPIRE', tint: Color(0xFFFFD54F), orbId: 'solar'),
    Chapter(index: 5, name: 'VOID NEXUS', tint: Color(0xFFAB47BC), orbId: 'void'),
  ];

  static const List<String> _titles = [
    'Spark', 'Ripple', 'Drift', 'Bloom', 'Glint', 'Pulse', 'Weave', 'Cascade',
    'Lattice', 'Vortex', 'Prism', 'Cinder', 'Halo', 'Fracture', 'Mirage', 'Eclipse',
  ];

  static final List<LevelSpec> all = _build();

  static int get count => all.length;

  static LevelSpec at(int number) =>
      all[(number - 1).clamp(0, all.length - 1)];

  static int chapterOf(int number) => (number - 1) ~/ levelsPerChapter;

  static List<LevelSpec> levelsIn(int chapterIndex) => all
      .where((l) => l.chapter == chapterIndex)
      .toList(growable: false);

  static List<LevelSpec> _build() {
    final out = <LevelSpec>[];
    final total = chapters.length * levelsPerChapter;

    for (var n = 1; n <= total; n++) {
      final ch = (n - 1) ~/ levelsPerChapter;
      final within = (n - 1) % levelsPerChapter;
      final chapter = chapters[ch];

      // Grid grows across chapters, and a touch within each chapter.
      final big = within >= 4 ? 1 : 0;
      final size = _sizeFor(ch, big);
      final r = size.$1, c = size.$2;
      final cells = r * c;

      // Scramble scales with global progression but is capped to the board.
      var scramble = 3 + n;
      final cap = (cells * 0.7).floor();
      if (scramble > cap) scramble = cap;
      if (scramble < 3) scramble = 3;

      final seed = n * 977 + 13;

      // Walls appear from chapter 3 onward, growing slowly, always symmetric.
      final walls = _walls(ch, within, r, c, seed);

      out.add(LevelSpec(
        number: n,
        title: _titles[within % _titles.length],
        rows: r,
        cols: c,
        seed: seed,
        scramble: scramble,
        walls: walls,
        tint: chapter.tint,
        chapter: ch,
        rule: _ruleFor(ch, within),
      ));
    }
    return out;
  }

  static ToggleRule _ruleFor(int chapter, int within) {
    // Chapters 0-2 teach the classic cross. Diagonal arrives in chapter 3,
    // the star (8-way) in chapter 4, and the final chapter alternates the
    // two hardest rules for maximum variety.
    switch (chapter) {
      case 0:
      case 1:
      case 2:
        return ToggleRule.cross;
      case 3:
        return within >= 4 ? ToggleRule.diagonal : ToggleRule.cross;
      case 4:
        return within >= 4 ? ToggleRule.star : ToggleRule.diagonal;
      default:
        return within.isEven ? ToggleRule.star : ToggleRule.diagonal;
    }
  }

  static (int, int) _sizeFor(int chapter, int big) {
    switch (chapter) {
      case 0:
        return big == 1 ? (4, 3) : (3, 3);
      case 1:
        return big == 1 ? (4, 4) : (4, 3);
      case 2:
        return big == 1 ? (5, 4) : (4, 4);
      case 3:
        return big == 1 ? (5, 5) : (5, 4);
      case 4:
        return big == 1 ? (6, 5) : (5, 5);
      default:
        return big == 1 ? (6, 6) : (6, 5);
    }
  }

  static List<int> _walls(int chapter, int within, int r, int c, int seed) {
    if (chapter < 2) return const [];
    var count = (chapter - 1) + (within >= 4 ? 1 : 0);
    final maxWalls = (r * c) ~/ 6;
    if (count > maxWalls) count = maxWalls;
    if (count <= 0) return const [];

    final rng = math.Random(seed);
    final picked = <int>{};
    var guard = 0;
    while (picked.length < count && guard < 200) {
      guard++;
      final rr = rng.nextInt(r);
      final cc = rng.nextInt(c);
      final idx = rr * c + cc;
      final mirror = rr * c + (c - 1 - cc); // horizontal symmetry
      picked.add(idx);
      if (picked.length < count) picked.add(mirror);
    }
    return picked.toList(growable: false);
  }
}
