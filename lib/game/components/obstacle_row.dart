import 'dart:math';
import 'package:flame/components.dart';
import '../../utils/constants.dart';
import '../gravity_rush_game.dart';
import 'death_zone.dart';
import 'pipe.dart';
import 'score_zone.dart';
import 'spike.dart';

enum GapType { safe, safe2x, death }

class ObstacleRow extends PositionComponent with HasGameReference<GravityRushGame> {
  final double gapWidth;
  final double gapCenterX;
  final GapType gapType;
  final bool hasLeftSpike;
  final bool hasRightSpike;
  final SpikeType leftSpikeType;
  final SpikeType rightSpikeType;
  bool _scored = false;

  ObstacleRow({
    required this.gapWidth,
    required this.gapCenterX,
    required this.gapType,
    this.hasLeftSpike = false,
    this.hasRightSpike = false,
    this.leftSpikeType = SpikeType.blue,
    this.rightSpikeType = SpikeType.red,
    required Vector2 position,
  }) : super(position: position);

  bool get scored => _scored;
  void markScored() => _scored = true;

  double get gapPositionX => gapCenterX;

  static ObstacleRow generate({
    required double screenWidth,
    required double gapWidth,
    required double redPipeChance,
    required double spikeChance,
    required double yPosition,
  }) {
    final rng = Random();

    final pipeW = GameConstants.pipeWidth;
    final minGapX = pipeW + gapWidth / 2 + 5;
    final maxGapX = screenWidth - pipeW - gapWidth / 2 - 5;
    final gapX = minGapX + rng.nextDouble() * (maxGapX - minGapX).clamp(0, double.infinity);

    GapType type;
    if (rng.nextDouble() < redPipeChance) {
      type = GapType.death;
    } else if (rng.nextDouble() < GameConstants.bonus2xChance) {
      type = GapType.safe2x;
    } else {
      type = GapType.safe;
    }

    return ObstacleRow(
      gapWidth: gapWidth,
      gapCenterX: gapX,
      gapType: type,
      hasLeftSpike: rng.nextDouble() < spikeChance,
      hasRightSpike: rng.nextDouble() < spikeChance,
      leftSpikeType: rng.nextBool() ? SpikeType.blue : SpikeType.red,
      rightSpikeType: rng.nextBool() ? SpikeType.blue : SpikeType.red,
      position: Vector2(0, yPosition),
    );
  }

  @override
  Future<void> onLoad() async {
    final cache = game.spriteCache;
    final screenW = game.size.x;
    final pipeW = GameConstants.pipeWidth;
    final pipeH = GameConstants.pipeHeight;

    final gapLeft = gapCenterX - gapWidth / 2;
    final gapRight = gapCenterX + gapWidth / 2;

    final isDeath = gapType == GapType.death;
    final rng = Random();

    Sprite getPipeSprite() {
      if (isDeath) {
        return rng.nextBool() ? cache.redPipeWithSkull : cache.redPipeWithoutSkull;
      }
      return cache.greenPipe;
    }

    // Left side: fill with pipe columns from screen edge to gap
    double x = 0;
    while (x + pipeW <= gapLeft) {
      add(Pipe(
        sprite: getPipeSprite(),
        position: Vector2(x, 0),
        size: Vector2(pipeW, pipeH),
      ));
      x += pipeW;
    }
    if (x < gapLeft) {
      add(Pipe(
        sprite: getPipeSprite(),
        position: Vector2(x, 0),
        size: Vector2(gapLeft - x, pipeH),
      ));
    }

    // Right side: fill with pipe columns from gap to screen edge
    x = gapRight;
    while (x + pipeW <= screenW) {
      add(Pipe(
        sprite: getPipeSprite(),
        position: Vector2(x, 0),
        size: Vector2(pipeW, pipeH),
      ));
      x += pipeW;
    }
    if (x < screenW) {
      add(Pipe(
        sprite: getPipeSprite(),
        position: Vector2(x, 0),
        size: Vector2(screenW - x, pipeH),
      ));
    }

    // Marker in center of gap
    final markerS = GameConstants.markerSize;
    final markerPos = Vector2(gapCenterX, pipeH / 2);

    if (isDeath) {
      add(DeathZone(
        sprite: cache.circleSkull,
        position: markerPos,
        size: Vector2.all(markerS),
      ));
    } else {
      add(ScoreZone(
        is2x: gapType == GapType.safe2x,
        sprite: gapType == GapType.safe2x ? cache.circle2x : cache.greenCircle,
        position: markerPos,
        size: Vector2.all(markerS),
      ));
    }

    // Spikes at gap edges
    final spikeW = GameConstants.spikeWidth;
    final spikeH = GameConstants.spikeHeight;

    if (hasLeftSpike) {
      add(Spike(
        sprite: leftSpikeType == SpikeType.blue ? cache.blueSpike : cache.redSpike,
        position: Vector2(gapLeft + spikeW / 2 + 2, pipeH - spikeH),
        size: Vector2(spikeW, spikeH),
      ));
    }
    if (hasRightSpike) {
      add(Spike(
        sprite: rightSpikeType == SpikeType.blue ? cache.blueSpike : cache.redSpike,
        position: Vector2(gapRight - spikeW / 2 - 2, pipeH - spikeH),
        size: Vector2(spikeW, spikeH),
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= game.difficultyManager.scrollSpeed * dt;

    if (position.y + GameConstants.pipeHeight < -50) {
      removeFromParent();
    }
  }
}
