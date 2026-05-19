import 'dart:math';
import '../../utils/physics_cfg.dart';

class RoundScaler {
  int _round = 0;

  int get round => _round;

  int get skullCount => (1 + _round).clamp(1, 6);

  double get minMultiplier => 1.0 + _round * 0.2;
  double get maxMultiplier => 1.5 + _round * 0.6;

  double get movingPegChance =>
      _round >= 2 ? ((_round - 1) * 0.10).clamp(0.0, 0.40) : 0.0;
  double get movingPegAmplitude => (10.0 + _round * 1.5).clamp(10.0, 20.0);

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
