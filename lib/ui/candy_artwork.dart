import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../app_log.dart';

import '../game/candy.dart';

/// Açılış ve menü ekranlarının arka planındaki illüstrasyon.
///
/// Bitmap yerine vektör çiziyoruz: her ekran yoğunluğunda net kalıyor, apk'ya
/// tek byte eklemiyor ve oyunun içindeki şekerlerle birebir aynı dili
/// konuşuyor.
class CandyArtwork extends StatelessWidget {
  const CandyArtwork({this.animation, super.key});

  /// Verilirse şekerler hafifçe süzülür.
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) {
    final painter = _ArtworkPainter(animation?.value ?? 0);
    return animation == null
        ? CustomPaint(painter: painter, size: Size.infinite)
        : AnimatedBuilder(
            animation: animation!,
            builder: (context, _) => CustomPaint(
              painter: _ArtworkPainter(animation!.value),
              size: Size.infinite,
            ),
          );
  }
}

class _ArtworkPainter extends CustomPainter {
  _ArtworkPainter(this.t);

  /// 0..1 arası serbest akan animasyon fazı.
  final double t;

  /// Şekerlerin yerleşimi: (x, y, boyut, tür, dönüş) — oranlar 0..1.
  ///
  /// Sabit bir liste; her açılışta aynı kompozisyon çıksın diye rastgelelik
  /// yok. Kompozisyon bir çerçeve gibi: ortadaki `y` 0.26–0.52 bandı başlığa
  /// bırakıldığı için oraya sadece kenarlardan taşan şekerler giriyor.
  static const List<(double, double, double, int, double)> _candies = [
    // üst sıra
    (0.11, 0.12, 0.13, 0, 0.18),
    (0.31, 0.06, 0.09, 3, 0.40),
    (0.51, 0.13, 0.12, 1, -0.10),
    (0.71, 0.06, 0.10, 5, -0.32),
    (0.89, 0.14, 0.12, 2, 0.24),
    // yanlar
    (0.06, 0.29, 0.11, 4, -0.20),
    (0.94, 0.30, 0.12, 3, 0.28),
    (0.05, 0.47, 0.10, 1, 0.34),
    (0.95, 0.46, 0.11, 0, -0.26),
    // alt sıra
    (0.12, 0.63, 0.13, 5, -0.16),
    (0.31, 0.69, 0.15, 2, 0.20),
    (0.51, 0.62, 0.12, 4, -0.30),
    (0.70, 0.69, 0.14, 0, 0.14),
    (0.89, 0.63, 0.13, 3, -0.22),
  ];

  static const List<(double, double, double)> _sparkles = [
    (0.20, 0.24, 1.0),
    (0.80, 0.23, 0.8),
    (0.24, 0.53, 0.9),
    (0.76, 0.55, 1.1),
    (0.42, 0.21, 0.7),
    (0.60, 0.55, 0.85),
    (0.15, 0.40, 0.75),
    (0.86, 0.39, 0.95),
    (0.50, 0.78, 0.8),
  ];

  /// Zemin + parıltı + şekerler karede değişmiyor; yalnızca hafif bir süzülme
  /// ve ışıltılar hareketli. Bu sabit katman on sekiz şekil, iki büyük blur ve
  /// bir radyal gradyan demek — her karede yeniden çizilince menü ana iş
  /// parçacığını tıkıyor ve düşük donanımda uygulama yanıt vermez hâle
  /// geliyordu. Bir kez rasterleştirip saklıyoruz.
  static ui.Image? _katman;
  static Size? _katmanBoyutu;
  static double _katmanOlcegi = 0;

  static final Paint _katmanBoyasi = Paint()
    ..filterQuality = FilterQuality.medium;

