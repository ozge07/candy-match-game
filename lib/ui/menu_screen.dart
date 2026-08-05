import 'package:flutter/material.dart';

import '../i18n/strings.dart';
import 'package:flutter/services.dart';

import '../game/ads_controller.dart';
import '../game/audio_controller.dart';
import '../game/game_save_store.dart';
import '../game/high_score_store.dart';
import '../game/tip_store.dart';
import 'candy_artwork.dart';
import 'game_page.dart';
import 'high_score_badge.dart';
import 'menu_button.dart';

/// Ana menü: yeni oyun başlat ya da çık.
class MenuScreen extends StatefulWidget {
  const MenuScreen({
    required this.audio,
    required this.ads,
    required this.highScores,
    required this.saves,
    required this.tips,
    super.key,
  });

  final AudioController audio;

  /// Ödüllü reklam kontrolcüsü; oyun ekranına aktarılıyor.
  final AdsController ads;
  final HighScoreStore highScores;
  final GameSaveStore saves;
  final TipStore tips;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  /// Son geri tuşuna basılma anı. İki saniye içinde tekrar basılırsa çıkılıyor.
  DateTime? _sonGeri;

  /// Geri tuşu menüdeyken uygulamayı kapatıyor. Tek dokunuşla kapanmak
  /// istemiyoruz — oyuncu yanlışlıkla basınca oyundan atılmış oluyor.
  void _geriTusu(bool didPop, Object? result) {
    if (didPop) {
      return;
    }
    final simdi = DateTime.now();
    final onceki = _sonGeri;
    if (onceki != null && simdi.difference(onceki) < const Duration(seconds: 2)) {
      SystemNavigator.pop();
      return;
    }
    _sonGeri = simdi;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(Strings.of(context).pressBackAgain),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  void _openGame({SavedGame? resume}) {
    widget.audio.swap();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GamePage(
          ads: widget.ads,
          audio: widget.audio,
          highScores: widget.highScores,
          saves: widget.saves,
          tips: widget.tips,
          resume: resume,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metin = Strings.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _geriTusu,
      child: Scaffold(
      backgroundColor: const Color(0xFF0E0B24),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CandyArtwork(animation: _drift),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                Text(
                  '${metin.titleTop} ${metin.titleBottom}',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5,
                    color: Colors.white,
                    shadows: [
                      const Shadow(blurRadius: 16, color: Colors.black87),
                      Shadow(
                        blurRadius: 30,
                        color: const Color(0xFFFFC145).withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                HighScoreBadge(store: widget.highScores),
                const SizedBox(height: 16),
                const LanguageToggle(),
                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 44),
                  child: Column(
                    children: [
                      // Devam et yalnızca yarım kalmış bir oyun varken
                      // görünüyor; oyun bittiğinde kayıt silindiği için
                      // kendiliğinden kayboluyor. Varken birincil eylem o
                      // oluyor, yeni oyun ikinciye düşüyor.
                      ValueListenableBuilder<bool>(
                        valueListenable: widget.saves.hasSave,
                        builder: (context, hasSave, _) => Column(
                          children: [
                            if (hasSave) ...[
                              MenuButton(
                                label: metin.continueGame,
                                icon: Icons.play_circle_fill_rounded,
                                onPressed: () =>
                                    _openGame(resume: widget.saves.saved),
                              ),
                              const SizedBox(height: 16),
                            ],
                            MenuButton(
                              label: metin.newGame,
                              icon: Icons.play_arrow_rounded,
                              filled: !hasSave,
                              onPressed: _openGame,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      MenuButton(
                        label: metin.exit,
                        icon: Icons.close_rounded,
                        filled: false,
                        onPressed: SystemNavigator.pop,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 64),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}
