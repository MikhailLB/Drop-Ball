import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'level_book.dart';

enum GameMode { campaign, daily, endless }

/// Builds puzzle specs for the non-campaign modes.
class ModeFactory {
  ModeFactory._();

  static const Color dailyTint = Color(0xFF7C4DFF);
  static const Color endlessTint = Color(0xFFFF7043);

  /// One deterministic puzzle per calendar day.
  static LevelSpec daily(DateTime date) {
    final key = date.year * 10000 + date.month * 100 + date.day;
    final rng = math.Random(key);
    const rules = ToggleRule.values;
    final rule = rules[key % rules.length];
    final scramble = 12 + rng.nextInt(8);
    return LevelSpec(
      number: 0,
      title: 'Daily',
      rows: 5,
      cols: 5,
      seed: key,
      scramble: scramble,
      tint: dailyTint,
      chapter: 0,
      rule: rule,
    );
  }

  static int dailyKey(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  /// Endless: difficulty ramps with [step] (0-based). Grids grow, scrambles
  /// deepen and tougher rules cycle in.
  static LevelSpec endless(int step) {
    final size = _endlessSize(step);
    final r = size.$1, c = size.$2;
    final cells = r * c;

    var scramble = 4 + step * 2;
    final cap = (cells * 0.7).floor();
    if (scramble > cap) scramble = cap;
    if (scramble < 3) scramble = 3;

    final seed = 90001 + step * 131;

    ToggleRule rule;
    if (step < 4) {
      rule = ToggleRule.cross;
    } else if (step < 9) {
      rule = step.isEven ? ToggleRule.cross : ToggleRule.diagonal;
    } else {
      rule = const [
        ToggleRule.cross,
        ToggleRule.diagonal,
        ToggleRule.star,
      ][step % 3];
    }

    return LevelSpec(
      number: 0,
      title: 'Endless',
      rows: r,
      cols: c,
      seed: seed,
      scramble: scramble,
      tint: endlessTint,
      chapter: 0,
      rule: rule,
    );
  }

  static (int, int) _endlessSize(int step) {
    if (step < 3) return (3, 3);
    if (step < 6) return (4, 4);
    if (step < 10) return (5, 4);
    if (step < 15) return (5, 5);
    if (step < 22) return (6, 5);
    return (6, 6);
  }

  /// Move budget for timed/limited modes, derived from the solved par.
  static int budgetFor(int par) => par + (par * 0.75).ceil() + 2;
}
