import 'package:flutter/material.dart';

import '../game/audio_controller.dart';
import '../game/game_save_store.dart';
import '../game/high_score_store.dart';
import '../game/tip_store.dart';
import 'candy_artwork.dart';
import 'menu_screen.dart';

/// Açılış ekranı: illüstrasyon, oyun adı ve gerçek bir yükleme çubuğu.
///
/// Çubuk sahte değil — ses dosyaları gerçekten burada yükleniyor. Böylece
/// oyuna girildiğinde ilk patlamanın sesi de hazır oluyor.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    required this.audio,
    required this.highScores,
    required this.saves,
    required this.tips,
    super.key,
  });

  final AudioController audio;
  final HighScoreStore highScores;
  final GameSaveStore saves;
  final TipStore tips;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Yükleme çok hızlı biterse ekran "parlayıp geçmesin" diye alt sınır.
  static const Duration _minimumVisible = Duration(milliseconds: 1900);

  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await Future.wait([
      widget.audio.load(),
      widget.highScores.load(),
      widget.saves.load(),
      widget.tips.load(),
      Future<void>.delayed(_minimumVisible),
    ]);
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => MenuScreen(
          audio: widget.audio,
          highScores: widget.highScores,
          saves: widget.saves,
          tips: widget.tips,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0B24),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CandyArtwork(animation: _drift),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                const _GameTitle(),
                const Spacer(flex: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: ValueListenableBuilder<double>(
                    valueListenable: widget.audio.progress,
                    builder: (context, value, _) => _LoadingBar(value: value),
                  ),
                ),
                const SizedBox(height: 56),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GameTitle extends StatelessWidget {
  const _GameTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'CANDY',
          style: TextStyle(
            fontSize: 54,
            fontWeight: FontWeight.w900,
            letterSpacing: 8,
            height: 1,
            color: Colors.white,
            shadows: [
              const Shadow(blurRadius: 18, color: Colors.black87),
              Shadow(
                blurRadius: 34,
                color: const Color(0xFFFFC145).withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'MATCH',
          style: TextStyle(
            fontSize: 54,
            fontWeight: FontWeight.w900,
            letterSpacing: 8,
            height: 1,
            color: const Color(0xFFF1C40F),
            shadows: [
              const Shadow(blurRadius: 18, color: Colors.black87),
              Shadow(
                blurRadius: 34,
                color: const Color(0xFFFF8A3D).withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'YÜKLENİYOR…',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Stack(
            children: [
              Container(
                height: 8,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                builder: (context, shown, _) => FractionallySizedBox(
                  widthFactor: shown,
                  child: Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFF1C40F), Color(0xFFFF8A3D)],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
