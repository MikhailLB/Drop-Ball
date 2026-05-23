import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/game_config.dart';

class ScoreTracker {
  int _pendingCoins = 0;
  int _sessionScore = 0;
  int _balance = 0;
  int _goldCoinsThisDrop = 0;

  int get pendingCoins => _pendingCoins;
  int get sessionScore => _sessionScore;
  int get balance => _balance;
  int get goldCoinsThisDrop => _goldCoinsThisDrop;

  Future<void> loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    _balance = prefs.getInt('balance') ?? 0;
  }

  Future<void> _saveBalance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('balance', _balance);
  }

  void onGoldPegHit() {
    _goldCoinsThisDrop += GameConfig.goldPegBonus;
  }

  void processLanding(double multiplier) {
    final earned = ((_goldCoinsThisDrop + GameConfig.baseDropCoins) * multiplier).round();
    _pendingCoins += earned;
    _goldCoinsThisDrop = 0;
  }

  /// Called on skull hit — keeps 50% of pending coins but adds nothing to session.
  int skullPenalty() {
    final lost = (_pendingCoins * 0.5).round();
    _pendingCoins = _pendingCoins - lost;
    _goldCoinsThisDrop = 0;
    return lost;
  }

  /// Bank all pending coins into the session score and balance.
  int collect() {
    final amount = _pendingCoins;
    _sessionScore += amount;
    _balance += amount;
    _pendingCoins = 0;
    _saveBalance();
    return amount;
  }

  int collectWithBonus() {
    _pendingCoins = (_pendingCoins * 1.5).round();
    return collect();
  }

  /// Hard burn — lose everything (e.g. rage quit / override).
  int burn() {
    final amount = _pendingCoins;
    _pendingCoins = 0;
    _goldCoinsThisDrop = 0;
    return amount;
  }

  void resetForNewGame() {
    _pendingCoins = 0;
    _sessionScore = 0;
    _goldCoinsThisDrop = 0;
  }

  void resetForNewDrop() {
    _goldCoinsThisDrop = 0;
  }
}
