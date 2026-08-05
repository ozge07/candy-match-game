import 'package:candy_match/game/ads_controller.dart';
import 'package:candy_match/game/audio_controller.dart';
import 'package:candy_match/game/board.dart';
import 'package:candy_match/game/candy.dart';
import 'package:candy_match/game/candy_game.dart';
import 'package:candy_match/game/level_theme.dart';
import 'package:candy_match/ui/game_page.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<CandyGame> pumpGame(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(home: GamePage(
        ads: AdsController.disabled(),audio: AudioController())),
  );
  await tester.pump();
  await tester.pump();
  return tester
      .widget<GameWidget<CandyGame>>(find.byType(GameWidget<CandyGame>))
      .game!;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('seviye teması', () {
    test('seviyeyle değişen tek şey tahta rengi', () {
      final first = LevelTheme.forLevel(1);
      final second = LevelTheme.forLevel(2);
      final third = LevelTheme.forLevel(3);

      expect(second.boardColor, isNot(first.boardColor));
      expect(third.boardColor, isNot(second.boardColor));
      expect(first.boardColor, const Color(0xFF241F4D));
    });

    test('çok yüksek seviyeler de üretilebiliyor', () {
      final theme = LevelTheme.forLevel(500);

      expect(theme.level, 500);
      expect(theme.boardColor, isNotNull);
    });
  });

  group('elemanlar seviyeden bağımsız', () {
    test('şeker şekli sadece türe bağlı', () {
      for (var type = 0; type < Candy.typeCount; type++) {
        final candy = Candy(
          type: type,
          row: 0,
          col: 0,
          position: Vector2.zero(),
          cellSize: 40,
        );
        expect(candy.shape, type);
        expect(candy.color, Candy.palette[type]);
      }
    });

    testWidgets('seviye atlayınca şekerlerin şekli ve rengi değişmez', (
      tester,
    ) async {
      final game = await pumpGame(tester);
      final board = game.world.children.whereType<BoardComponent>().first;
      final sample = board.candyAt(0, 0)!;
      final shapeBefore = sample.shape;
      final colourBefore = sample.color;
      final boardColourBefore = board.theme.boardColor;

      game.addScore(CandyGame.pointsPerLevel);
      await tester.pump();

      expect(sample.shape, shapeBefore);
      expect(sample.color, colourBefore);
      expect(board.theme.boardColor, isNot(boardColourBefore));
    });
  });

  group('seviye atlama', () {
    testWidgets('oyun birinci seviyede başlar', (tester) async {
      final game = await pumpGame(tester);

      expect(game.level.value, 1);
      expect(find.text('SEVİYE 1'), findsOneWidget);
    });

    testWidgets('eşik geçilince seviye atlanır ve tema değişir', (
      tester,
    ) async {
      final game = await pumpGame(tester);
      final before = game.theme;

      game.addScore(CandyGame.pointsPerLevel);
      await tester.pump();

      expect(game.level.value, 2);
      expect(game.theme.boardColor, isNot(before.boardColor));
      expect(find.text('SEVİYE 2'), findsOneWidget);
    });

    testWidgets('eşiğin altında seviye değişmez', (tester) async {
      final game = await pumpGame(tester);

      game.addScore(CandyGame.pointsPerLevel - 1);
      await tester.pump();

      expect(game.level.value, 1);
    });

    testWidgets('tek hamlede birkaç eşik geçilse de seviye doğru', (
      tester,
    ) async {
      final game = await pumpGame(tester);

      game.addScore(CandyGame.pointsPerLevel * 3 + 10);
      await tester.pump();

      expect(game.level.value, 4);
      expect(game.theme.level, 4);
    });
  });

  group('yerleşim', () {
    testWidgets('tahta ekran genişliğini neredeyse tamamen kaplar', (
      tester,
    ) async {
      final game = await pumpGame(tester);

      // Dünya sabit genişlikte; tahta kenar boşlukları dışında her yeri kaplar.
      final boardWidth = CandyGame.cols * game.debugCellSize;
      expect(boardWidth / CandyGame.gameWidth, greaterThan(0.95));
    });

    testWidgets('dünya yüksekliği ekran oranına uyar', (tester) async {
      final game = await pumpGame(tester);

      // Test yüzeyi 800x600; dünya genişliği sabit 720 olduğuna göre
      // yükseklik oranla büyümeli.
      expect(game.worldHeight, greaterThan(0));
      expect(
        game.worldHeight / CandyGame.gameWidth,
        closeTo(600 / 800, 0.01),
      );
    });
  });
}
