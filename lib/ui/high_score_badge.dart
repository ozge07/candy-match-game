import 'package:flutter/material.dart';

import '../i18n/strings.dart';

import '../game/high_score_store.dart';

/// Menüdeki rekor rozeti: kupa ikonu, nefes alan bir hale ve skor.
///
/// Rekor henüz yoksa hiç görünmüyor — boş bir "0" göstermek yerine ilk skoru
/// bir hedef gibi bırakıyoruz.
class HighScoreBadge extends StatefulWidget {
  const HighScoreBadge({required this.store, super.key});

  final HighScoreStore store;

  @override
  State<HighScoreBadge> createState() => _HighScoreBadgeState();
}

class _HighScoreBadgeState extends State<HighScoreBadge>
    with SingleTickerProviderStateMixin {
  /// `late final` ile tembel kurulmuyor: rekor yokken `build` denetleyiciye hiç
  /// dokunmuyor, o zaman `dispose` içinde ilk kez kurulup çökmeye yol açıyordu.
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metin = Strings.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: widget.store.best,
      builder: (context, best, _) {
        if (best <= 0) {
          return const SizedBox.shrink();
        }
        return AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_pulse.value);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: const Color(0xFFFFD54A).withValues(alpha: 0.35 + t * 0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD54A).withValues(alpha: 0.18 + t * 0.22),
                    blurRadius: 22 + t * 14,
                    spreadRadius: t * 2,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: Color(0xFFFFD54A),
                size: 26,
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metin.highScoreLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: widget.store.best,
                    builder: (context, best, _) => Text(
                      '$best',
                      style: const TextStyle(
                        fontSize: 26,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFFD54A),
                        shadows: [
                          Shadow(blurRadius: 18, color: Color(0x88FFD54A)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
