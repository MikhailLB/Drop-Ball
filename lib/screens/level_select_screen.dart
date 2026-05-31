import 'package:flutter/material.dart';

import '../resonance/level_book.dart';
import '../services/progress_store.dart';
import '../widgets/aurora_background.dart';

class LevelSelectScreen extends StatelessWidget {
  final void Function(int level) onPick;
  final VoidCallback onBack;

  const LevelSelectScreen({
    super.key,
    required this.onPick,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final store = ProgressStore.instance;

    return AuroraBackground(
      tint: const Color(0xFF7C4DFF),
      child: SafeArea(
        child: Column(
          children: [
            _header(store),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                itemCount: LevelBook.chapters.length,
                itemBuilder: (context, i) =>
                    _chapterSection(LevelBook.chapters[i], store),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(ProgressStore store) => Padding(
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
            const Text('LEVELS',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 5)),
            const Spacer(),
            Row(children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 18),
              const SizedBox(width: 5),
              Text('${store.totalStars}',
                  style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ]),
          ],
        ),
      );

  Widget _chapterSection(Chapter chapter, ProgressStore store) {
    final levels = LevelBook.levelsIn(chapter.index);
    final earned =
        levels.fold(0, (sum, l) => sum + store.starsFor(l.number));
    final maxStars = levels.length * 3;
    final chapterUnlocked = store.isUnlocked(levels.first.number);

    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 26,
                decoration: BoxDecoration(
                  color: chapterUnlocked ? chapter.tint : Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: chapterUnlocked
                      ? [BoxShadow(color: chapter.tint, blurRadius: 10)]
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Text(chapter.name,
                  style: TextStyle(
                      color: chapterUnlocked
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
              const Spacer(),
              if (chapterUnlocked) ...[
                const Icon(Icons.star_rounded,
                    color: Color(0xFFFFD54F), size: 14),
                const SizedBox(width: 3),
                Text('$earned/$maxStars',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ] else
                const Icon(Icons.lock_outline_rounded,
                    color: Colors.white30, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemCount: levels.length,
            itemBuilder: (context, i) => _card(levels[i], store),
          ),
        ],
      ),
    );
  }

  Widget _card(LevelSpec spec, ProgressStore store) {
    final unlocked = store.isUnlocked(spec.number);
    final stars = store.starsFor(spec.number);
    final tint = unlocked ? spec.tint : Colors.white24;

    return GestureDetector(
      onTap: unlocked ? () => onPick(spec.number) : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: unlocked
              ? tint.withValues(alpha: 0.09)
              : Colors.white.withValues(alpha: 0.02),
          border: Border.all(
            color: unlocked
                ? tint.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.08),
            width: 1.4,
          ),
          boxShadow: unlocked && stars > 0
              ? [BoxShadow(color: tint.withValues(alpha: 0.16), blurRadius: 10)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!unlocked)
              const Icon(Icons.lock_outline, color: Colors.white30, size: 20)
            else
              Text('${spec.number}',
                  style: TextStyle(
                      color: tint,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(color: tint, blurRadius: 12)])),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Icon(
                  i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 11,
                  color: i < stars
                      ? const Color(0xFFFFD54F)
                      : Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
