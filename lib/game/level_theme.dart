import 'package:flutter/material.dart';

/// Bir seviyenin görsel kimliği.
///
/// Seviye atlandığında **yalnızca tahta rengi** değişiyor: şekerlerin şekli ve
/// rengi sabit kalıyor ki oyuncu seviye başında yeniden tanıma yapmak zorunda
/// kalmasın. Tahta rengi her seviyede sabit bir açı kadar döndürüldüğü için
/// seviye sayısı sınırsız.
@immutable
class LevelTheme {
  const LevelTheme({required this.level, required this.boardColor});

  /// Her seviyede tahta renginin döneceği açı. 47° tam turun böleni olmadığı
  /// için uzun süre tekrar etmiyor.
  static const double _hueStep = 47;

  /// Arka plan ve vurgu rengi seviyeden bağımsız.
  static const Color background = Color(0xFF141130);
  static const Color accent = Color(0xFFFFC145);

  static const Color _baseBoard = Color(0xFF241F4D);

  final int level;

  /// Seviyeye göre değişen tek şey.
  final Color boardColor;

  factory LevelTheme.forLevel(int level) {
    final step = (level - 1).clamp(0, 1 << 20);
    return LevelTheme(
      level: level,
      boardColor: _rotate(_baseBoard, step * _hueStep),
    );
  }

  static Color _rotate(Color color, double degrees) {
    if (degrees == 0) {
      return color;
    }
    final hsl = HSLColor.fromColor(color);
    return hsl.withHue((hsl.hue + degrees) % 360).toColor();
  }
}
