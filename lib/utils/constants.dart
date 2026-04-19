class GameConstants {
  GameConstants._();

  static const double ballRadius = 14.0;
  static const double pegRadius = 7.0;

  static const int pegRows = 10;
  static const int pegColsWide = 8;
  static const int pegColsNarrow = 7;
  static const int numSlots = 9;

  static const double gravity = 900.0;
  static const double bounceDamping = 0.55;
  static const double horizontalJitter = 80.0;
  static const double maxVelocity = 900.0;
  static const int physicsSubsteps = 3;
  static const double nudgeStrength = 3.0;

  static const double boardTopFraction = 0.14;
  static const double boardBottomFraction = 0.82;
  static const double slotHeightFraction = 0.10;
  static const double boardMarginFraction = 0.06;

  static const int baseScore = 10;
  static const int score2x = 20;
  static const int goldPegBonus = 5;

  static const int dropsPerDifficulty = 5;
  static const double baseGoldPegChance = 0.18;
  static const double baseMovingPegAmplitude = 12.0;
}
