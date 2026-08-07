import 'dart:async';

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import 'bootstrap.dart';
import 'game/ad_config.dart';
import 'game/ads_controller.dart';
import 'game/audio_controller.dart';
import 'game/game_save_store.dart';
import 'game/high_score_store.dart';
import 'game/tip_store.dart';
import 'i18n/app_language.dart';
import 'i18n/strings.dart';
import 'ui/splash_screen.dart';

/// Oyunun zemin rengi; hata ekranı da bununla boyanıyor.
const Color _background = Color(0xFF141130);

Future<void> main() => bootstrap(() async {
  await Flame.device.setPortrait();

  // Reklam altyapısı arka planda açılıyor; oyunu bekletmiyor.
  final ads = AdConfig.buildController();
  unawaited(ads.initialise());

  // Dil tercihi ilk ekran çizilmeden hazır olsun.
  final languages = LanguageStore();
  await languages.load();

  return CandyMatchApp(
    audio: AudioController(),
    ads: ads,
    languages: languages,
    highScores: HighScoreStore(),
    saves: GameSaveStore(),
    tips: TipStore(),
  );
}, background: _background);

class CandyMatchApp extends StatelessWidget {
  const CandyMatchApp({
    required this.audio,
    required this.ads,
    required this.languages,
    required this.highScores,
    required this.saves,
    required this.tips,
    super.key,
  });

  /// Ses altyapısı ve rekor açılış ekranında yüklenip tüm ekranlarda
  /// paylaşılıyor.
  final AudioController audio;

  /// Ödüllü reklam kontrolcüsü; oyun sonu kartındaki "devam et" buna bakıyor.
  final AdsController ads;

  /// Seçilen dil; bütün ekranlar buradan okuyor.
  final LanguageStore languages;
  final HighScoreStore highScores;
  final GameSaveStore saves;
  final TipStore tips;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Candy Match',
      debugShowCheckedModeBanner: false,
      // Dil kapsamı Navigator'ın üstünde olmalı: `home:` içine konursa
      // sonradan açılan sayfalar kapsamın dışında kalıyor.
      builder: (context, child) =>
          LanguageScope(store: languages, child: child ?? const SizedBox()),
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: SplashScreen(
        audio: audio,
        ads: ads,
        highScores: highScores,
        saves: saves,
          tips: tips,
      ),
    );
  }
}
