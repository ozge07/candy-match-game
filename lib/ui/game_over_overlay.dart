import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/ads_controller.dart';
import '../game/candy_game.dart';
import 'menu_button.dart';

/// Hamle kalmadığında beliren oyun sonu kartı.
///
/// Tam ekran kapladığı için altındaki tahtaya dokunuşları da engelliyor —
/// ayrıca bir giriş kilidine gerek kalmıyor.
class GameOverOverlay extends StatefulWidget {
  const GameOverOverlay({
    required this.game,
    required this.ads,
    required this.onExitToMenu,
    super.key,
  });

  final CandyGame game;

  /// Ödüllü reklam kontrolcüsü; "devam et" buna bakıyor.
  final AdsController ads;

  /// Menüye dönüş oyun ekranının sorumluluğunda.
  final VoidCallback onExitToMenu;

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _enter,
    curve: Curves.elasticOut,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _enter,
    curve: const Interval(0, 0.4, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ColoredBox(
        color: const Color(0xFF0E0B24).withValues(alpha: 0.82),
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _Card(
                game: widget.game,
                ads: widget.ads,
                onExitToMenu: widget.onExitToMenu,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatefulWidget {
  const _Card({
    required this.game,
    required this.ads,
    required this.onExitToMenu,
  });

  final CandyGame game;
  final AdsController ads;
  final VoidCallback onExitToMenu;

  @override
  State<_Card> createState() => _CardState();
}

class _CardState extends State<_Card> {
  bool _watching = false;

  CandyGame get game => widget.game;

  Future<void> _watchAdToContinue() async {
    setState(() => _watching = true);
    final earned = await widget.ads.showRewarded();
    if (!mounted) {
      return;
    }
    setState(() => _watching = false);
    if (earned) {
      game.continueAfterAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 34, 28, 28),
      decoration: BoxDecoration(
        color: const Color(0xFF241F4D),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8A3D).withValues(alpha: 0.28),
            blurRadius: 44,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'OYUN BİTTİ',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 26,
                  color: const Color(0xFFFF8A3D).withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Yapılacak hamle kalmadı',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 26),
          _ScorePanel(game: game),
          const SizedBox(height: 28),
          // Devam etme yalnızca bu turda kullanılmadıysa ve gösterime hazır
          // bir reklam varsa teklif ediliyor.
          ValueListenableBuilder<bool>(
            valueListenable: widget.ads.isReady,
            builder: (context, adReady, _) {
              if (!adReady || !game.canContinue) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  MenuButton(
                    label: _watching ? 'REKLAM AÇILIYOR…' : 'DEVAM ET',
                    icon: Icons.play_circle_fill_rounded,
                    onPressed: _watching ? null : _watchAdToContinue,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'reklam izle, tahta karışsın',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),
          MenuButton(
            label: 'MENÜYE DÖN',
            icon: Icons.home_rounded,
            onPressed: widget.onExitToMenu,
          ),
          const SizedBox(height: 12),
          MenuButton(
            label: 'ÇIKIŞ',
            icon: Icons.close_rounded,
            filled: false,
            onPressed: SystemNavigator.pop,
          ),
        ],
      ),
    );
  }
}

class _ScorePanel extends StatelessWidget {
  const _ScorePanel({required this.game});

  final CandyGame game;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            'SKORUN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 4),
          // Sayı sıfırdan sayarak yükselsin: küçük ama tatmin edici bir detay.
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: game.score.value),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text(
              '$value',
              style: const TextStyle(
                fontSize: 52,
                height: 1.05,
                fontWeight: FontWeight.w900,
                color: Color(0xFFF1C40F),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${game.moves.value} hamle',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          _BestLine(game: game),
        ],
      ),
    );
  }
}

/// Kartın altındaki kupa satırı: rekor kırıldıysa kutlar, kırılmadıysa
/// hedefi hatırlatır.
class _BestLine extends StatelessWidget {
  const _BestLine({required this.game});

  final CandyGame game;

  @override
  Widget build(BuildContext context) {
    final best = game.highScores.best.value;
    final isRecord = game.score.value >= best && game.score.value > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.emoji_events_rounded,
          size: 20,
          color: isRecord
              ? const Color(0xFFFFD54A)
              : Colors.white.withValues(alpha: 0.5),
        ),
        const SizedBox(width: 8),
        Text(
          isRecord ? 'YENİ REKOR!' : 'Rekor: $best',
          style: TextStyle(
            fontSize: 15,
            fontWeight: isRecord ? FontWeight.w900 : FontWeight.w600,
            letterSpacing: isRecord ? 1.5 : 0,
            color: isRecord
                ? const Color(0xFFFFD54A)
                : Colors.white.withValues(alpha: 0.7),
            shadows: isRecord
                ? const [Shadow(blurRadius: 16, color: Color(0xAAFFD54A))]
                : null,
          ),
        ),
      ],
    );
  }
}
