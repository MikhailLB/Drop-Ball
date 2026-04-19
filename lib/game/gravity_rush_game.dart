import 'dart:ui' show Color, Offset, FontWeight;
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show TextStyle, Shadow;
import '../models/skin_data.dart';
import '../utils/constants.dart';
import 'components/ball.dart';
import 'components/obstacle_row.dart';
import 'components/score_indicator.dart';
import 'components/scrolling_background.dart';
import 'components/spike.dart';
import 'managers/difficulty_manager.dart';
import 'managers/score_manager.dart';

class GravityRushGame extends FlameGame
    with PanDetector, HasCollisionDetection {
  final SkinData skin;
  final ScoreManager scoreManager = ScoreManager();
  final DifficultyManager difficultyManager = DifficultyManager();

  late Ball _ball;
  double _nextRowY = 0;
  bool _isGameOver = false;

  GravityRushGame({required this.skin}) {
    images.prefix = 'assets/';
  }

  @override
  Future<void> onLoad() async {
    await scoreManager.loadHighScore();
    await _startGame();
  }

  Future<void> _startGame() async {
    _isGameOver = false;
    scoreManager.reset();
    difficultyManager.reset();

    add(ScrollingBackground());

    _ball = Ball(skin: skin);
    add(_ball);

    _nextRowY = size.y * 0.6;
    _spawnInitialRows();

    add(_ScoreDisplay());
  }

  void _spawnInitialRows() {
    for (int i = 0; i < 4; i++) {
      _spawnRow();
    }
  }

  void _spawnRow() {
    final row = ObstacleRow.generate(
      screenWidth: size.x,
      gapWidth: difficultyManager.gapWidth,
      redPipeChance: difficultyManager.redPipeChance,
      spikeChance: difficultyManager.spikeChance,
      yPosition: _nextRowY,
    );
    add(row);
    _nextRowY += difficultyManager.rowSpacing;
  }

  @override
  void update(double dt) {
    if (_isGameOver) return;
    super.update(dt);
    _checkCollisions();
    _manageRows();
  }

  void _manageRows() {
    final rows = children.whereType<ObstacleRow>().toList();

    for (final row in rows) {
      if (!row.scored && row.position.y + GameConstants.pipeHeight < _ball.position.y) {
        row.markScored();
        difficultyManager.onRowPassed();

        if (row.gapType == GapType.safe || row.gapType == GapType.safe2x) {
          final points = row.gapType == GapType.safe2x
              ? GameConstants.baseScore * GameConstants.multiplier2x
              : GameConstants.baseScore;
          scoreManager.addScore(points);
          add(ScoreIndicator(
            text: '+$points',
            position: row.position + Vector2(row.gapPositionX, 0),
          ));
        }
      }
    }

    while (_nextRowY < rows.fold<double>(0, (max, r) => r.position.y > max ? r.position.y : max) +
        difficultyManager.rowSpacing * 2) {
      _spawnRow();
    }
  }

  void _checkCollisions() {
    final ballCenter = _ball.position;
    final ballRadius = GameConstants.ballSize / 2 * 0.8;

    for (final row in children.whereType<ObstacleRow>()) {
      final rowTop = row.position.y;
      final rowBottom = rowTop + GameConstants.pipeHeight;

      if (ballCenter.y + ballRadius < rowTop || ballCenter.y - ballRadius > rowBottom) {
        continue;
      }

      final gapLeft = row.gapPositionX - row.gapWidth / 2;
      final gapRight = row.gapPositionX + row.gapWidth / 2;
      final inGap = ballCenter.x > gapLeft + ballRadius * 0.5 &&
          ballCenter.x < gapRight - ballRadius * 0.5;

      if (!inGap) {
        gameOver();
        return;
      }

      if (inGap && row.gapType == GapType.death) {
        gameOver();
        return;
      }

      for (final spike in row.children.whereType<Spike>()) {
        final spikeWorldPos = row.position + spike.position;
        final dist = (ballCenter - spikeWorldPos).length;
        if (dist < ballRadius + GameConstants.spikeWidth / 3) {
          gameOver();
          return;
        }
      }
    }
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (_isGameOver) return;
    _ball.moveHorizontal(info.delta.global.x);
  }

  void gameOver() {
    if (_isGameOver) return;
    _isGameOver = true;
    pauseEngine();
    overlays.add('GameOver');
  }

  void restart() {
    overlays.remove('GameOver');
    overlays.remove('Pause');
    removeAll(children);
    resumeEngine();
    _startGame();
  }

  void togglePause() {
    if (_isGameOver) return;
    if (paused) {
      resumeEngine();
      overlays.remove('Pause');
    } else {
      pauseEngine();
      overlays.add('Pause');
    }
  }
}

class _ScoreDisplay extends TextComponent with HasGameReference<GravityRushGame> {
  _ScoreDisplay()
      : super(
          anchor: Anchor.topCenter,
          priority: 100,
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 32,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Color(0xFF000000), blurRadius: 6, offset: Offset(2, 2)),
              ],
            ),
          ),
        );

  @override
  void onLoad() {
    position = Vector2(game.size.x / 2, 40);
  }

  @override
  void update(double dt) {
    super.update(dt);
    text = '${game.scoreManager.score}';
  }
}
