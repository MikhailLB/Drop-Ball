import 'package:flutter/material.dart';

import '../models/orb_skin.dart';
import '../resonance/board_engine.dart';
import '../utils/asset_paths.dart';

/// Renders the Resonance grid and forwards taps as (row, col).
class BoardView extends StatelessWidget {
  final BoardEngine engine;
  final OrbSkin orb;
  final void Function(int row, int col) onTap;
  final bool locked;

  const BoardView({
    super.key,
    required this.engine,
    required this.orb,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        const gap = 8.0;

        final cellW = (maxW - gap * (engine.cols - 1)) / engine.cols;
        final cellH = (maxH - gap * (engine.rows - 1)) / engine.rows;
        final cell = cellW < cellH ? cellW : cellH;

        final boardW = cell * engine.cols + gap * (engine.cols - 1);
        final boardH = cell * engine.rows + gap * (engine.rows - 1);

        return Center(
          child: SizedBox(
            width: boardW,
            height: boardH,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int r = 0; r < engine.rows; r++) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int c = 0; c < engine.cols; c++) ...[
                        _Cell(
                          size: cell,
                          orb: orb,
                          wall: engine.isWall(r, c),
                          lit: engine.isLit(r, c),
                          onTap: locked ? null : () => onTap(r, c),
                        ),
                        if (c < engine.cols - 1) const SizedBox(width: gap),
                      ],
                    ],
                  ),
                  if (r < engine.rows - 1) const SizedBox(height: gap),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  final double size;
  final OrbSkin orb;
  final bool wall;
  final bool lit;
  final VoidCallback? onTap;

  const _Cell({
    required this.size,
    required this.orb,
    required this.wall,
    required this.lit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (wall) {
      return SizedBox(
        width: size,
        height: size,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.02),
            border: Border.all(color: const Color(0x33FF5252)),
          ),
          padding: EdgeInsets.all(size * 0.16),
          child: Opacity(
            opacity: 0.5,
            child: Image.asset(AssetPaths.skull, fit: BoxFit.contain),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: lit
                ? orb.glowColor.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.025),
            border: Border.all(
              color: lit
                  ? orb.glowColor.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.10),
              width: lit ? 2 : 1,
            ),
            boxShadow: lit
                ? [
                    BoxShadow(
                      color: orb.glowColor.withValues(alpha: 0.55),
                      blurRadius: size * 0.32,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          padding: EdgeInsets.all(size * 0.12),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: lit ? 1.0 : 0.16,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              scale: lit ? 1.0 : 0.82,
              child: Image.asset(orb.assetPath, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
