import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:candy_match/game/ad_config.dart';
import 'package:candy_match/game/ads_controller.dart';
import 'package:candy_match/game/unity_ads_provider.dart';

/// Reklam katmaninin davranisi.
///
/// En onemlisi ilk grupta: **gelistirme derlemesi reklam agiyla hic
/// konusmamali.** Bu projede AdMob hesabi gecersiz trafik nedeniyle kapandi;
/// kural kodda kilitli ve burada sinaniyor. Biri ileride gevsetirse test duser.
void main() {
  group('gelistirme derlemesinde reklam yok', () {
    test('yayin disinda reklamlar tamamen kapali', () {
      expect(kReleaseMode, isFalse);
      expect(AdConfig.adsEnabled, isFalse,
          reason: 'gelistirme derlemesi reklam agiyla hic konusmamali');
    });

    test('saglayici dogrudan kurulsa bile istek gitmiyor', () async {
      // Ikinci savunma hatti: AdConfig atlanip saglayici elle kurulsa bile
      // yayin disinda hicbir reklam cagrisi yapilmiyor.
      final provider = UnityRewardedProvider(
        gameId: '000000000',
        placementId: 'Rewarded_Android',
      );
      await provider.initialise();
      expect(provider.isReady.value, isFalse);
      expect(await provider.showRewarded(), isFalse);
      provider.dispose();
    });
  });

  group('saglayici bagli degilken', () {
    test('odul dogrudan veriliyor', () async {
      final ads = AdConfig.buildController();
      expect(ads.hasProvider, isFalse);
      expect(await ads.showRewarded(), isTrue,
          reason: 'reklam agi yokken oyuncu ozellikten mahrum kalmamali');
      ads.dispose();
    });

    test('dugme gorunur kaliyor', () {
      final ads = AdsController();
      expect(ads.isReady.value, isTrue);
      ads.dispose();
    });
  });

  group('reklamlar kapaliyken', () {
    test('odul verilmiyor ve dugme cikmiyor', () async {
      final ads = AdsController.disabled();
      expect(ads.isReady.value, isFalse);
      expect(await ads.showRewarded(), isFalse);
      ads.dispose();
    });
  });
}
