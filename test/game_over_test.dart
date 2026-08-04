import 'package:candy_match/game/audio_controller.dart';
import 'package:candy_match/game/candy_game.dart';
import 'package:candy_match/game/high_score_store.dart';
import 'package:candy_match/ui/game_page.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Oyun ekranını kurup içindeki [CandyGame] örneğini döndürür.
Future<CandyGame> pumpGame(WidgetTester tester, {HighScoreStore? store}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GamePage(audio: AudioController(), highScores: store),
    ),
  );
  await tester.pump();
  await tester.pump();
  return tester
      .widget<GameWidget<CandyGame>>(find.byType(GameWidget<CandyGame>))
      .game!;
}

/// Oyun sonu kartının açılma animasyonunu tamamlar.
Future<void> settleCard(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('oyun sonu', () {
    testWidgets('başlangıçta oyun sonu kartı yok', (tester) async {
      await pumpGame(tester);

      expect(find.text('OYUN BİTTİ'), findsNothing);
      expect(find.text('SKOR'), findsOneWidget);
    });

    testWidgets('hamle kalmayınca kart, skor ve düğmeler çıkar', (
      tester,
    ) async {
      final game = await pumpGame(tester);
      game.addScore(1234);
      game.registerMove();

      game.endGame();
      await settleCard(tester);

      expect(game.isOver.value, isTrue);
      expect(find.text('OYUN BİTTİ'), findsOneWidget);
      expect(find.text('SKORUN'), findsOneWidget);
      expect(find.text('1234'), findsWidgets);
      expect(find.text('1 hamle'), findsWidgets);
      expect(find.text('MENÜYE DÖN'), findsOneWidget);
      expect(find.text('ÇIKIŞ'), findsOneWidget);
      // Tekrar oyna kaldırıldı; yeni oyun menüden başlıyor.
      expect(find.text('TEKRAR OYNA'), findsNothing);
    });

    testWidgets('rekor kırılmadıysa kartta mevcut rekor yazıyor', (
      tester,
    ) async {
      final store = HighScoreStore();
      await store.submit(5000);
      final game = await pumpGame(tester, store: store);
      game.addScore(120);

      game.endGame();
      await settleCard(tester);

      expect(find.text('Rekor: 5000'), findsOneWidget);
      expect(find.text('YENİ REKOR!'), findsNothing);
    });

    testWidgets('rekor kırıldıysa kartta kutlama yazıyor', (tester) async {
      final store = HighScoreStore();
      await store.submit(100);
      final game = await pumpGame(tester, store: store);
      game.addScore(900);

      game.endGame();
      await settleCard(tester);

      expect(find.text('YENİ REKOR!'), findsWidgets);
    });

    testWidgets('endGame iki kez çağrılsa da tek sefer biter', (tester) async {
      final game = await pumpGame(tester);

      game.endGame();
      game.endGame();
      await settleCard(tester);

      expect(find.text('OYUN BİTTİ'), findsOneWidget);
    });
  });
}
