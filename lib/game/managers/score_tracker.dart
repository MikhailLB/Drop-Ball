import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/game_config.dart';

class ScoreTracker {
  int _pendingCoins = 0;
  int _balance = 0;
  int _goldCoinsThisDrop = 0;

  int get pendingCoins => _pendingCoins;
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
    _pendingCoins += _goldCoinsThisDrop + GameConfig.baseDropCoins;
    _pendingCoins = (_pendingCoins * multiplier).round();
    _goldCoinsThisDrop = 0;
  }

  int collect() {
    final amount = _pendingCoins;
    _balance += _pendingCoins;
    _pendingCoins = 0;
    _saveBalance();
    return amount;
  }

  int collectWithBonus() {
    _pendingCoins *= 2;
    return collect();
  }

  int burn() {
    final amount = _pendingCoins;
    _pendingCoins = 0;
    _goldCoinsThisDrop = 0;
    return amount;
  }

  void resetForNewGame() {
    _pendingCoins = 0;
    _goldCoinsThisDrop = 0;
  }

  void resetForNewDrop() {
    _goldCoinsThisDrop = 0;
  }
}
