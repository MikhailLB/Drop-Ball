import '../models/stage_config.dart';

class StageControl {
  final StageConfig cfg;
  int _lives;
  int _drops = 0;

  StageControl({required this.cfg}) : _lives = cfg.lives;

  int  get livesLeft   => _lives;
  bool get hasLives    => _lives > 0;
  int  get dropCount   => _drops;
  double get moveChance => cfg.movePegChance;
  double get moveRange  => cfg.movePegRange;

  void loseLife()  { if (_lives > 0) _lives--; }
  void countDrop() => _drops++;

  void reset() {
    _lives = cfg.lives;
    _drops = 0;
  }
}
