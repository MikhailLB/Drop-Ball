import 'package:shared_preferences/shared_preferences.dart';

import '../models/orb_skin.dart';

/// Local, offline-only progress. No network, no accounts, no currency —
/// just level stars, unlocks and the chosen orb, persisted on device.
class ProgressStore {
  ProgressStore._();
  static final ProgressStore instance = ProgressStore._();

  static const _kStars = 'rs_stars_v1'; // "level:stars" csv
  static const _kActiveOrb = 'rs_active_orb_v1';
  static const _kTutorial = 'rs_tutorial_done_v1';
  static const _kDailyDate = 'rs_daily_date_v1'; // yyyymmdd of last solve
  static const _kDailyStreak = 'rs_daily_streak_v1';
  static const _kEndlessBest = 'rs_endless_best_v1';

  SharedPreferences? _prefs;
  final Map<int, int> _stars = {}; // level number -> best stars

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _prefs = p;
    _stars.clear();
    final raw = p.getStringList(_kStars) ?? const [];
    for (final entry in raw) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        final lvl = int.tryParse(parts[0]);
        final st = int.tryParse(parts[1]);
        if (lvl != null && st != null) _stars[lvl] = st;
      }
    }
  }

  int starsFor(int level) => _stars[level] ?? 0;
  bool isCleared(int level) => _stars.containsKey(level);

  int get totalStars =>
      _stars.values.fold(0, (sum, s) => sum + s);

  /// A level is unlocked if it's the first one or the previous one is cleared.
  bool isUnlocked(int level) => level <= 1 || isCleared(level - 1);

  Future<void> recordResult(int level, int stars) async {
    final best = _stars[level] ?? 0;
    if (stars <= best) return;
    _stars[level] = stars;
    await _prefs?.setStringList(
      _kStars,
      _stars.entries.map((e) => '${e.key}:${e.value}').toList(),
    );
  }

  // ── Orb selection / unlocks ────────────────────────────────────────────
  String get activeOrbId => _prefs?.getString(_kActiveOrb) ?? 'frost';

  OrbSkin get activeOrb => OrbSkin.byId(activeOrbId);

  bool isOrbUnlocked(OrbSkin orb) => totalStars >= orb.unlockStars;

  Future<void> setActiveOrb(String id) async {
    await _prefs?.setString(_kActiveOrb, id);
  }

  // ── Onboarding ─────────────────────────────────────────────────────────
  bool get tutorialDone => _prefs?.getBool(_kTutorial) ?? false;

  Future<void> markTutorialDone() async {
    await _prefs?.setBool(_kTutorial, true);
  }

  // ── Daily challenge ────────────────────────────────────────────────────
  int get _lastDailyKey => _prefs?.getInt(_kDailyDate) ?? 0;
  int get dailyStreak => _prefs?.getInt(_kDailyStreak) ?? 0;

  bool dailyDoneFor(int todayKey) => _lastDailyKey == todayKey;

  /// Records today's daily solve and maintains the streak. [todayKey] and
  /// [yesterdayKey] are yyyymmdd integers.
  Future<void> markDailySolved(int todayKey, int yesterdayKey) async {
    if (_lastDailyKey == todayKey) return;
    final newStreak = (_lastDailyKey == yesterdayKey) ? dailyStreak + 1 : 1;
    await _prefs?.setInt(_kDailyDate, todayKey);
    await _prefs?.setInt(_kDailyStreak, newStreak);
  }

  // ── Endless ────────────────────────────────────────────────────────────
  int get endlessBest => _prefs?.getInt(_kEndlessBest) ?? 0;

  Future<void> recordEndless(int cleared) async {
    if (cleared > endlessBest) {
      await _prefs?.setInt(_kEndlessBest, cleared);
    }
  }
}
