class GameConfig {
  GameConfig._();

  static const double ballRadius = 12.0;
  static const double pegRadius = 7.0;

  static const int pegRows = 12;
  static const int pegColsWide = 9;
  static const int pegColsNarrow = 8;
  static const int numSlots = 9;

  static const double gravity = 900.0;
  static const double bounceDamping = 0.55;
  static const double horizontalJitter = 80.0;
  static const double maxVelocity = 900.0;
  static const int physicsSubsteps = 3;

  static const double nudgeStrength = 4.0;
  static const double driftForce = 70.0;
  static const double driftInterval = 0.12;

  static const double boardTopFraction = 0.15;
  static const double boardBottomFraction = 0.82;
  static const double slotHeightFraction = 0.09;
  static const double boardMarginFraction = 0.06;

  static const int goldPegBonus = 5;
  static const int baseDropCoins = 10;
  static const double goldPegChance = 0.12;
}
