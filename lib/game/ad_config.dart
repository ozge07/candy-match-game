import 'package:flutter/foundation.dart';

import 'ads_controller.dart';
import 'unity_ads_provider.dart';

/// Reklam yapilandirmasi.
///
/// ## Gelistirirken hic reklam yok
///
/// Yayin (release) disi **hicbir** derlemede reklam saglayicisi kurulmuyor:
/// SDK baslatilmiyor, tek bir istek bile gitmiyor, test reklami dahi
/// acilmiyor. Kimlik `--dart-define` ile verilmis olsa bile yok sayiliyor.
///
/// Sebep: bu projede AdMob hesabi gecersiz trafik nedeniyle kapandi. Ikinci
/// bir reddedilme riskini tamamen ortadan kaldirmanin tek kesin yolu,
/// gelistirme derlemesinin reklam agiyla hic konusmamasi.
///
/// Ozellikler bu sirada kaybolmuyor: saglayici yokken odul dogrudan veriliyor
/// (bkz. [NoAdsProvider]).
///
/// ## Yayinda gercek reklam
///
/// `flutter build --release` ile ve `UNITY_GAME_ID` gecilerek derlendiginde
/// Unity saglayicisi devreye giriyor (bkz. `tool/build_release.sh`).
class AdConfig {
  const AdConfig._();

  static const String _unityGameId = String.fromEnvironment('UNITY_GAME_ID');

  static const String _unityPlacementId = String.fromEnvironment(
    'UNITY_REWARDED_PLACEMENT',
    defaultValue: 'Rewarded_Android',
  );

  /// Yayin paketinde TEST reklami goster.
  ///
  /// Kendi uygulamani gercek pakette denemek icin: `tool/build_qa.sh`.
  /// Unity test reklami gosterir — gelir yazmaz, gecersiz trafik riski yok.
  /// Varsayilan `false`; Play'e giden pakette gercek reklam cikar.
  static const bool testMode = bool.fromEnvironment('UNITY_TEST_MODE');

  /// Reklamlar yalnizca yayin derlemesinde ve kimlik verilmisse etkin.
  static bool get adsEnabled => kReleaseMode && _unityGameId.isNotEmpty;

  /// Oyunun kullanacagi denetleyici.
  static AdsController buildController() {
    if (!adsEnabled) {
      return AdsController();
    }
    return AdsController(
      provider: UnityRewardedProvider(
        gameId: _unityGameId,
        placementId: _unityPlacementId,
        testMode: testMode,
      ),
    );
  }
}
