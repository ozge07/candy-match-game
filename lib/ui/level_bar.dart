import 'dart:async';

import 'package:flutter/material.dart';

import '../i18n/strings.dart';

import '../game/candy_game.dart';
import '../game/level_theme.dart';

/// Ekranın altındaki seviye şeridi: mevcut seviye, bir sonrakine kalan yol ve
/// zorluğu anlatan bilgi ipucu.
///
/// Tahtanın altında kalan boşluğu doldurmasının yanında, seviye atlamanın
/// yaklaştığını da görünür kılıyor.
class LevelBar extends StatefulWidget {
  const LevelBar({required this.game, super.key});

  final CandyGame game;

  @override
  State<LevelBar> createState() => _LevelBarState();
}

class _LevelBarState extends State<LevelBar> {
  /// İpucu bu süre sonunda kendiliğinden kapanıyor.
  static const Duration _visibleFor = Duration(seconds: 5);

  bool _showTip = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    // İpucu yalnızca ilk oyunda kendiliğinden açılıyor; sonrasında bilgi
    // düğmesiyle istenildiği zaman görülebiliyor.
    if (!widget.game.tips.seen.value) {
      _revealTip();
      unawaited(widget.game.tips.markSeen());
    }
  }

  void _revealTip() {
    _hideTimer?.cancel();
    setState(() => _showTip = true);
    _hideTimer = Timer(_visibleFor, () {
      if (mounted) {
        setState(() => _showTip = false);
      }
    });
  }

  void _toggleTip() {
    if (_showTip) {
      _hideTimer?.cancel();
      setState(() => _showTip = false);
    } else {
      _revealTip();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TipCard(visible: _showTip, onClose: _toggleTip),
              const SizedBox(height: 10),
              _Progress(game: widget.game, onInfo: _toggleTip),
            ],
          ),
        ),
      ),
    );
  }
}

/// Zorluğun nasıl arttığını anlatan ipucu balonu.
class _TipCard extends StatelessWidget {
  const _TipCard({required this.visible, required this.onClose});

  final bool visible;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 0.25),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 240),
        // Görünmezken dokunuşları da geçirmesin.
        child: IgnorePointer(
          ignoring: !visible,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 11, 6, 11),
            decoration: BoxDecoration(
              color: const Color(0xFF241F4D),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: LevelTheme.accent.withValues(alpha: 0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: LevelTheme.accent,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Strings.of(context).harderEachLevel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Strings.of(context).levelTip(CandyGame.pointsPerLevel),
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: Colors.white54,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Kapat',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.game, required this.onInfo});

  final CandyGame game;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.level,
      builder: (context, level, _) => ValueListenableBuilder<int>(
        valueListenable: game.score,
        builder: (context, score, _) {
          final earned = score % CandyGame.pointsPerLevel;
          final progress = earned / CandyGame.pointsPerLevel;
          final remaining = CandyGame.pointsPerLevel - earned;
          const accent = LevelTheme.accent;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _LevelChip(level: level, accent: accent),
                  const SizedBox(width: 6),
                  _InfoButton(onPressed: onInfo),
                  const Spacer(),
                  Text(
                    Strings.of(context).nextLevel(remaining),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: Stack(
                  children: [
                    Container(
                      height: 10,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      builder: (context, shown, _) => FractionallySizedBox(
                        widthFactor: shown,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                accent,
                                Color.lerp(accent, Colors.white, 0.4)!,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.6),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoButton extends StatelessWidget {
  const _InfoButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(5),
          child: Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level, required this.accent});

  final int level;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
      ),
      child: Text(
        Strings.of(context).level(level),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: accent,
        ),
      ),
    );
  }
}
