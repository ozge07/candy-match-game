import 'package:candy_match/game/audio_controller.dart';
import 'package:candy_match/game/board.dart';
import 'package:candy_match/game/candy.dart';
import 'package:candy_match/game/candy_game.dart';
import 'package:candy_match/game/game_save_store.dart';
import 'package:candy_match/game/high_score_store.dart';
import 'package:candy_match/game/tip_store.dart';
import 'package:candy_match/ui/game_page.dart';
import 'package:candy_match/ui/menu_screen.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<CandyGame> pumpGame(
  WidgetTester tester, {
  GameSaveStore? saves,
  SavedGame? resume,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GamePage(
        audio: AudioController(),
        saves: saves,
        resume: resume,
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return tester
      .widget<GameWidget<CandyGame>>(find.byType(GameWidget<CandyGame>))
      .game!;
}

Future<void> advance(WidgetTester tester, {int frames = 40}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Sonsuz arka plan animasyonu yüzünden ağacı elle söküyoruz.
Future<void> teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('kayıt deposu', () {
    test('boşken kayıt yok', () async {
      final store = GameSaveStore();
      await store.load();

      expect(store.hasSave.value, isFalse);
      expect(store.saved, isNull);
    });

    test('kaydedilen oyun geri okunuyor', () async {
      final store = GameSaveStore();
      await store.save(
        SavedGame(
          score: 1500,
          moves: 12,
          level: 2,
          rows: 2,
          cols: 2,
          types: const [0, 1, 2, 3],
          kinds: const [0, 1, 2, 0],
        ),
      );

      final reloaded = GameSaveStore();
      await reloaded.load();

      expect(reloaded.hasSave.value, isTrue);
      expect(reloaded.saved!.score, 1500);
      expect(reloaded.saved!.level, 2);
      expect(reloaded.saved!.types, const [0, 1, 2, 3]);
    });

    test('silince kayıt kalmıyor', () async {
      final store = GameSaveStore();
      await store.save(
        SavedGame(
          score: 10,
          moves: 1,
          level: 1,
          rows: 1,
          cols: 1,
          types: const [0],
          kinds: const [0],
        ),
      );
      await store.clear();

      expect(store.hasSave.value, isFalse);

      final reloaded = GameSaveStore();
      await reloaded.load();
      expect(reloaded.hasSave.value, isFalse);
    });
  });

  group('oyun kaydı', () {
    testWidgets('tahta oturunca oyun kaydediliyor', (tester) async {
      final saves = GameSaveStore();
      await pumpGame(tester, saves: saves);
      await advance(tester);

      expect(saves.hasSave.value, isTrue);
      expect(saves.saved!.rows, CandyGame.rows);
      expect(saves.saved!.types.length, CandyGame.rows * CandyGame.cols);
    });

    testWidgets('oyun bitince kayıt siliniyor', (tester) async {
      final saves = GameSaveStore();
      final game = await pumpGame(tester, saves: saves);
      await advance(tester);
      expect(saves.hasSave.value, isTrue);

      game.endGame();
      await tester.pump();

      expect(saves.hasSave.value, isFalse);
    });

    testWidgets('kayıttan devam edilince tahta aynı geliyor', (tester) async {
      final saves = GameSaveStore();
      final first = await pumpGame(tester, saves: saves);
      first.addScore(770);
      first.registerMove();
      await advance(tester);

      final save = saves.saved!;
      await teardown(tester);

      final resumed = await pumpGame(tester, saves: saves, resume: save);
      await advance(tester);
      final board = resumed.world.children.whereType<BoardComponent>().first;

      expect(resumed.score.value, save.score);
      expect(resumed.moves.value, save.moves);
      expect(resumed.level.value, save.level);
      for (var r = 0; r < CandyGame.rows; r++) {
        for (var c = 0; c < CandyGame.cols; c++) {
          final index = r * CandyGame.cols + c;
          expect(board.candyAt(r, c)!.type, save.types[index]);
          expect(board.candyAt(r, c)!.kind.index, save.kinds[index]);
        }
      }
    });
  });

  group('menüdeki devam et', () {
    testWidgets('kayıt yoksa görünmüyor', (tester) async {
      final saves = GameSaveStore();
      await tester.pumpWidget(
        MaterialApp(
          home: MenuScreen(
            audio: AudioController(),
            highScores: HighScoreStore(),
            saves: saves,
            tips: TipStore()..seen.value = true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('DEVAM ET'), findsNothing);
      expect(find.text('YENİ OYUN'), findsOneWidget);
      await teardown(tester);
    });

    testWidgets('kayıt varsa görünüyor', (tester) async {
      final saves = GameSaveStore();
      await saves.save(
        SavedGame(
          score: 300,
          moves: 4,
          level: 1,
          rows: 1,
          cols: 1,
          types: const [0],
          kinds: const [0],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MenuScreen(
            audio: AudioController(),
            highScores: HighScoreStore(),
            saves: saves,
            tips: TipStore()..seen.value = true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('DEVAM ET'), findsOneWidget);
      await teardown(tester);
    });
  });

  group('seviye zorluğu', () {
    testWidgets('seviye yükseldikçe şeker türü artıyor', (tester) async {
      final game = await pumpGame(tester);

      expect(game.level.value, 1);
      expect(game.activeTypes, CandyGame.startingTypes);

      game.level.value = 3;
      expect(game.activeTypes, CandyGame.startingTypes + 1);

      game.level.value = 5;
      expect(game.activeTypes, CandyGame.startingTypes + 2);

      // Tanımlı tür sayısında tavan yapıyor.
      game.level.value = 999;
      expect(game.activeTypes, Candy.typeCount);
      await advance(tester);
    });
  });
}
