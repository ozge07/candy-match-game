import 'package:candy_match/game/audio_controller.dart';
import 'package:candy_match/game/candy_game.dart';
import 'package:candy_match/game/high_score_store.dart';
import 'package:candy_match/ui/game_page.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<CandyGame> pumpGame(WidgetTester tester, HighScoreStore store) async {
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

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('rekor deposu', () {
    test('boş başlarsa rekor sıfır', () async {
      final store = HighScoreStore();
      await store.load();

      expect(store.best.value, 0);
    });

    test('daha yüksek skor kaydedilir ve kalıcı olur', () async {
      final store = HighScoreStore();
      await store.load();

      expect(await store.submit(500), isTrue);
      expect(store.best.value, 500);

      // Yeni bir örnek aynı değeri okumalı.
      final reloaded = HighScoreStore();
      await reloaded.load();
      expect(reloaded.best.value, 500);
    });

    test('düşük ya da eşit skor rekoru değiştirmez', () async {
      final store = HighScoreStore();
      await store.load();
      await store.submit(500);

      expect(await store.submit(400), isFalse);
      expect(await store.submit(500), isFalse);
      expect(store.best.value, 500);
    });
  });

  group('oyun içinde rekor', () {
    testWidgets('HUD rekoru ve menü düğmesini gösteriyor', (tester) async {
      final store = HighScoreStore();
      await store.submit(750);
      await pumpGame(tester, store);

      expect(find.text('REKOR'), findsOneWidget);
      expect(find.text('750'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    });

    testWidgets('skor rekoru geçince rekor da yükseliyor', (tester) async {
      final store = HighScoreStore();
      await store.submit(100);
      final game = await pumpGame(tester, store);

      game.addScore(250);
      await tester.pump();

      expect(store.best.value, 250);
      expect(find.text('250'), findsWidgets);
    });

    testWidgets('oyun sonu kartında tekrar oyna yok, menüye dön var', (
      tester,
    ) async {
      final store = HighScoreStore();
      final game = await pumpGame(tester, store);

      game.endGame();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.text('TEKRAR OYNA'), findsNothing);
      expect(find.text('MENÜYE DÖN'), findsOneWidget);
      expect(find.text('ÇIKIŞ'), findsOneWidget);
    });
  });
}
