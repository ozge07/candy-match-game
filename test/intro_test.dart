import 'package:candy_match/game/board.dart';
import 'package:candy_match/game/candy_game.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:candy_match/i18n/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<BoardComponent> pumpBoard(WidgetTester tester) async {
  final game = CandyGame();
  await tester.pumpWidget(GameWidget(game: game));
  await tester.pump();
  await tester.pump();
  return game.world.children.whereType<BoardComponent>().first;
}

/// Animasyon sonsuz döngüde olmadığı için elle kare ilerletiyoruz.
Future<void> advance(WidgetTester tester, {int frames = 40}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Testler Türkçe metinlere bakıyor; cihaz dilinden bağımsız olsun.
    LanguageStore.debugOverride = AppLanguage.tr;
  });
  tearDown(() => LanguageStore.debugOverride = null);

  group('tahtanın dökülerek gelmesi', () {
    testWidgets('şekerler tahtanın üstünden başlar', (tester) async {
      final board = await pumpBoard(tester);

      for (final (row, col) in [(0, 0), (7, 0), (3, 4)]) {
        final candy = board.candyAt(row, col)!;
        final target = board.cellCenter(row, col);
        expect(
          candy.position.y,
          lessThan(target.y),
          reason: '($row,$col) hedefinin üstünde başlamalı',
        );
        expect(candy.position.x, closeTo(target.x, 0.01));
      }
    });

    testWidgets('animasyon bitince hepsi hücresine oturur', (tester) async {
      final board = await pumpBoard(tester);
      await advance(tester);

      for (var r = 0; r < CandyGame.rows; r++) {
        for (var c = 0; c < CandyGame.cols; c++) {
          final candy = board.candyAt(r, c)!;
          final target = board.cellCenter(r, c);
          expect(
            candy.position.y,
            closeTo(target.y, 0.5),
            reason: '($r,$c) hücresine oturmalı',
          );
        }
      }
    });

    testWidgets('dökülürken hamle kabul edilmiyor', (tester) async {
      final board = await pumpBoard(tester);
      final a = board.candyAt(4, 3)!;
      final b = board.candyAt(4, 4)!;
      final typeA = a.type;
      final typeB = b.type;

      // Animasyon sürerken takas denemesi yok sayılmalı.
      await board.trySwap(a, b);

      expect(a.type, typeA);
      expect(b.type, typeB);
      expect(board.candyAt(4, 3), same(a));
      expect(board.candyAt(4, 4), same(b));

      await advance(tester);
    });
  });
}
