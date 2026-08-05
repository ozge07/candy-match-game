import 'package:flutter_test/flutter_test.dart';
import 'package:candy_match/game/ad_config.dart';

/// Bu testler tek bir şeyi koruyor: **geliştirme derlemesi asla gerçek reklam
/// göstermemeli.** Kendi gerçek reklamına tıklamak geçersiz trafik sayılır ve
/// AdMob hesabının kapatılmasına yol açar.
///
/// Testler debug modda koştuğu için `kDebugMode` burada her zaman true.
void main() {
  const testPublisher = 'ca-app-pub-3940256099942544';

  group('AdConfig', () {
    test('geliştirme derlemesinde test reklamı kullanılıyor', () {
      expect(AdConfig.usingTestAds, isTrue);
    });

    test("kullanılan birim Google'ın test yayıncısına ait", () {
      expect(AdConfig.rewardedUnitId, startsWith(testPublisher));
    });

    test('birim kimliği boş değil', () {
      // Boş kimlikle RewardedAd.load çağrısı platform tarafında patlıyor.
      expect(AdConfig.rewardedUnitId, isNotEmpty);
    });
  });
}
