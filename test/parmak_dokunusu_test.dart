import 'package:candy_match/game/board.dart';
import 'package:candy_match/game/candy_game.dart';
import 'package:candy_match/i18n/app_language.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gerçek parmakla dokunma.
///
/// Parmak dokunurken hiçbir zaman tam olarak yerinde durmuyor; birkaç
/// piksellik kayma Flame'in olayı `onTapUp` yerine sürükleme olarak
/// sınıflamasına yetiyor. Kayma yarım hücreyi geçmediği için hamle de
/// sayılmıyordu, yani telefonda **dokunarak şeker seçmek hiç çalışmıyordu**.
///
/// Emulator'de görünmüyordu: `adb input tap` hiç kaymadan basıp bırakıyor ve
/// o yolda `onTapUp` düzgün tetikleniyor. Hatayı yalnızca gerçek cihaz
/// gösteriyordu.
Future<({CandyGame game, BoardComponent board})> pumpBoard(
  WidgetTester tester, {
  required Size ekran,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = ekran;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final game = CandyGame();
  await tester.pumpWidget(GameWidget(game: game));
  await tester.pump();
  await tester.pump();
  // Şekerler açılışta yukarıdan düşüyor; yerleşmeden konumları okunamaz.
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  return (
    game: game,
    board: game.world.children.whereType<BoardComponent>().first,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LanguageStore.debugOverride = AppLanguage.tr;
  });
  tearDown(() => LanguageStore.debugOverride = null);

  testWidgets('birkaç piksel kayan dokunuş şekeri seçiyor', (tester) async {
    final kurulum = await pumpBoard(tester, ekran: const Size(1080, 2400));
    final board = kurulum.board;
    final seker = board.candyAt(2, 3);
    expect(seker, isNotNull, reason: 'tahta dolu başlamalı');
    expect(seker!.selected, isFalse, reason: 'başlangıçta seçili olmamalı');

    /*
     * Dünya -> ekran: kamera sol üste sabit ve ölçek genişlikten geliyor,
     * tahta da oyunun içinde `_boardTop` kadar aşağıda.
     */
    final olcek = 1080 / CandyGame.gameWidth;
    final merkez = board.position + seker.position;
    final nokta = Offset(merkez.x * olcek, merkez.y * olcek);

    // Yarım hücreyi geçmeyen kayma: Flame bunu sürükleme sayıyor ama
    // oyuncunun niyeti dokunmak.
    await tester.dragFrom(nokta, const Offset(5, 4));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(
      seker.selected,
      isTrue,
      reason: 'kayan dokunuş da şekeri seçmeli',
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
