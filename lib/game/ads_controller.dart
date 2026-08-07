import 'package:flutter/foundation.dart';

import '../app_log.dart';

/// Odullu reklam saglayicisi arayuzu.
///
/// Oyun hangi reklam aginin kullanildigini bilmiyor; yalnizca bu arayuzu
/// cagiriyor. Saglayici degistirmek tek bir sinif yazmak demek — oyun kodu
/// hic degismiyor.
///
/// AdMob basta bu arayuzun arkasindaydi; hesap kapandigi icin kaldirildi.
/// Unity Ads (ya da baska bir ag) eklenirken yapilacak tek sey bu arayuzu
/// uygulayan yeni bir sinif yazip [AdsController]'a vermek.
abstract class RewardedAdProvider {
  /// Reklam gosterime hazir mi?
  ValueListenable<bool> get isReady;

  /// SDK'yi hazirlar. Tekrar tekrar cagrilabilir.
  Future<void> initialise();

  /// Odullu reklami gosterir. Odul hak edildiyse `true`.
  Future<bool> showRewarded();

  void dispose();
}

/// Reklam agi bagli degilken kullanilan saglayici.
///
/// Odulu dogrudan veriyor: oyuncu reklam aginin yoklugundan sorumlu degil.
/// "Devam et" hakki zaten tur basina bir kez ile sinirli, dolayisiyla oyun
/// dengesi bozulmuyor.
class NoAdsProvider implements RewardedAdProvider {
  NoAdsProvider();

  @override
  final ValueNotifier<bool> isReady = ValueNotifier<bool>(true);

  @override
  Future<void> initialise() async {
    AppLog.info('ads', 'reklam saglayicisi bagli degil, odul dogrudan veriliyor');
  }

  @override
  Future<bool> showRewarded() async => true;

  @override
  void dispose() => isReady.dispose();
}

/// Reklamlarin hic gosterilmedigi saglayici (testler icin).
class DisabledAdsProvider implements RewardedAdProvider {
  DisabledAdsProvider();

  @override
  final ValueNotifier<bool> isReady = ValueNotifier<bool>(false);

  @override
  Future<void> initialise() async {}

  @override
  Future<bool> showRewarded() async => false;

  @override
  void dispose() => isReady.dispose();
}

/// Oyunun kullandigi reklam denetleyicisi.
class AdsController {
  AdsController({RewardedAdProvider? provider})
      : provider = provider ?? NoAdsProvider();

  /// Reklamlarin hic acilmadigi surum: testler ve reklam desteklenmeyen
  /// ortamlar icin.
  AdsController.disabled() : provider = DisabledAdsProvider();

  final RewardedAdProvider provider;

  /// Gosterilecek hazir bir reklam var mi? Dugme buna gore cikiyor.
  ValueListenable<bool> get isReady => provider.isReady;

  /// Gercek bir reklam agi bagli mi? Arayuz metni buna gore degisiyor.
  bool get hasProvider => provider is! NoAdsProvider && provider is! DisabledAdsProvider;

  Future<void> initialise() => provider.initialise();

  Future<bool> showRewarded() => provider.showRewarded();

  void dispose() => provider.dispose();
}
