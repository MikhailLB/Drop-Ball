class GameConstants {
  GameConstants._();

  static const double baseScrollSpeed = 100.0;
  static const double maxScrollSpeed = 280.0;
  static const double speedIncrement = 6.0;

  static const double ballSize = 40.0;

  static const double pipeWidth = 70.0;
  static const double pipeHeight = 100.0;

  static const double spikeWidth = 30.0;
  static const double spikeHeight = 40.0;

  static const double markerSize = 36.0;

  static const double baseGapWidth = 90.0;
  static const double minGapWidth = 55.0;
  static const double gapShrinkRate = 1.5;

  static const double rowSpacing = 220.0;
  static const double minRowSpacing = 150.0;

  static const int rowsPerDifficultyTick = 6;

  static const double initialRedPipeChance = 0.12;
  static const double maxRedPipeChance = 0.40;
  static const double redPipeChanceIncrement = 0.015;

  static const double initialSpikeChance = 0.15;
  static const double maxSpikeChance = 0.55;
  static const double spikeChanceIncrement = 0.025;

  static const int baseScore = 10;
  static const int multiplier2x = 2;
  static const double bonus2xChance = 0.2;
}
