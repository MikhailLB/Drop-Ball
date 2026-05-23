import '../models/level_config.dart';

class LevelController {
  final LevelConfig config;
  int _livesRemaining;
  int _dropIteration = 0;

  LevelController({required this.config})
      : _livesRemaining = config.lives;

  int get livesRemaining => _livesRemaining;
  bool get hasLivesLeft => _livesRemaining > 0;

  double get movingPegChance => config.movingPegChance;
  double get movingPegAmplitude => config.movingPegAmplitude;

  int get skullCount => config.skullCount;

  void loseLife() {
    if (_livesRemaining > 0) _livesRemaining--;
  }

  void onDrop() {
    _dropIteration++;
  }

  int get dropIteration => _dropIteration;

  void reset() {
    _livesRemaining = config.lives;
    _dropIteration = 0;
  }
}
