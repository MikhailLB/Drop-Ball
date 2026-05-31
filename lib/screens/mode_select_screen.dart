import 'package:flutter/material.dart';

import '../resonance/game_mode.dart';
import '../resonance/level_book.dart';
import '../services/progress_store.dart';
import '../widgets/aurora_background.dart';

class ModeSelectScreen extends StatelessWidget {
  final void Function(GameMode mode, int index) onOpen;
  final void Function(int level) onCampaign;
  final VoidCallback onBack;

  const ModeSelectScreen({
    super.key,
    required this.onOpen,
    required this.onCampaign,
    required this.onBack,
  });

  int _continueLevel(ProgressStore store) {
    for (var i = 1; i <= LevelBook.count; i++) {
      if (store.isUnlocked(i) && !store.isCleared(i)) return i;
    }
    return LevelBook.count;
  }

  @override
  Widget build(BuildContext context) {
    final store = ProgressStore.instance;
    final cleared = List.generate(LevelBook.count, (i) => i + 1)
        .where(store.isCleared)
        .length;
    final today = ModeFactory.dailyKey(DateTime.now());
    final dailyDone = store.dailyDoneFor(today);

    return AuroraBackground(
      tint: const Color(0xFF26C6DA),
      child: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                children: [
                  _modeCard(
                    icon: Icons.map_rounded,
                    title: 'CAMPAIGN',
                    subtitle: '$cleared / ${LevelBook.count} levels cleared',
                    accent: const Color(0xFF4FC3F7),
                    badge: '$cleared/${LevelBook.count}',
                    onTap: () => onCampaign(_continueLevel(store)),
                  ),
                  const SizedBox(height: 16),
                  _modeCard(
                    icon: Icons.today_rounded,
                    title: 'DAILY CHALLENGE',
                    subtitle: dailyDone
                        ? 'Solved today · come back tomorrow'
                        : 'A fresh puzzle every day',
                    accent: ModeFactory.dailyTint,
                    badge: '🔥 ${store.dailyStreak}',
                    onTap: () => onOpen(GameMode.daily, 0),
                  ),
                  const SizedBox(height: 16),
                  _modeCard(
                    icon: Icons.all_inclusive_rounded,
                    title: 'ENDLESS',
                    subtitle: 'Survive harder boards on a move budget',
                    accent: ModeFactory.endlessTint,
                    badge: 'BEST ${store.endlessBest}',
                    onTap: () => onOpen(GameMode.endless, 0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white70, size: 18),
              ),
            ),
            const Spacer(),
            const Text('GAME MODES',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4)),
            const Spacer(),
            const SizedBox(width: 44),
          ],
        ),
      );

  Widget _modeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required String badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.18),
              Colors.white.withValues(alpha: 0.03),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.18), blurRadius: 18),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.18),
                border: Border.all(color: accent.withValues(alpha: 0.6)),
              ),
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(color: accent, blurRadius: 12)
                          ])),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                          height: 1.25)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(badge,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
