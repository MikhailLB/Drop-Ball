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
  final double gapPositionX;
  final GapType gapType;
  final bool hasLeftSpike;
  final bool hasRightSpike;
  final SpikeType leftSpikeType;
  final SpikeType rightSpikeType;
  bool _scored = false;

  ObstacleRow({
    required this.gapWidth,
    required this.gapPositionX,
    required this.gapType,
    this.hasLeftSpike = false,
    this.hasRightSpike = false,
    this.leftSpikeType = SpikeType.blue,
    this.rightSpikeType = SpikeType.red,
    required Vector2 position,
  }) : super(position: position);

  bool get scored => _scored;
  void markScored() => _scored = true;

  static ObstacleRow generate({
    required double screenWidth,
    required double gapWidth,
    required double redPipeChance,
    required double spikeChance,
    required double yPosition,
  }) {
    final rng = Random();
    final minGapX = gapWidth / 2 + 20;
    final maxGapX = screenWidth - gapWidth / 2 - 20;
    final gapX = minGapX + rng.nextDouble() * (maxGapX - minGapX);

    GapType type;
    if (rng.nextDouble() < redPipeChance) {
      type = GapType.death;
    } else if (rng.nextDouble() < GameConstants.bonus2xChance) {
      type = GapType.safe2x;
    } else {
      type = GapType.safe;
    }

    final hasLeft = rng.nextDouble() < spikeChance;
    final hasRight = rng.nextDouble() < spikeChance;

    return ObstacleRow(
      gapWidth: gapWidth,
      gapPositionX: gapX,
      gapType: type,
      hasLeftSpike: hasLeft,
      hasRightSpike: hasRight,
      leftSpikeType: rng.nextBool() ? SpikeType.blue : SpikeType.red,
      rightSpikeType: rng.nextBool() ? SpikeType.blue : SpikeType.red,
      position: Vector2(0, yPosition),
    );
  }

  @override
  Future<void> onLoad() async {
    final screenWidth = game.size.x;
    final pipeHeight = GameConstants.pipeHeight;
    final gapLeft = gapPositionX - gapWidth / 2;
    final gapRight = gapPositionX + gapWidth / 2;

    final pipeType = gapType == GapType.death
        ? (Random().nextBool() ? PipeType.redWithSkull : PipeType.redWithoutSkull)
        : PipeType.green;

    if (gapLeft > 0) {
      add(Pipe(
        pipeType: pipeType,
        position: Vector2(0, 0),
        size: Vector2(gapLeft, pipeHeight),
      ));
    }

    if (gapRight < screenWidth) {
      add(Pipe(
        pipeType: pipeType,
        position: Vector2(gapRight, 0),
        size: Vector2(screenWidth - gapRight, pipeHeight),
      ));
    }

    final markerSize = Vector2.all(gapWidth * 0.5);
    final markerPos = Vector2(gapPositionX, pipeHeight / 2);

    if (gapType == GapType.death) {
      add(DeathZone(position: markerPos, size: markerSize));
    } else {
      add(ScoreZone(
        is2x: gapType == GapType.safe2x,
        position: markerPos,
        size: markerSize,
      ));
    }

    if (hasLeftSpike && gapLeft > GameConstants.spikeWidth + 10) {
      add(Spike(
        spikeType: leftSpikeType,
        position: Vector2(gapLeft - GameConstants.spikeWidth / 2 - 5, 0),
        size: Vector2(GameConstants.spikeWidth, GameConstants.spikeHeight),
      ));
    }

    if (hasRightSpike && (screenWidth - gapRight) > GameConstants.spikeWidth + 10) {
      add(Spike(
        spikeType: rightSpikeType,
        position: Vector2(gapRight + GameConstants.spikeWidth / 2 + 5, 0),
        size: Vector2(GameConstants.spikeWidth, GameConstants.spikeHeight),
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
