import '../../utils/constants.dart';

class DifficultyManager {
  int _dropCount = 0;
  int _tier = 0;
  bool tierChanged = false;

  int get tier => _tier;
  int get dropCount => _dropCount;
  int get skullCount => (_tier + 1).clamp(1, 4);
  int get bonus2xCount => (1 + _tier ~/ 3).clamp(1, 2);

  double get goldPegChance =>
      (GameConstants.baseGoldPegChance + _tier * 0.025).clamp(0.15, 0.30);

  double get movingPegChance =>
      _tier >= 2 ? ((_tier - 1) * 0.10).clamp(0.0, 0.35) : 0.0;

  double get movingPegAmplitude =>
      (GameConstants.baseMovingPegAmplitude + _tier * 1.5).clamp(10.0, 18.0);

  void onDrop() {
    _dropCount++;
    final newTier = _dropCount ~/ GameConstants.dropsPerDifficulty;
    tierChanged = newTier != _tier;
    _tier = newTier;
  }

  void reset() {
    _dropCount = 0;
    _tier = 0;
    tierChanged = false;
  }
}
