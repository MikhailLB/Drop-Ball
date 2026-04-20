import 'dart:math';
import '../../utils/constants.dart';

class DifficultyManager {
  int _iteration = 0;

  int get iteration => _iteration;

  /// Skulls grow fast: 1 → 2 → 3 → 4 → 5 → 6 (max)
  int get skullCount => (1 + _iteration).clamp(1, 6);

  double get minMultiplier => 1.0 + _iteration * 0.2;
  double get maxMultiplier => 1.5 + _iteration * 0.6;

  /// Moving pegs start from iteration 2 and ramp up fast
  double get movingPegChance =>
      _iteration >= 2 ? ((_iteration - 1) * 0.10).clamp(0.0, 0.40) : 0.0;
  double get movingPegAmplitude =>
      (10.0 + _iteration * 1.5).clamp(10.0, 20.0);

  List<double> generateMultipliers() {
    final rng = Random();
    return List.generate(GameConstants.numSlots, (_) {
      final v =
          minMultiplier + rng.nextDouble() * (maxMultiplier - minMultiplier);
      return double.parse(v.toStringAsFixed(1));
    });
  }

  void onDrop() {
    _iteration++;
  }

  void reset() {
    _iteration = 0;
  }
}
