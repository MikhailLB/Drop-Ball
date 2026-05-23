class DropConfig {
  DropConfig._();

  static const double orbRadius  = 12.0;
  static const double pegRadius  = 7.0;

  static const int pegRows      = 12;
  static const int pegColsWide  = 9;
  static const int pegColsNarrow = 8;
  static const int slotCount    = 9;

  static const double gravity       = 900.0;
  static const double dampening     = 0.55;
  static const double lateralJitter = 80.0;
  static const double speedCap      = 900.0;
  static const int    subSteps      = 3;

  static const double steerStrength = 4.0;
  static const double driftPush     = 70.0;
  static const double driftTick     = 0.12;

  static const double boardTop     = 0.15;
  static const double boardBottom  = 0.82;
  static const double slotHeight   = 0.09;
  static const double boardMargin  = 0.06;

  static const int    goldBonus    = 10;
  static const int    baseCoins    = 15;
  static const double goldChance   = 0.12;
}
