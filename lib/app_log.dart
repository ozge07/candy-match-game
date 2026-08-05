import 'package:flutter/foundation.dart';

/// Oyunun tek log noktası.
///
/// Dağınık `debugPrint` çağrıları yerine buradan geçiyoruz. İki faydası var:
/// çıktı tek biçimde etiketleniyor, ve yayın derlemesinde ne kadarının
/// yazılacağına tek yerden karar veriliyor.
///
/// Yayın derlemesinde hata ve uyarılar da yazılıyor (Play Console'daki
/// "ANR ve kilitlenmeler" altında logcat çıktısı görünür, sorun ayıklamayı
/// kolaylaştırır); ayrıntılı `info` kayıtları yalnızca geliştirmede.
class AppLog {
  const AppLog._();

  static void info(String tag, String message) {
    if (kReleaseMode) {
      return;
    }
    debugPrint('[$tag] $message');
  }

  /// Beklenen ama önemli olmayan aksaklık: oyun çalışmaya devam ediyor.
  ///
  /// Ses yüklenememesi, kaydın okunamaması, reklamın gelmemesi gibi. Bunlar
  /// oyuncuyu durdurmuyor, o yüzden yakalanıp burada bırakılıyorlar.
  static void warn(String tag, String message, [Object? error]) {
    debugPrint(error == null ? '[$tag] $message' : '[$tag] $message: $error');
  }

  /// Beklenmeyen hata. Yığın izi de yazılıyor.
  static void error(
    String tag,
    Object error, [
    StackTrace? stack,
    String? message,
  ]) {
    debugPrint('[$tag] ${message ?? 'beklenmeyen hata'}: $error');
    if (stack != null) {
      debugPrintStack(stackTrace: stack, maxFrames: 12);
    }
  }
}
