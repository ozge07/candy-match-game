import 'dart:io';

import 'package:flutter/foundation.dart';

/// Reklam kimliklerinin tek kaynağı.
///
/// **Gerçek kimlikler bu dosyada yazmaz.** Kaynakta yalnızca Google'ın herkese
/// açık test birimleri var; gerçek değerler derleme sırasında geçiliyor:
///
/// ```bash
/// flutter build appbundle --release \
///   --dart-define=ADMOB_REWARDED_ANDROID=ca-app-pub-XXXX/YYYY
/// ```
///
/// Hiçbir şey geçilmezse test kimlikleri kullanılır. Debug ve profile
/// derlemelerinde ise gerçek kimlik verilmiş olsa bile **her zaman** test
/// reklamı gösterilir: kendi gerçek reklamına tıklamak geçersiz trafik sayılır
/// ve AdMob hesabının kapatılmasına yol açar.
class AdConfig {
  const AdConfig._();

  // Google'ın belgelerinde yayımladığı test birimleri. Kazanç getirmezler,
  // depoda durmalarında sakınca yok.
  static const String _testRewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedIos =
      'ca-app-pub-3940256099942544/1712485313';

  // Derleme sırasında verilmezse boş kalır.
  static const String _realRewardedAndroid = String.fromEnvironment(
    'ADMOB_REWARDED_ANDROID',
  );
  static const String _realRewardedIos = String.fromEnvironment(
    'ADMOB_REWARDED_IOS',
  );

  /// Test reklamı mı gösteriliyor?
  static bool get usingTestAds {
    if (kDebugMode || kProfileMode) {
      return true;
    }
    return _realUnitId.isEmpty;
  }

  static String get _realUnitId =>
      Platform.isIOS ? _realRewardedIos : _realRewardedAndroid;

  static String get _testUnitId =>
      Platform.isIOS ? _testRewardedIos : _testRewardedAndroid;

  /// Ödüllü reklam birimi kimliği.
  static String get rewardedUnitId => usingTestAds ? _testUnitId : _realUnitId;

  /// Açılışta bir kez günlüğe yazılıyor; yanlış derlemeyle yayına çıkmayı
  /// fark etmeyi kolaylaştırıyor.
  static void debugDescribe() {
    debugPrint(
      usingTestAds
          ? 'AdMob: TEST reklamları kullanılıyor ($_testUnitId)'
          : 'AdMob: GERÇEK reklamlar kullanılıyor',
    );
  }
}
