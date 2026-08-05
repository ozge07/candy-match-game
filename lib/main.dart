import 'dart:async';

import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import 'game/ads_controller.dart';
import 'game/audio_controller.dart';
import 'game/game_save_store.dart';
import 'game/high_score_store.dart';
import 'game/tip_store.dart';
import 'ui/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.setPortrait();

  // Reklam altyapısı arka planda açılıyor; oyunu bekletmiyor.
  final ads = AdsController();
  unawaited(ads.initialise());

  runApp(
    CandyMatchApp(
      audio: AudioController(),
      ads: ads,
      highScores: HighScoreStore(),
      saves: GameSaveStore(),
      tips: TipStore(),
    ),
  );
}

class CandyMatchApp extends StatelessWidget {
  const CandyMatchApp({
    required this.audio,
    required this.ads,
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
  final HighScoreStore highScores;
  final GameSaveStore saves;
  final TipStore tips;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Candy Match',
      debugShowCheckedModeBanner: false,
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
