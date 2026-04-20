import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';

class ScoreManager {
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
    _goldCoinsThisDrop += GameConstants.goldPegBonus;
  }

  /// Adds this drop's earnings to pending, then multiplies EVERYTHING.
  void processLanding(double multiplier) {
    _pendingCoins += _goldCoinsThisDrop + GameConstants.baseDropCoins;
    _pendingCoins = (_pendingCoins * multiplier).round();
    _goldCoinsThisDrop = 0;
  }

  /// Moves pending coins to saved balance.
  int collect() {
    final amount = _pendingCoins;
    _balance += _pendingCoins;
    _pendingCoins = 0;
    _saveBalance();
    return amount;
  }

  /// Win bonus: doubles pending, then collects.
  int collectWithBonus() {
    _pendingCoins *= 2;
    return collect();
  }

  /// Burns all pending coins on death.
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
