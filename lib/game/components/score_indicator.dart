import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../gravity_rush_game.dart';

class ScoreIndicator extends TextComponent with HasGameReference<GravityRushGame> {
  double _lifeTimer = 0;
  static const double _lifetime = 0.8;

  ScoreIndicator({
    required String text,
    required Vector2 position,
    Color color = Colors.greenAccent,
  }) : super(
          text: text,
          position: position,
          anchor: Anchor.center,
          textRenderer: TextPaint(
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: Colors.black, blurRadius: 4),
              ],
            ),
          ),
          priority: 20,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _lifeTimer += dt;
    position.y -= 60 * dt;

    final progress = _lifeTimer / _lifetime;
    final renderer = textRenderer as TextPaint;
    textRenderer = TextPaint(
      style: renderer.style.copyWith(
        color: renderer.style.color?.withValues(alpha: 1 - progress),
      ),
    );

    if (_lifeTimer >= _lifetime) {
      removeFromParent();
    }
  }
}
