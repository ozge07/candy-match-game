import 'package:flutter/material.dart';

import '../game/candy_game.dart';

/// Oyunun üstünde duran skor / rekor göstergesi ve düğmeler.
///
/// Flame'in overlay mekanizmasıyla normal bir Flutter widget'ı olarak
/// çiziliyor.
class HudOverlay extends StatelessWidget {
  const HudOverlay({
    required this.game,
    required this.onExitToMenu,
    super.key,
  });

  final CandyGame game;

  /// Menüye dönüş oyun ekranının sorumluluğunda; HUD sadece haber veriyor.
  final VoidCallback onExitToMenu;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _ScoreCard(game: game)),
            const SizedBox(width: 10),
            Expanded(child: _BestCard(game: game)),
            const SizedBox(width: 10),
            Column(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: game.audio.muted,
                  builder: (context, muted, _) => _RoundButton(
                    icon: muted ? Icons.volume_off : Icons.volume_up,
                    tooltip: muted ? 'Sesi aç' : 'Sesi kapat',
                    onPressed: game.audio.toggleMute,
                  ),
                ),
                const SizedBox(height: 8),
                _RoundButton(
                  icon: Icons.home_rounded,
                  tooltip: 'Menüye dön',
                  onPressed: onExitToMenu,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.game});

  final CandyGame game;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _CardLabel('SKOR'),
          const SizedBox(height: 2),
          ValueListenableBuilder<int>(
            valueListenable: game.score,
            builder: (context, score, _) => Text(
              '$score',
              style: const TextStyle(
                color: Color(0xFFF1C40F),
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          ValueListenableBuilder<int>(
            valueListenable: game.moves,
            builder: (context, moves, _) => Text(
              '$moves hamle',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rekor kartı. Skor rekoru yakaladığı an kupa altın rengine dönüp parlıyor.
class _BestCard extends StatelessWidget {
  const _BestCard({required this.game});

  final CandyGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.highScores.best,
      builder: (context, best, _) => ValueListenableBuilder<int>(
        valueListenable: game.score,
        builder: (context, score, _) {
          final leading = score > 0 && score >= best;
          return _Card(
            glow: leading,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const _CardLabel('REKOR'),
                const SizedBox(height: 2),
                Row(
                  children: [
                    _Trophy(size: 20, active: leading),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '$best',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: leading
                              ? const Color(0xFFFFD54A)
                              : Colors.white.withValues(alpha: 0.85),
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  leading ? 'lider sensin' : 'en iyi skor',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Kupa ikonu. [active] iken altın renginde ve haleli.
class _Trophy extends StatelessWidget {
  const _Trophy({required this.size, this.active = false});

  final double size;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: active
            ? [
                const BoxShadow(
                  color: Color(0x99FFD54A),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.emoji_events_rounded,
        size: size,
        color: active
            ? const Color(0xFFFFD54A)
            : Colors.white.withValues(alpha: 0.55),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.glow = false});

  final Widget child;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: glow
              ? const Color(0xFFFFD54A).withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.12),
        ),
        boxShadow: glow
            ? [const BoxShadow(color: Color(0x55FFD54A), blurRadius: 20)]
            : null,
      ),
      child: child,
    );
  }
}

class _CardLabel extends StatelessWidget {
  const _CardLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.6),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.08),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Icon(icon, color: Colors.white70, size: 21),
          ),
        ),
      ),
    );
  }
}
