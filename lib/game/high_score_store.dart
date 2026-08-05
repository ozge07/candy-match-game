import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_log.dart';

/// En yüksek skoru cihazda saklar.
///
/// Depolama erişilemezse (test ortamı, kısıtlı cihaz) oyun çökmüyor; rekor
/// yalnızca o oturum boyunca hafızada tutuluyor.
class HighScoreStore {
  static const String _key = 'candy_match.high_score';

  /// Depolama yanıt vermezse açılış ekranında beklemeyelim.
  static const Duration _timeout = Duration(seconds: 5);

  /// Menü ve HUD bunu dinliyor.
  final ValueNotifier<int> best = ValueNotifier<int>(0);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(_timeout);
      best.value = prefs.getInt(_key) ?? 0;
    } catch (error) {
      AppLog.warn('score', 'rekor okunamadı, sıfırdan başlanıyor', error);
    }
  }

  /// [score] mevcut rekoru geçtiyse kaydeder ve `true` döner.
  ///
  /// Rekor hafızada hemen güncelleniyor; diske yazma başarısız olsa bile
  /// oyun içindeki gösterim doğru kalıyor.
  Future<bool> submit(int score) async {
    if (score <= best.value) {
      return false;
    }
    best.value = score;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(_timeout);
      await prefs.setInt(_key, score).timeout(_timeout);
    } catch (error) {
      AppLog.warn('score', 'rekor kaydedilemedi', error);
    }
    return true;
  }

  void dispose() => best.dispose();
}
