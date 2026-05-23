import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/drop_config.dart';

class CoinLedger {
  int _pending  = 0;
  int _session  = 0;
  int _wallet   = 0;
  int _goldTick = 0;

  int get pending  => _pending;
  int get session  => _session;
  int get wallet   => _wallet;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _wallet = p.getInt('db_wallet') ?? 0;
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('db_wallet', _wallet);
  }

  void onGoldPeg() => _goldTick += DropConfig.goldBonus;

  void recordLanding(double multi) {
    final earned = ((_goldTick + DropConfig.baseCoins) * multi).round();
    _pending += earned;
    _goldTick = 0;
  }

  /// Skull hit — keep 50 % of pending.
  int skullPenalty() {
    final lost = (_pending * 0.5).round();
    _pending -= lost;
    _goldTick = 0;
    return lost;
  }

  int bank() {
    final amt = _pending;
    _session += amt;
    _wallet  += amt;
    _pending  = 0;
    _save();
    return amt;
  }

  int bankWithBonus() {
    _pending = (_pending * 1.5).round();
    return bank();
  }

  int forfeit() {
    final amt = _pending;
    _pending  = 0;
    _goldTick = 0;
    return amt;
  }

  void resetRound() {
    _pending  = 0;
    _session  = 0;
    _goldTick = 0;
  }

  void resetDrop() => _goldTick = 0;
}
