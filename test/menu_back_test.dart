import 'package:candy_match/game/ads_controller.dart';
import 'package:candy_match/game/audio_controller.dart';
import 'package:candy_match/game/game_save_store.dart';
import 'package:candy_match/game/high_score_store.dart';
import 'package:candy_match/game/tip_store.dart';
import 'package:candy_match/ui/menu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:candy_match/i18n/app_language.dart';
import 'package:candy_match/i18n/strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Menüde geri tuşu davranışı: tek dokunuşla kapanmamalı.
///
/// Oyuncu yanlışlıkla geri tuşuna basınca oyundan atılıyordu; artık iki
/// saniye içinde iki kez basması gerekiyor.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Testler Türkçe metinlere bakıyor; cihaz dilinden bağımsız olsun.
    LanguageStore.debugOverride = AppLanguage.tr;
  });
  tearDown(() => LanguageStore.debugOverride = null);

  Future<void> pumpMenu(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LanguageScope(
          store: LanguageStore(),
          child: MenuScreen(
          audio: AudioController(),
          ads: AdsController.disabled(),
          highScores: HighScoreStore(),
          saves: GameSaveStore(),
            tips: TipStore(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Sistemin geri tuşunu taklit eder.
  Future<void> geriBas(WidgetTester tester) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      'flutter/navigation',
      const JSONMethodCodec().encodeMethodCall(
        const MethodCall('popRoute'),
      ),
      (_) {},
    );
    await tester.pump();
  }

  testWidgets('tek geri tuşu uyarı gösteriyor, uygulamayı kapatmıyor', (
    tester,
  ) async {
    await pumpMenu(tester);

    await geriBas(tester);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Çıkmak için tekrar geri bas'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('iki saniye sonra uyarı yeniden çıkıyor', (tester) async {
    await pumpMenu(tester);

    await geriBas(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Çıkmak için tekrar geri bas'), findsOneWidget);

    // Süre dolduktan sonraki basış yine uyarı vermeli, çıkış değil.
    await tester.pump(const Duration(seconds: 3));
    await geriBas(tester);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Çıkmak için tekrar geri bas'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
