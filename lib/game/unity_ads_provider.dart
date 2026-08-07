import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';

import '../app_log.dart';
import 'ads_controller.dart';

/// Unity Ads ile odullu reklam saglayicisi.
///
/// **Ikinci savunma hatti.** Bu sinif zaten yalnizca yayin derlemesinde
/// kuruluyor ([AdConfig.adsEnabled] `kReleaseMode` sarti koyuyor). Yine de
/// biri onu atlayip burayi dogrudan kullanirsa diye butun metotlar yayin
/// disi derlemede hicbir sey yapmadan donuyor: SDK baslatilmiyor, tek bir
/// istek bile gitmiyor.
///
/// Sebep somut: bu projede AdMob hesabi gecersiz trafik nedeniyle kapandi.
/// Gelistirme derlemesinin reklam agiyla hic konusmamasi, ikinci bir
/// reddedilmeyi imkansiz kiliyor.
class UnityRewardedProvider implements RewardedAdProvider {
  UnityRewardedProvider({required this.gameId, required this.placementId});

  /// Unity Dashboard'daki oyun kimligi (platforma ozel).
  final String gameId;

  /// Odullu yerlesim kimligi.
  final String placementId;

  @override
  final ValueNotifier<bool> isReady = ValueNotifier<bool>(false);

  @override
  Future<void> initialise() async {
    if (!kReleaseMode) {
      AppLog.info('ads', 'yayin derlemesi degil, Unity Ads baslatilmadi');
      return;
    }
    await UnityAds.init(
      gameId: gameId,
      // Yayin derlemesindeyiz: gercek reklamlar.
      testMode: false,
      onComplete: () {
        AppLog.info('ads', 'Unity Ads hazir (gercek reklamlar)');
        _yukle();
      },
      onFailed: (error, message) {
        AppLog.warn('ads', 'Unity Ads baslatilamadi ($error)', message);
      },
    );
  }

  void _yukle() {
    if (!kReleaseMode) {
      return;
    }
    unawaited(
      UnityAds.load(
        placementId: placementId,
        onComplete: (_) => isReady.value = true,
        onFailed: (_, error, message) {
          isReady.value = false;
          AppLog.warn('ads', 'odullu reklam yuklenemedi ($error)', message);
        },
      ),
    );
  }

  @override
  Future<bool> showRewarded() async {
    if (!kReleaseMode || !isReady.value) {
      _yukle();
      return false;
    }
    isReady.value = false;

    final sonuc = Completer<bool>();
    void bitir(bool oduluAldi) {
      if (!sonuc.isCompleted) {
        sonuc.complete(oduluAldi);
      }
      _yukle();
    }

    await UnityAds.showVideoAd(
      placementId: placementId,
      onComplete: (_) => bitir(true),
      onSkipped: (_) => bitir(false),
      onFailed: (_, error, message) {
        AppLog.warn('ads', 'reklam gosterilemedi ($error)', message);
        bitir(false);
      },
    );

    return sonuc.future;
  }

  @override
  void dispose() => isReady.dispose();
}
