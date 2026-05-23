import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/models/stage_config.dart';
import '../models/orb_skin.dart';
import '../utils/asset_paths.dart';

class StageMap extends StatefulWidget {
  final void Function(StageConfig s, OrbSkin orb) onPick;
  final VoidCallback onBack;

  const StageMap({super.key, required this.onPick, required this.onBack});

  @override
  State<StageMap> createState() => _StageMapState();
}

class _StageMapState extends State<StageMap> {
  int _topUnlocked = 1;
  final Set<int> _done = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final doneList = (p.getStringList('completed_stages') ?? []);
    setState(() {
      _topUnlocked = p.getInt('top_unlocked_stage') ?? 1;
      _done.addAll(doneList.map(int.parse));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08091A),
      body: SafeArea(child: Column(children: [
        _header(),
        Expanded(child: _grid()),
      ])),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Row(children: [
      GestureDetector(
        onTap: widget.onBack,
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
        ),
      ),
      const SizedBox(width: 12),
      Image.asset(AssetPaths.logoMark, width: 32, height: 32),
      const SizedBox(width: 10),
      const Text('STAGES', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 3)),
      const Spacer(),
      Text('${_done.length}/${StageBook.count}',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 13)),
    ]),
  );

  Widget _grid() => GridView.builder(
    padding: const EdgeInsets.all(14),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1,
    ),
    itemCount: StageBook.count,
    itemBuilder: (ctx, i) => _card(StageBook.all[i]),
  );

  Widget _card(StageConfig s) {
    final unlocked = s.number <= _topUnlocked;
    final done     = _done.contains(s.number);
    final tint     = unlocked ? s.tint : Colors.white24;
    final orb      = OrbSkin.byId(s.orbId);

    return GestureDetector(
      onTap: () { if (unlocked) widget.onPick(s, orb); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: unlocked ? tint.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.02),
          border: Border.all(
            color: done ? Colors.amberAccent.withValues(alpha: 0.65) : unlocked ? tint.withValues(alpha: 0.45) : Colors.white10,
            width: done ? 2.0 : 1.5,
          ),
          boxShadow: unlocked ? [BoxShadow(color: tint.withValues(alpha: 0.13), blurRadius: 10)] : null,
        ),
        child: Stack(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: tint.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(7)),
                  child: Text('${s.number}', style: TextStyle(color: unlocked ? tint : Colors.white38, fontSize: 15, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                unlocked
                    ? Image.asset(orb.assetPath, width: 30, height: 30)
                    : const Icon(Icons.lock_outline, color: Colors.white30, size: 22),
              ]),
              const Spacer(),
              Text(s.title, style: TextStyle(color: unlocked ? Colors.white : Colors.white38, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(
                unlocked ? 'GOAL ${_fmt(s.goal)}' : 'LOCKED',
                style: TextStyle(color: unlocked ? tint.withValues(alpha: 0.75) : Colors.white24, fontSize: 10),
              ),
            ]),
          ),
          if (done)
            Positioned(top: 7, right: 7,
              child: Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withValues(alpha: 0.18), shape: BoxShape.circle,
                  border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.55)),
                ),
                child: const Icon(Icons.check, color: Colors.amberAccent, size: 12),
              ),
            ),
        ]),
      ),
    );
  }

  String _fmt(int v) => v >= 1000 ? '${v ~/ 1000}K' : '$v';
}
