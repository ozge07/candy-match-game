import 'package:candy_match/game/audio_controller.dart';
import 'package:candy_match/game/game_save_store.dart';
import 'package:candy_match/game/high_score_store.dart';
import 'package:candy_match/game/tip_store.dart';
import 'package:candy_match/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('açılış ekranı ve yükleme çubuğu görünüyor', (tester) async {
    await tester.pumpWidget(
      CandyMatchApp(
        audio: AudioController(),
        highScores: HighScoreStore(),
        saves: GameSaveStore(),
        tips: TipStore(),
      ),
    );
    await tester.pump();

    expect(find.text('CANDY'), findsOneWidget);
    expect(find.text('MATCH'), findsOneWidget);
    expect(find.text('YÜKLENİYOR…'), findsOneWidget);

    // Açılış ekranı kendini menüye devreder. Arka plandaki şeker animasyonu
    // sonsuz döndüğü için `pumpAndSettle` kullanılamıyor; kareleri elle
    // ilerletiyoruz.
    // Test ortamında ses altyapısı yanıt vermez; yükleme zaman aşımına
    // düşene kadar (8 sn) ilerletiyoruz.
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('YENİ OYUN'), findsOneWidget);
    expect(find.text('ÇIKIŞ'), findsOneWidget);

    // Menünün arka plan animasyonu sonsuz döndüğü için ağacı elle söküyoruz;
    // aksi halde test bitiminde askıda kalan bir ticker kalıyor.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
