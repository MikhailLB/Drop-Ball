class GameConstants {
  GameConstants._();

  static const double baseScrollSpeed = 120.0;
  static const double maxScrollSpeed = 350.0;
  static const double speedIncrement = 8.0;

  static const double ballSize = 40.0;
  static const double pipeWidth = 90.0;
  static const double pipeHeight = 120.0;
  static const double spikeWidth = 35.0;
  static const double spikeHeight = 45.0;

  static const double baseGapWidth = 100.0;
  static const double minGapWidth = 60.0;
  static const double gapShrinkRate = 2.0;

  static const double rowSpacing = 250.0;
  static const double minRowSpacing = 160.0;

  static const int rowsPerDifficultyTick = 5;

  static const double initialRedPipeChance = 0.15;
  static const double maxRedPipeChance = 0.45;
  static const double redPipeChanceIncrement = 0.02;

  static const double initialSpikeChance = 0.2;
  static const double maxSpikeChance = 0.7;
  static const double spikeChanceIncrement = 0.03;

  static const int baseScore = 10;
  static const int multiplier2x = 2;
  static const double bonus2xChance = 0.2;
}
