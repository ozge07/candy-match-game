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
import 'package:candy_match/i18n/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [ekran] verilirse test yüzeyi o piksel boyutuna ayarlanıyor. Yerleşim
/// testleri buna muhtaç: varsayılan 800x600 yüzey hiçbir telefona ya da
/// tablete benzemiyor.
Future<CandyGame> pumpGame(WidgetTester tester, {Size? ekran}) async {
  if (ekran != null) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = ekran;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
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
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Testler Türkçe metinlere bakıyor; cihaz dilinden bağımsız olsun.
    LanguageStore.debugOverride = AppLanguage.tr;
  });
  tearDown(() => LanguageStore.debugOverride = null);

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
    testWidgets('telefon oranında tahta ekran genişliğini neredeyse kaplar', (
      tester,
    ) async {
      // Telefon oranı (1:2.22): yükseklik bol, sınırlayan şey genişlik.
      final game = await pumpGame(tester, ekran: const Size(1080, 2400));

      final boardWidth = CandyGame.cols * game.debugCellSize;
      expect(boardWidth / CandyGame.gameWidth, greaterThan(0.95));
    });

    testWidgets('tablet oranında tahta HUD ile seviye çubuğuna taşmaz', (
      tester,
    ) async {
      // Tablet oranı (1:1.6) telefondan belirgin şekilde kısa. Hücre boyu
      // yalnızca genişlikten hesaplanırsa tahta buraya sığmıyor ve HUD'un
      // altına taşıyor.
      final game = await pumpGame(tester, ekran: const Size(1200, 1920));
      final board = game.world.children.whereType<BoardComponent>().first;

      expect(
        board.position.y,
        greaterThanOrEqualTo(CandyGame.hudSpace),
        reason: 'tahtanın üstü HUD şeridine giriyor',
      );
      expect(
        board.position.y + board.size.y,
        lessThanOrEqualTo(game.worldHeight - CandyGame.levelBarSpace),
        reason: 'tahtanın altı seviye çubuğuna giriyor',
      );
    });

    testWidgets('yükseklik sınırlayınca tahta yatayda ortalanıyor', (
      tester,
    ) async {
      final game = await pumpGame(tester, ekran: const Size(1200, 1920));
      final board = game.world.children.whereType<BoardComponent>().first;

      // Dar kalan tahta kenara yaslanmamalı; iki yandaki boşluk eşit olmalı.
      final sagBosluk = CandyGame.gameWidth - (board.position.x + board.size.x);
      expect(board.position.x, closeTo(sagBosluk, 0.01));
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