  /// Sabit katmanı üretir; ölçü ya da piksel oranı değişirse yeniliyor.
  static ui.Image? _sabitKatman(Size size, double olcek) {
    final onceki = _katman;
    if (onceki != null && _katmanBoyutu == size && _katmanOlcegi == olcek) {
      return onceki;
    }
    final genislik = (size.width * olcek).ceil();
    final yukseklik = (size.height * olcek).ceil();
    if (genislik <= 0 || yukseklik <= 0) {
      return null;
    }
    try {
      final kaydedici = ui.PictureRecorder();
      final tuval = Canvas(kaydedici);
      tuval.scale(olcek);
      _cizSabit(tuval, size);
      final resim = kaydedici.endRecording().toImageSync(genislik, yukseklik);
      onceki?.dispose();
      _katman = resim;
      _katmanBoyutu = size;
      _katmanOlcegi = olcek;
      return resim;
    } catch (error) {
      AppLog.warn('artwork', 'sabit katman rasterleştirilemedi', error);
      return null;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Katmanı cihaz çözünürlüğünde üretmek pahalıya patlıyor: iki büyük blur
    // 17 milyon piksele uygulanınca ilk çizim saniyeler sürüyor ve açılış
    // kilitleniyor. Zaten yumuşak bir arka plan, düşük çözünürlükte üretip
    // büyütmek gözle ayırt edilmiyor.
    const enFazlaGenislik = 540.0;
    final olcek = size.width <= 0
        ? 1.0
        : (enFazlaGenislik / size.width).clamp(0.25, 1.0);
    final katman = _sabitKatman(size, olcek);

    if (katman != null) {
      // Bütün kompozisyon yavaşça nefes alsın diye tek bir kaydırma yetiyor.
      final kayma = sin(t * 2 * pi) * size.height * 0.008;
      canvas.save();
      canvas.translate(0, kayma);
      canvas.drawImageRect(
        katman,
        Rect.fromLTWH(0, 0, katman.width.toDouble(), katman.height.toDouble()),
        Offset.zero & size,
        _katmanBoyasi,
      );
      canvas.restore();
    } else {
      // Rasterleştirme başarısızsa eski yoldan çiziyoruz; görüntü aynı.
      _cizSabit(canvas, size);
    }

    for (final (x, y, scale) in _sparkles) {
      final twinkle = (sin(t * 2 * pi * 2 + x * 11 + y * 5) + 1) / 2;
      _drawSparkle(
        canvas,
        Offset(size.width * x, size.height * y),
        size.width * 0.022 * scale * (0.6 + twinkle * 0.6),
        Colors.white.withValues(alpha: 0.25 + twinkle * 0.5),
      );
    }
  }

  /// Karede değişmeyen katman: zemin, parıltı ve şekerler.
  static void _cizSabit(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -0.25),
          radius: 1.1,
          colors: [Color(0xFF3B2E7A), Color(0xFF1B1642), Color(0xFF0E0B24)],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );

    // Şekerlerin arkasındaki sıcak parıltı.
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.44),
      size.width * 0.42,
      Paint()
        ..color = const Color(0xFFFFC145).withValues(alpha: 0.13)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70),
    );

    for (final (x, y, s, type, tilt) in _candies) {
      final side = size.width * s;
      final centre = Offset(size.width * x, size.height * y);
      final colour = Candy.palette[type % Candy.palette.length];

      canvas.save();
      canvas.translate(centre.dx, centre.dy);
      canvas.rotate(tilt);

      final shape = Candy.shapeOf(
        Rect.fromCenter(center: Offset.zero, width: side, height: side),
        type,
      );

      canvas.drawPath(
        shape,
        Paint()
          ..color = colour.withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, side * 0.22),
      );
      canvas.drawPath(shape, Paint()..color = colour);

      canvas.save();
      canvas.clipPath(shape);
      canvas.drawCircle(
        Offset(-side * 0.16, -side * 0.2),
        side * 0.2,
        Paint()..color = Colors.white.withValues(alpha: 0.4),
      );
      canvas.restore();

      canvas.drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = side * 0.05
          ..color = Colors.black.withValues(alpha: 0.25),
      );
      canvas.restore();
    }

  }

  /// Dört uçlu parıltı: iki dikey damla şeklinde.
  static void _drawSparkle(Canvas canvas, Offset centre, double radius, Color color) {
    final path = Path()
      ..moveTo(centre.dx, centre.dy - radius)
      ..quadraticBezierTo(
        centre.dx + radius * 0.16,
        centre.dy - radius * 0.16,
        centre.dx + radius,
        centre.dy,
      )
      ..quadraticBezierTo(
        centre.dx + radius * 0.16,
        centre.dy + radius * 0.16,
        centre.dx,
        centre.dy + radius,
      )
      ..quadraticBezierTo(
        centre.dx - radius * 0.16,
        centre.dy + radius * 0.16,
        centre.dx - radius,
        centre.dy,
      )
      ..quadraticBezierTo(
        centre.dx - radius * 0.16,
        centre.dy - radius * 0.16,
        centre.dx,
        centre.dy - radius,
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArtworkPainter oldDelegate) => oldDelegate.t != t;
}
