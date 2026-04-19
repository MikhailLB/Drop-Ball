import 'package:shared_preferences/shared_preferences.dart';

class ScoreManager {
  int _score = 0;
  int _highScore = 0;
  static const String _highScoreKey = 'high_score';

  int get score => _score;
  int get highScore => _highScore;

  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    _highScore = prefs.getInt(_highScoreKey) ?? 0;
  }

  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_highScoreKey, _highScore);
  }

  void addScore(int points) {
    _score += points;
    if (_score > _highScore) {
      _highScore = _score;
      _saveHighScore();
    }
  }

  void reset() {
    _score = 0;
  }
}
