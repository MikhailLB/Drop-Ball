import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/models/stage_config.dart';
import '../models/orb_skin.dart';
import 'arena_view.dart';
import 'stage_map.dart';
import 'launch_screen.dart';
import 'shop_screen.dart';

enum _Scene { launch, shop, stages, arena }

class GameFlow extends StatefulWidget {
  /// When true (coming from GateScreen) skip the launch video and go
  /// straight to the shop — GateScreen already served as the loading screen.
  final bool skipLaunch;
  const GameFlow({super.key, this.skipLaunch = false});

  @override
  State<GameFlow> createState() => _GameFlowState();
}

class _GameFlowState extends State<GameFlow> {
  late _Scene _scene;
  OrbSkin   _orb   = OrbSkin.catalog[0];
  StageConfig _stage = StageBook.all[0];

  @override
  void initState() {
    super.initState();
    _scene = widget.skipLaunch ? _Scene.shop : _Scene.launch;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  void _goPortrait() =>
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  void _onLaunchDone() => setState(() => _scene = _Scene.shop);
  void _onPlayFromShop(OrbSkin orb) { _orb = orb; setState(() => _scene = _Scene.stages); }
  void _onStagePicked(StageConfig s, OrbSkin orb) => setState(() { _stage = s; _orb = orb; _scene = _Scene.arena; });
  void _onBackToShop() => setState(() => _scene = _Scene.shop);
  void _onMenu()       { _goPortrait(); setState(() => _scene = _Scene.shop); }

  Future<void> _onNextStage(int n) async {
    await _persistClear(_stage.number);
    if (n > StageBook.count) { _onMenu(); return; }
    setState(() { _stage = StageBook.at(n); _orb = OrbSkin.byId(_stage.orbId); _scene = _Scene.arena; });
  }

  Future<void> _persistClear(int num) async {
    final p = await SharedPreferences.getInstance();
    final done = (p.getStringList('completed_stages') ?? []).toSet()..add('$num');
    final top  = p.getInt('top_unlocked_stage') ?? 1;
    await p.setStringList('completed_stages', done.toList());
    await p.setInt('top_unlocked_stage', (num + 1 > top ? num + 1 : top));
  }

  @override
  Widget build(BuildContext context) {
    if (_scene == _Scene.arena || _scene == _Scene.shop || _scene == _Scene.stages) {
      _goPortrait();
    }
    return switch (_scene) {
      _Scene.launch => LaunchScreen(onReady: _onLaunchDone),
      _Scene.shop   => ShopScreen(onPlay: _onPlayFromShop),
      _Scene.stages => StageMap(onPick: _onStagePicked, onBack: _onBackToShop),
      _Scene.arena  => ArenaView(
          key: ValueKey('arena_${_stage.number}'),
          skin: _orb, stage: _stage, onMenu: _onMenu,
          onNextStage: (n) async { await _persistClear(_stage.number); await _onNextStage(n); },
        ),
    };
  }
}
