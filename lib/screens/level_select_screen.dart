import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/models/level_config.dart';
import '../models/ball_skin.dart';
import '../utils/media_paths.dart';

class LevelSelectScreen extends StatefulWidget {
  final void Function(LevelConfig level, BallSkin skin) onLevelSelected;
  final VoidCallback onBack;

  const LevelSelectScreen({
    super.key,
    required this.onLevelSelected,
    required this.onBack,
  });

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  int _highestUnlocked = 1;
  final Set<int> _completed = {};

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final highest = prefs.getInt('highest_unlocked_level') ?? 1;
    final completedList =
        prefs.getStringList('completed_levels') ?? [];
    setState(() {
      _highestUnlocked = highest;
      _completed.addAll(completedList.map(int.parse));
    });
  }

  void _onLevelTap(LevelConfig level) {
    if (level.number > _highestUnlocked) return;
    final skin = BallSkin.getById(level.sphereSkinId);
    widget.onLevelSelected(level, skin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white70, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Image.asset(
            MediaPaths.logoWhite,
            width: 40,
            height: 40,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          const Text(
            'SELECT LEVEL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          Text(
            '${_completed.length}/${Levels.count}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: Levels.count,
      itemBuilder: (context, index) {
        final level = Levels.all[index];
        final isUnlocked = level.number <= _highestUnlocked;
        final isCompleted = _completed.contains(level.number);
        return _buildLevelCard(level, isUnlocked, isCompleted);
      },
    );
  }

  Widget _buildLevelCard(
      LevelConfig level, bool isUnlocked, bool isCompleted) {
    final color = isUnlocked ? level.themeColor : Colors.white24;
    final skin = BallSkin.getById(level.sphereSkinId);

    return GestureDetector(
      onTap: () => _onLevelTap(level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isUnlocked
              ? color.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.03),
          border: Border.all(
            color: isCompleted
                ? Colors.amberAccent.withValues(alpha: 0.7)
                : isUnlocked
                    ? color.withValues(alpha: 0.5)
                    : Colors.white10,
            width: isCompleted ? 2.0 : 1.5,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 12,
                  )
                ]
              : null,
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Level number badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${level.number}',
                          style: TextStyle(
                            color: isUnlocked ? color : Colors.white38,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Sphere thumbnail or lock
                      isUnlocked
                          ? Image.asset(
                              skin.assetPath,
                              width: 32,
                              height: 32,
                            )
                          : Icon(Icons.lock_outline,
                              color: Colors.white30, size: 24),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    level.name,
                    style: TextStyle(
                      color: isUnlocked ? Colors.white : Colors.white38,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isUnlocked
                        ? 'TARGET: ${_formatScore(level.targetScore)}'
                        : 'LOCKED',
                    style: TextStyle(
                      color: isUnlocked
                          ? color.withValues(alpha: 0.8)
                          : Colors.white24,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Completed checkmark
            if (isCompleted)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.amberAccent.withValues(alpha: 0.6)),
                  ),
                  child: const Icon(Icons.check,
                      color: Colors.amberAccent, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatScore(int score) {
    if (score >= 1000) return '${score ~/ 1000}K';
    return '$score';
  }
}
