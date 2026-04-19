import '../../utils/constants.dart';

class DifficultyManager {
  int _dropCount = 0;
  int _tier = 0;
  bool tierChanged = false;

  int get tier => _tier;
  int get dropCount => _dropCount;
  int get skullCount => (_tier + 1).clamp(1, 4);
  int get bonus2xCount => (1 + _tier ~/ 3).clamp(1, 2);

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
