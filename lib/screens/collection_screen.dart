import 'package:flutter/material.dart';

import '../models/orb_skin.dart';
import '../services/progress_store.dart';
import '../widgets/aurora_background.dart';

class CollectionScreen extends StatefulWidget {
  final VoidCallback onBack;
  const CollectionScreen({super.key, required this.onBack});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = ProgressStore.instance.activeOrbId;
  }

  Future<void> _pick(OrbSkin orb) async {
    if (!ProgressStore.instance.isOrbUnlocked(orb)) return;
    await ProgressStore.instance.setActiveOrb(orb.id);
    setState(() => _selected = orb.id);
  }

  @override
  Widget build(BuildContext context) {
    final store = ProgressStore.instance;
    final active = OrbSkin.byId(_selected);

    return AuroraBackground(
      tint: active.glowColor,
      child: SafeArea(
        child: Column(
          children: [
            _header(store),
            _hero(active, store),
            Expanded(child: _grid(store)),
          ],
        ),
      ),
    );
  }

  Widget _header(ProgressStore store) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
        child: Row(
          children: [
            GestureDetector(
              onTap: widget.onBack,
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
            const Text('ORB COLLECTION',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3)),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFFFD54F), size: 18),
                const SizedBox(width: 5),
                Text('${store.totalStars}',
                    style: const TextStyle(
                        color: Color(0xFFFFD54F),
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      );

  Widget _hero(OrbSkin orb, ProgressStore store) {
    final unlocked = store.isOrbUnlocked(orb);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Container(
            width: 124,
            height: 124,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: orb.glowColor.withValues(alpha: 0.4),
                    blurRadius: 38,
                    spreadRadius: 4),
              ],
            ),
            child: Image.asset(orb.assetPath),
          ),
          const SizedBox(height: 12),
          Text(orb.label.toUpperCase(),
              style: TextStyle(
                  color: orb.glowColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  shadows: [Shadow(color: orb.glowColor, blurRadius: 16)])),
          const SizedBox(height: 4),
          Text(
            unlocked
                ? '${orb.element} · selected'
                : 'Unlocks at ${orb.unlockStars} ★',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _grid(ProgressStore store) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: OrbSkin.catalog.length,
        itemBuilder: (context, i) {
          final orb = OrbSkin.catalog[i];
          final unlocked = store.isOrbUnlocked(orb);
          final isSel = orb.id == _selected;

          return GestureDetector(
            onTap: () => _pick(orb),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: isSel
                    ? orb.glowColor.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.04),
                border: Border.all(
                  color: isSel
                      ? orb.glowColor
                      : Colors.white.withValues(alpha: 0.1),
                  width: isSel ? 2.5 : 1,
                ),
                boxShadow: isSel
                    ? [
                        BoxShadow(
                            color: orb.glowColor.withValues(alpha: 0.4),
                            blurRadius: 16)
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Opacity(
                      opacity: unlocked ? 1 : 0.25,
                      child: Image.asset(orb.assetPath),
                    ),
                  ),
                  if (!unlocked)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_rounded,
                            color: Colors.white70, size: 22),
                        const SizedBox(height: 2),
                        Text('${orb.unlockStars}★',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      );
}
