import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/audio_controller.dart';
import '../game/candy_game.dart';
import '../game/game_save_store.dart';
import '../game/high_score_store.dart';
import '../game/tip_store.dart';
import 'game_over_overlay.dart';
import 'hud_overlay.dart';
import 'level_bar.dart';

/// Oyunun oynandığı ekran. HUD ve oyun sonu kartı Flame'in overlay
/// mekanizmasıyla, normal Flutter widget'ları olarak çiziliyor.
class GamePage extends StatefulWidget {
  const GamePage({
    required this.audio,
    this.highScores,
    this.saves,
    this.tips,
    this.resume,
    super.key,
  });

  final AudioController audio;
  final HighScoreStore? highScores;
  final GameSaveStore? saves;
  final TipStore? tips;

  /// Verilirse oyun bu kayıttan devam eder.
  final SavedGame? resume;

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  static const String hudOverlay = 'hud';
  static const String levelOverlay = 'level';
  static const String gameOverOverlay = 'gameOver';

  late final CandyGame _game = CandyGame(
    audio: widget.audio,
    highScores: widget.highScores,
    saves: widget.saves,
    tips: widget.tips,
    resume: widget.resume,
  );

  @override
  void initState() {
    super.initState();
    _game.isOver.addListener(_onGameOverChanged);
  }

  void _onGameOverChanged() {
    if (_game.isOver.value) {
      _game.overlays.add(gameOverOverlay);
    } else {
      _game.overlays.remove(gameOverOverlay);
    }
  }

  void _exitToMenu() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _game.isOver.removeListener(_onGameOverChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141130),
      body: GameWidget<CandyGame>(
        game: _game,
        overlayBuilderMap: {
          hudOverlay: (context, game) =>
              HudOverlay(game: game, onExitToMenu: _exitToMenu),
          levelOverlay: (context, game) => LevelBar(game: game),
          gameOverOverlay: (context, game) =>
              GameOverOverlay(game: game, onExitToMenu: _exitToMenu),
        },
        initialActiveOverlays: const [hudOverlay, levelOverlay],
      ),
    );
  }
}
