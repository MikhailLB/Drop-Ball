import 'package:flutter/material.dart';

import '../models/orb_skin.dart';
import '../resonance/board_engine.dart';
import '../resonance/level_book.dart';
import '../services/progress_store.dart';
import '../widgets/aurora_background.dart';
import '../widgets/board_view.dart';

/// Interactive onboarding. Explains the rules and lets the player solve a
/// tiny live board before diving in.
class HowToPlayScreen extends StatefulWidget {
  final VoidCallback onDone;
  const HowToPlayScreen({super.key, required this.onDone});

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  static const _tint = Color(0xFF4FC3F7);

  late BoardEngine _engine;
  late OrbSkin _orb;
  bool _solved = false;

  @override
  void initState() {
    super.initState();
    _orb = ProgressStore.instance.activeOrb;
    _engine = BoardEngine(const LevelSpec(
      number: 0,
      title: 'Tutorial',
      rows: 3,
      cols: 3,
      seed: 42,
      scramble: 3,
      tint: _tint,
      chapter: 0,
    ));
  }

  void _onTap(int r, int c) {
    if (_solved) return;
    setState(() {
      _engine.tap(r, c);
      if (_engine.isSolved) _solved = true;
    });
  }

  Future<void> _finish() async {
    await ProgressStore.instance.markTutorialDone();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return AuroraBackground(
      tint: _tint,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 14),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: Text('SKIP',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            letterSpacing: 2,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              Text('HOW TO PLAY',
                  style: TextStyle(
                      color: _tint,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      shadows: [Shadow(color: _tint, blurRadius: 16)])),
              const SizedBox(height: 18),
              _rule(Icons.touch_app_rounded,
                  'Tap an orb to flip it AND its 4 neighbours.'),
              const SizedBox(height: 10),
              _rule(Icons.blur_on_rounded,
                  'Light up every orb on the board to win.'),
              const SizedBox(height: 10),
              _rule(Icons.star_rounded,
                  'Fewer moves = more stars. Stars unlock new orbs.'),
              const SizedBox(height: 18),
              Text(
                _solved ? 'PERFECT — YOU GOT IT!' : 'TRY IT: light all 9 orbs',
                style: TextStyle(
                  color: _solved ? const Color(0xFFFFD54F) : Colors.white70,
                  fontSize: 13,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: BoardView(
                  engine: _engine,
                  orb: _orb,
                  locked: _solved,
                  onTap: _onTap,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _finish,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(colors: [
                      _tint.withValues(alpha: _solved ? 0.95 : 0.4),
                      const Color(0xFF0288D1).withValues(alpha: _solved ? 0.85 : 0.4),
                    ]),
                    boxShadow: _solved
                        ? [BoxShadow(color: _tint.withValues(alpha: 0.5), blurRadius: 22)]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: const Text('START PLAYING',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rule(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _tint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _tint.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, color: _tint, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(text,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13.5,
                  height: 1.3)),
        ),
      ],
    );
  }
}
