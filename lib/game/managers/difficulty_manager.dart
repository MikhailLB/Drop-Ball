import '../../utils/constants.dart';

class DifficultyManager {
  int _rowsPassed = 0;
  int _difficultyTier = 0;

  double get scrollSpeed {
    final speed = GameConstants.baseScrollSpeed +
        (_difficultyTier * GameConstants.speedIncrement);
    return speed.clamp(GameConstants.baseScrollSpeed, GameConstants.maxScrollSpeed);
  }

  double get gapWidth {
    final gap = GameConstants.baseGapWidth -
        (_difficultyTier * GameConstants.gapShrinkRate);
    return gap.clamp(GameConstants.minGapWidth, GameConstants.baseGapWidth);
  }

  double get rowSpacing {
    final spacing = GameConstants.rowSpacing -
        (_difficultyTier * 5.0);
    return spacing.clamp(GameConstants.minRowSpacing, GameConstants.rowSpacing);
  }

  double get redPipeChance {
    final chance = GameConstants.initialRedPipeChance +
        (_difficultyTier * GameConstants.redPipeChanceIncrement);
    return chance.clamp(GameConstants.initialRedPipeChance, GameConstants.maxRedPipeChance);
  }

  double get spikeChance {
    final chance = GameConstants.initialSpikeChance +
        (_difficultyTier * GameConstants.spikeChanceIncrement);
    return chance.clamp(GameConstants.initialSpikeChance, GameConstants.maxSpikeChance);
  }

  void onRowPassed() {
    _rowsPassed++;
    if (_rowsPassed % GameConstants.rowsPerDifficultyTick == 0) {
      _difficultyTier++;
    }
  }

  void reset() {
    _rowsPassed = 0;
    _difficultyTier = 0;
  }
}
