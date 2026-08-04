import 'package:candy_match/game/audio_controller.dart';
import 'package:candy_match/game/tip_store.dart';
import 'package:candy_match/ui/game_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpGame(WidgetTester tester, TipStore tips) async {
  await tester.pumpWidget(
    MaterialApp(home: GamePage(audio: AudioController(), tips: tips)),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> advance(WidgetTester tester, {int frames = 40}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// İpucu balonu görünür mü? Kapalıyken de ağaçta duruyor, saydamlığı 0.
bool tipVisible(WidgetTester tester) {
  final finder = find.ancestor(
    of: find.text('Seviye atladıkça zorlaşır'),
    matching: find.byType(AnimatedOpacity),
  );
  if (finder.evaluate().isEmpty) {
    return false;
  }
  return tester.widget<AnimatedOpacity>(finder.first).opacity > 0;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('bilgi ipucu', () {
    testWidgets('ilk oyunda kendiliğinden açılıyor', (tester) async {
      final tips = TipStore();
      await pumpGame(tester, tips);
      await tester.pump();

      expect(tipVisible(tester), isTrue);
      expect(tips.seen.value, isTrue, reason: 'bir daha açılmasın diye');

      await advance(tester, frames: 140);
    });

    testWidgets('5 saniye sonra kendiliğinden kapanıyor', (tester) async {
      await pumpGame(tester, TipStore());
      await tester.pump();
      expect(tipVisible(tester), isTrue);

      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 400));

      expect(tipVisible(tester), isFalse);
      await advance(tester);
    });

    testWidgets('daha önce görüldüyse açılmıyor', (tester) async {
      final tips = TipStore()..seen.value = true;
      await pumpGame(tester, tips);
      await tester.pump();

      expect(tipVisible(tester), isFalse);
      await advance(tester);
    });

    testWidgets('bilgi düğmesi ipucunu tekrar açıyor', (tester) async {
      final tips = TipStore()..seen.value = true;
      await pumpGame(tester, tips);
      await advance(tester);
      expect(tipVisible(tester), isFalse);

      await tester.tap(find.byIcon(Icons.info_outline_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(tipVisible(tester), isTrue);

      // Tekrar 5 saniye sonra kapanmalı.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tipVisible(tester), isFalse);

      await advance(tester);
    });

    testWidgets('ipucu durumu kalıcı olarak saklanıyor', (tester) async {
      final tips = TipStore();
      await pumpGame(tester, tips);
      await advance(tester, frames: 140);

      final reloaded = TipStore();
      await reloaded.load();
      expect(reloaded.seen.value, isTrue);
    });
  });
}
