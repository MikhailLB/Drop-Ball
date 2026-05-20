import 'dart:math';
import '../../utils/physics_cfg.dart';

class RoundScaler {
  int _round = 0;

  int get round => _round;

  int get skullCount => (1 + _round).clamp(1, 6);

  double get minMultiplier => 1.2 + _round * 0.25;
  double get maxMultiplier => 2.0 + _round * 0.7;

  double get movingPegChance =>
      _round >= 1 ? (_round * 0.12).clamp(0.0, 0.45) : 0.0;
  double get movingPegAmplitude => (12.0 + _round * 2.0).clamp(12.0, 24.0);

  List<double> buildMultipliers() {
    final rng = Random();
    return List.generate(PhysicsCfg.numSlots, (_) {
      final v = minMultiplier + rng.nextDouble() * (maxMultiplier - minMultiplier);
      return double.parse(v.toStringAsFixed(1));
    });
  }

  void advance() => _round++;

  void reset() => _round = 0;
}
