import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_log.dart';

/// Uygulamayı hata yakalayıcıların içinde başlatır.
///
/// Üç ayrı kanaldan hata gelebiliyor ve üçü de yakalanmazsa uygulama sessizce
/// kapanır — mağazada en kötü izlenim bu:
///
/// 1. `FlutterError.onError` — widget ağacındaki (build, layout, paint) hatalar
/// 2. `PlatformDispatcher.instance.onError` — Flutter dışı asenkron hatalar
/// 3. `runZonedGuarded` — zamanlayıcı ve future zincirlerinden kaçanlar
///
/// Yayın derlemesinde hata ekrana kırmızı kutu yerine oyunun kendi koyu
/// zeminiyle yazılıyor; oyuncu en azından çirkin bir çökme görmüyor.
Future<void> bootstrap(
  FutureOr<Widget> Function() builder, {
  required Color background,
}) async {
  FlutterError.onError = (details) {
    AppLog.error(
      'flutter',
      details.exception,
      details.stack,
      details.library == null ? null : 'kaynak: ${details.library}',
    );
    // Geliştirirken varsayılan davranışı da koru: konsolda tam rapor çıksın.
    if (!kReleaseMode) {
      FlutterError.presentError(details);
    }
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.error('platform', error, stack);
    // true: hata işlendi, uygulama kapanmasın.
    return true;
  };

  ErrorWidget.builder = (details) => _ErrorScreen(background: background);

  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(await builder());
  }, (error, stack) => AppLog.error('zone', error, stack));
}

/// Bir widget çizilemediğinde onun yerine geçen ekran.
///
/// Flutter'ın varsayılanı sarı-siyah çizgili kırmızı kutu; yayında bunu
/// göstermek istemiyoruz.
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.background});

  final Color background;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background,
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Bir şeyler ters gitti.\nOyunu kapatıp yeniden açar mısın?',
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
          ),
        ),
      ),
    );
  }
}
