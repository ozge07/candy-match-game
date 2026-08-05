import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_log.dart';

/// Oyuna ilk girişte gösterilen ipucunun daha önce görülüp görülmediğini
/// saklar.
///
/// İpucu yalnızca bir kez kendiliğinden açılıyor; sonrasında oyuncu bilgi
/// düğmesine basarak istediği zaman tekrar görebiliyor.
class TipStore {
  static const String _key = 'candy_match.seen_level_tip';
  static const Duration _timeout = Duration(seconds: 5);

  /// İpucu daha önce gösterildi mi?
  final ValueNotifier<bool> seen = ValueNotifier<bool>(false);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(_timeout);
      seen.value = prefs.getBool(_key) ?? false;
    } catch (error) {
      // Okunamazsa ipucu bir kez daha gösterilir; zararsız.
      AppLog.warn('tips', 'durum okunamadı', error);
    }
  }

  Future<void> markSeen() async {
    if (seen.value) {
      return;
    }
    seen.value = true;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(_timeout);
      await prefs.setBool(_key, true).timeout(_timeout);
    } catch (error) {
      AppLog.warn('tips', 'durum kaydedilemedi', error);
    }
  }

  void dispose() => seen.dispose();
}
