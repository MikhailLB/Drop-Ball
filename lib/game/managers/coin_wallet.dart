import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/physics_cfg.dart';

class CoinWallet {
  int _pending = 0;
  int _balance = 0;
  int _goldThisDrop = 0;

  int get pending => _pending;
  int get balance => _balance;
  int get goldThisDrop => _goldThisDrop;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _balance = prefs.getInt('bb2_wallet') ?? 0;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bb2_wallet', _balance);
  }

  void onGoldHit() {
    _goldThisDrop += PhysicsCfg.goldPegBonus;
  }

  void applyLanding(double multiplier) {
    _pending += _goldThisDrop + PhysicsCfg.baseDropCoins;
    _pending = (_pending * multiplier).round();
    _goldThisDrop = 0;
  }

  int collect() {
    final amount = _pending;
    _balance += _pending;
    _pending = 0;
    _persist();
    return amount;
  }

  int collectBonus() {
    _pending *= 2;
    return collect();
  }

  int burn() {
    final amount = _pending;
    _balance += (_pending * 0.3).round();
    _pending = 0;
    _goldThisDrop = 0;
    _persist();
    return amount;
  }

  void resetGame() {
    _pending = 0;
    _goldThisDrop = 0;
  }

  void resetDrop() {
    _goldThisDrop = 0;
  }
}
