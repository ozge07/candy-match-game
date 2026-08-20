import 'package:candy_match/game/board.dart';
import 'package:candy_match/game/candy.dart';
import 'package:candy_match/game/candy_game.dart';
import 'package:candy_match/i18n/app_language.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Şekerlerin görünüşü ve tahtanın canlılığı.
///
/// Buradaki testler "güzel mi" sorusuna cevap veremez ama görünüşü tümden
/// bozan iki sessiz hatayı yakalar: siluetin boş ya da kutusundan taşan bir
/// yol dönmesi (şeker görünmez ya da komşusunun üstüne biner) ve iki türün
/// aynı silueti alması (renk körü oyuncu için oyun oynanamaz hâle gelir).
/// [outer] dikdörtgeninin içinde kalan bir dikdörtgen bekler.
Matcher _within(Rect outer) => predicate<Rect>(
  (inner) =>
      inner.left >= outer.left &&
      inner.top >= outer.top &&
      inner.right <= outer.right &&
      inner.bottom <= outer.bottom,
  '$outer içinde kalan bir dikdörtgen',
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LanguageStore.debugOverride = AppLanguage.tr;
  });
  tearDown(() => LanguageStore.debugOverride = null);

  const box = Rect.fromLTWH(0, 0, 100, 100);

  test('her siluet kendi kutusunu dolduruyor ve dışına taşmıyor', () {
    for (var shape = 0; shape < Candy.shapeCount; shape++) {
      final bounds = Candy.shapeOf(box, shape).getBounds();

      expect(
        bounds.isEmpty,
        isFalse,
        reason: '$shape numaralı siluet boş — şeker görünmez olurdu',
      );
      // Kutunun en az yarısını kaplasın: aksi hâlde hücrede kaybolur.
      expect(bounds.width, greaterThan(box.width * 0.5), reason: 'şekil $shape');
      expect(
        bounds.height,
        greaterThan(box.height * 0.5),
        reason: 'şekil $shape',
      );
      // Kutunun dışına taşmasın: taşan şekil komşu hücreye girer. Gölge ve
      // blur zaten ayrı bir payla çiziliyor, siluetin kendisi taşmamalı.
      //
      // Küçük bir pay bırakılıyor çünkü `getBounds` eğrilerde kontrol
      // noktalarını da kutuya katıyor; çizilen eğri kontrol noktasına hiç
      // ulaşmadığı için ölçüm gerçekte olduğundan geniş çıkıyor. Pay,
      // gözle görülür taşmayı (eğik kapsül kutudan %6 taşıyordu)
      // yakalayacak kadar dar.
      const tolerans = 2.0;
      expect(
        bounds,
        _within(box.inflate(tolerans)),
        reason: '$shape numaralı siluet kutusundan taşıyor',
      );
    }
  });

  test('oynanan türlerin hepsi ayrı siluet', () {
    // Renk körü oyuncu şekerleri yalnızca siluetten ayırt ediyor.
    final imzalar = <String>{};
    for (var type = 0; type < Candy.typeCount; type++) {
      final bounds = Candy.shapeOf(box, type).getBounds();
      final metrik = Candy.shapeOf(box, type).computeMetrics().first;
      imzalar.add(
        '${bounds.width.toStringAsFixed(1)}x'
        '${bounds.height.toStringAsFixed(1)}@'
        '${metrik.length.toStringAsFixed(1)}',
      );
    }
    expect(
      imzalar.length,
      Candy.typeCount,
      reason: 'iki tür aynı siluete düşmüş',
    );
  });

  testWidgets('tahta şekerlerin ortak saatini ilerletiyor', (tester) async {
    // Salınım ve tahtayı süpüren ışık bu saate bağlı; durursa tahta donar.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Candy.clock = 0;
    final game = CandyGame();
    await tester.pumpWidget(GameWidget(game: game));
    await tester.pump();
    expect(game.world.children.whereType<BoardComponent>(), isNotEmpty);

    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(
      Candy.clock,
      greaterThan(0.3),
      reason: 'tahta saati ilerletmiyor, animasyonlar donuk kalır',
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
