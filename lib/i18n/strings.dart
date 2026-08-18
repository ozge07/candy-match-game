import 'package:flutter/material.dart';

import 'app_language.dart';

/// Ekranda görünen bütün metinler.
///
/// Ayrı bir çeviri paketi ve kod üretimi kullanmıyoruz: oyunda birkaç düzine
/// metin var ve iki dil yan yana durunca çeviriyi gözden kaçırmak zorlaşıyor.
class Strings {
  const Strings(this.language);

  final AppLanguage language;

  /// En yakın [LanguageScope]'tan okur. Dil değişince bu widget'ı kullanan
  /// her yer kendiliğinden yeniden çiziliyor.
  static Strings of(BuildContext context) {
    final kapsam = context.dependOnInheritedWidgetOfExactType<_LanguageData>();
    // Kapsam bulunamazsa cihazın diline düşüyoruz; eksik bir sarmalayıcı
    // yüzünden ekran çökmesin.
    return kapsam?.strings ?? Strings(LanguageStore.deviceLanguage());
  }

  String _pick(String tr, String en) => language == AppLanguage.tr ? tr : en;

  // --- Açılış ve menü ---
  String get titleTop => 'CANDY';
  String get titleBottom => 'MATCH';
  String get loading => _pick('YÜKLENİYOR…', 'LOADING…');
  String get continueGame => _pick('DEVAM ET', 'CONTINUE');
  String get newGame => _pick('YENİ OYUN', 'NEW GAME');
  String get exit => _pick('ÇIKIŞ', 'EXIT');
  String get highScoreLabel => _pick('EN YÜKSEK SKOR', 'HIGH SCORE');
  String get pressBackAgain =>
      _pick('Çıkmak için tekrar geri bas', 'Press back again to exit');

  // --- HUD ---
  String get score => _pick('SKOR', 'SCORE');
  String get record => _pick('REKOR', 'BEST');
  String get backToMenu => _pick('Menüye dön', 'Back to menu');
  String get soundOn => _pick('Sesi aç', 'Turn sound on');
  String get soundOff => _pick('Sesi kapat', 'Turn sound off');
  String moves(int count) => _pick('$count hamle', '$count moves');
  String get bestScore => _pick('en iyi skor', 'best score');
  String get leadingNow => _pick('lider sensin', "you're leading");

  // --- Seviye ---
  String level(int value) => _pick('SEVİYE $value', 'LEVEL $value');
  String get harderEachLevel =>
      _pick('Seviye atladıkça zorlaşır', 'It gets harder each level');
  String nextLevel(int points) =>
      _pick('sonraki seviyeye $points', '$points to next level');

  /// [points] seviye başına gereken puan; oyun sabitinden geliyor.
  String levelTip(int points) => _pick(
    'Her $points puanda seviye atlarsın; yeni şeker türleri eklenir, '
        'eşleşme bulmak zorlaşır.',
    'You level up every $points points; new candy types appear and '
        'matches get harder to find.',
  );

  // --- Oyun sonu ---
  String get gameOver => _pick('OYUN BİTTİ', 'GAME OVER');
  String get noMovesLeft =>
      _pick('Yapılacak hamle kalmadı', 'No moves left');
  String get yourScore => _pick('SKORUN', 'YOUR SCORE');
  String get newRecord => _pick('YENİ REKOR!', 'NEW RECORD!');
  String get watchingAd => _pick('REKLAM AÇILIYOR…', 'LOADING AD…');
  String get continueSubtitle =>
      _pick('tahta karışsın', 'shuffle the board');
  String get backToMenuButton => _pick('MENÜYE DÖN', 'BACK TO MENU');

  // --- Oyun içi tebrikler (Flame tarafında çiziliyor) ---
  String get boom => _pick('BOOM!', 'BOOM!');
  String get crossBlast => _pick('ÇAPRAZ PATLAMA!', 'CROSS BLAST!');
  String get megaBlast => _pick('MEGA PATLAMA!', 'MEGA BLAST!');
  String get colourBlast => _pick('RENK PATLAMASI!', 'COLOUR BLAST!');
  String get bombRain => _pick('BOMBA YAĞMURU!', 'BOMB RAIN!');
  String get bigMatch => _pick('HARİKA!', 'GREAT!');

  /// Zincir uzadıkça sırayla çıkan tebrikler.
  List<String> get chainPraise => language == AppLanguage.tr
      ? const ['GÜZEL!', 'SÜPER!', 'HARİKA!', 'MUHTEŞEM!', 'İNANILMAZ!']
      : const ['NICE!', 'SUPER!', 'GREAT!', 'AWESOME!', 'INCREDIBLE!'];
}

/// Dili ağaca yayar ve değiştiğinde altındaki her şeyi yeniler.
class LanguageScope extends StatelessWidget {
  const LanguageScope({required this.store, required this.child, super.key});

  final LanguageStore store;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: store.language,
      builder: (context, language, _) => _LanguageData(
        strings: Strings(language),
        store: store,
        child: child,
      ),
    );
  }

  /// Dili değiştirmek isteyen düğmeler bunu kullanıyor.
  static LanguageStore storeOf(BuildContext context) {
    final kapsam = context.dependOnInheritedWidgetOfExactType<_LanguageData>();
    assert(kapsam != null, 'LanguageScope ağaçta bulunamadı');
    return kapsam!.store;
  }
}

class _LanguageData extends InheritedWidget {
  const _LanguageData({
    required this.strings,
    required this.store,
    required super.child,
  });

  final Strings strings;
  final LanguageStore store;

  @override
  bool updateShouldNotify(_LanguageData oldWidget) =>
      oldWidget.strings.language != strings.language;
}

/// Menüdeki dil düğmesi: TR ile EN arasında geçiş yapıyor.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final store = LanguageScope.storeOf(context);
    final secili = Strings.of(context).language;

    return Semantics(
      label: secili == AppLanguage.tr
          ? 'Dil: Türkçe. Değiştirmek için dokun.'
          : 'Language: English. Tap to change.',
      button: true,
      child: Material(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: store.toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final dil in AppLanguage.values)
                  _Chip(language: dil, selected: dil == secili),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.language, required this.selected});

  final AppLanguage language;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFC145) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        language.code,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
          color: selected
              ? const Color(0xFF241F4D)
              : Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
