import 'dart:io';

import 'package:candy_match/i18n/app_language.dart';
import 'package:candy_match/i18n/strings.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dil desteğinin bütünlüğü.
///
/// İngilizce seçiliyken ekranda Türkçe metin kalmıştı ("0 hamle",
/// "sonraki seviyeye 2000"). Metinleri `Strings`'e yazıp arayüze bağlamayı
/// unutmak kolay olduğu için kaynağı tarayan bir test tutuyoruz.
void main() {
  group('çeviri bütünlüğü', () {
    test('İngilizcede Türkçe karakter kalmıyor', () {
      const en = Strings(AppLanguage.en);
      final turkce = RegExp('[çğıöşüÇĞİÖŞÜ]');

      final metinler = <String, String>{
        'loading': en.loading,
        'continueGame': en.continueGame,
        'newGame': en.newGame,
        'exit': en.exit,
        'highScoreLabel': en.highScoreLabel,
        'pressBackAgain': en.pressBackAgain,
        'score': en.score,
        'record': en.record,
        'backToMenu': en.backToMenu,
        'soundOn': en.soundOn,
        'soundOff': en.soundOff,
        'moves': en.moves(3),
        'bestScore': en.bestScore,
        'level': en.level(2),
        'harderEachLevel': en.harderEachLevel,
        'nextLevel': en.nextLevel(500),
        'levelTip': en.levelTip(2000),
        'gameOver': en.gameOver,
        'noMovesLeft': en.noMovesLeft,
        'yourScore': en.yourScore,
        'newRecord': en.newRecord,
        'watchingAd': en.watchingAd,
        'continueSubtitle': en.continueSubtitle,
        'backToMenuButton': en.backToMenuButton,
        'crossBlast': en.crossBlast,
        'megaBlast': en.megaBlast,
        'colourBlast': en.colourBlast,
        'bombRain': en.bombRain,
        'bigMatch': en.bigMatch,
      };

      for (final girdi in metinler.entries) {
        expect(
          turkce.hasMatch(girdi.value),
          isFalse,
          reason: '${girdi.key} çevrilmemiş: "${girdi.value}"',
        );
      }

      for (final tebrik in en.chainPraise) {
        expect(turkce.hasMatch(tebrik), isFalse, reason: 'tebrik: $tebrik');
      }
    });

    test('iki dil de aynı sayıda tebrik veriyor', () {
      expect(
        const Strings(AppLanguage.tr).chainPraise.length,
        const Strings(AppLanguage.en).chainPraise.length,
      );
    });

    test('arayüzde dile bağlanmamış Türkçe metin kalmadı', () {
      // Ekranda görünen metinler: Text(...), label:, tooltip:, showPraise(...)
      final desen = RegExp(
        r"""(Text\(|label: |tooltip: |showPraise\()'[^']*[çğışöüÇĞİŞÖÜ][^']*'""",
      );
      final kacanlar = <String>[];

      for (final dosya in Directory('lib').listSync(recursive: true)) {
        if (dosya is! File || !dosya.path.endsWith('.dart')) {
          continue;
        }
        // Çeviri tablosunun kendisi ve hata ekranı doğal olarak Türkçe içeriyor.
        if (dosya.path.contains('i18n') || dosya.path.contains('bootstrap')) {
          continue;
        }
        for (final eslesme in desen.allMatches(dosya.readAsStringSync())) {
          kacanlar.add('${dosya.path}: ${eslesme.group(0)}');
        }
      }

      expect(kacanlar, isEmpty, reason: kacanlar.join('\n'));
    });
  });
}
