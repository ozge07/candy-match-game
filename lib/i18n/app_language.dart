import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_log.dart';

/// Oyunun desteklediği diller.
enum AppLanguage {
  tr('TR', 'Türkçe'),
  en('EN', 'English');

  const AppLanguage(this.code, this.label);

  /// Düğmede görünen kısa kod.
  final String code;

  /// Dilin kendi adı — dil seçerken oyuncu kendi dilini tanısın diye
  /// çevrilmiyor.
  final String label;

  /// Sıradaki dil; düğme tek dokunuşla diller arasında geçiyor.
  AppLanguage get next =>
      this == AppLanguage.tr ? AppLanguage.en : AppLanguage.tr;
}

/// Seçilen dili cihazda saklar.
///
/// İlk açılışta seçim yoksa cihazın diline bakıyoruz: telefon Türkçeyse oyun
/// Türkçe açılıyor, değilse İngilizce. Oyuncu sonradan değiştirirse tercihi
/// kalıcı oluyor.
class LanguageStore {
  static const String _key = 'app_language';

  /// Depolama yanıt vermezse oyunu bekletmeyelim.
  static const Duration _timeout = Duration(seconds: 5);

  final ValueNotifier<AppLanguage> language = ValueNotifier<AppLanguage>(
    deviceLanguage(),
  );

  /// Testlerin dili sabitlemesi için; yalnızca test ortamında kullanılıyor.
  @visibleForTesting
  static AppLanguage? debugOverride;

  /// Cihazın dili; kayıtlı tercih yoksa bundan başlıyoruz.
  static AppLanguage deviceLanguage() {
    final zorlanan = debugOverride;
    if (zorlanan != null) {
      return zorlanan;
    }
    final kod = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return kod == 'tr' ? AppLanguage.tr : AppLanguage.en;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(_timeout);
      final kayitli = prefs.getString(_key);
      if (kayitli == null) {
        return;
      }
      language.value = AppLanguage.values.firstWhere(
        (dil) => dil.name == kayitli,
        orElse: deviceLanguage,
      );
    } catch (error) {
      AppLog.warn('lang', 'dil tercihi okunamadı', error);
    }
  }

  Future<void> set(AppLanguage dil) async {
    if (language.value == dil) {
      return;
    }
    language.value = dil;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(_timeout);
      await prefs.setString(_key, dil.name).timeout(_timeout);
    } catch (error) {
      AppLog.warn('lang', 'dil tercihi kaydedilemedi', error);
    }
  }

  /// Düğme için: diller arasında geçiş.
  Future<void> toggle() => set(language.value.next);

  void dispose() => language.dispose();
}
