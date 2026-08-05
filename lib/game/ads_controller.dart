import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// Ödüllü reklamları yönetir: oyuncu reklamı sonuna kadar izlerse tahta
/// karıştırılıp oyun kaldığı yerden devam ediyor.
///
/// Hangi reklam kimliğinin kullanılacağına [AdConfig] karar veriyor: debug ve
/// profile derlemelerinde her zaman Google'ın test birimleri, release'de ise
/// `--dart-define` ile geçilmişse gerçek birim.
///
/// Kendi gerçek reklamına tıklamak AdMob hesabının kapatılmasına yol açar;
/// bu yüzden geliştirme derlemelerine gerçek kimlik hiç girmiyor.
class AdsController {
  AdsController({this.enabled = true});

  /// Reklamların hiç açılmadığı sürüm: testler ve reklam desteklenmeyen
  /// ortamlar için. Oyun reklamsız çalışmaya devam ediyor, "devam et"
  /// düğmesi hiç çıkmıyor.
  AdsController.disabled() : enabled = false;

  /// `false` ise SDK'ya hiç dokunulmuyor.
  final bool enabled;

  /// Reklam altyapısı yanıt vermezse oyunu bekletmeyelim.
  ///
  /// Yavaş bir cihazda ya da zayıf bağlantıda SDK'nın açılması uzun sürüyor;
  /// süre çok kısa olursa reklam hiç hazır olmuyor ve "devam et" hiç çıkmıyor.
  static const Duration _timeout = Duration(seconds: 30);

  RewardedAd? _ad;
  bool _initialised = false;
  bool _initialising = false;
  bool _loading = false;

  /// Gösterilecek hazır bir reklam var mı? Düğme buna göre çıkıyor.
  final ValueNotifier<bool> isReady = ValueNotifier<bool>(false);

  /// SDK'yı başlatır ve bir reklam hazırlar.
  ///
  /// Tekrar tekrar çağrılabilir: zaten hazırsa hiçbir şey yapmaz, daha önce
  /// başarısız olduysa yeniden dener. Her oyun başında çağırıyoruz ki geçici
  /// bir ağ sorunu bütün oturumu reklamsız bırakmasın.
  ///
  /// Hata yutuluyor: reklam yüklenemezse oyun reklamsız devam etmeli,
  /// oyuncu bundan etkilenmemeli.
  Future<void> initialise() async {
    if (!enabled || _initialising) {
      return;
    }
    if (_initialised) {
      // Altyapı ayakta ama elde reklam kalmamış olabilir (gösterildi ya da
      // yükleme başarısız oldu); yenisini hazırla.
      unawaited(_load());
      return;
    }
    _initialising = true;
    try {
      await MobileAds.instance.initialize().timeout(_timeout);
      AdConfig.debugDescribe();
      _initialised = true;
      unawaited(_load());
    } catch (error) {
      // `_initialised` false kalıyor; bir sonraki çağrı baştan deneyecek.
      debugPrint('Reklam altyapısı başlatılamadı: $error');
    } finally {
      _initialising = false;
    }
  }

  Future<void> _load() async {
    if (!enabled || !_initialised || _loading || _ad != null) {
      return;
    }
    _loading = true;
    final completer = Completer<void>();

    RewardedAd.load(
      adUnitId: AdConfig.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          isReady.value = true;
          _loading = false;
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onAdFailedToLoad: (error) {
          _ad = null;
          isReady.value = false;
          _loading = false;
          debugPrint('Ödüllü reklam yüklenemedi: $error');
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      ),
    );

    await completer.future;
  }

  /// Reklamı gösterir. Oyuncu **ödülü hak edecek kadar** izlediyse `true`
  /// döner; kapatırsa ya da reklam yoksa `false`.
  Future<bool> showRewarded() async {
    final ad = _ad;
    if (ad == null) {
      return false;
    }
    _ad = null;
    isReady.value = false;

    var earned = false;
    final closed = Completer<void>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!closed.isCompleted) {
          closed.complete();
        }
        // Bir sonraki tur için yeni reklam hazırla.
        unawaited(_load());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        debugPrint('Reklam gösterilemedi: $error');
        if (!closed.isCompleted) {
          closed.complete();
        }
        unawaited(_load());
      },
    );

    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    await closed.future;
    return earned;
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
    isReady.dispose();
  }
}
