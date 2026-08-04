import 'dart:math';

import 'package:flutter/material.dart';

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

  @override
  void paint(Canvas canvas, Size size) {
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
      // Her şeker kendi hızında, birbirinden bağımsız süzülüyor.
      final drift = sin(t * 2 * pi + x * 7 + y * 3) * size.height * 0.012;
      final side = size.width * s;
      final centre = Offset(size.width * x, size.height * y + drift);
      final colour = Candy.palette[type % Candy.palette.length];

      canvas.save();
      canvas.translate(centre.dx, centre.dy);
      canvas.rotate(tilt + sin(t * 2 * pi + x * 5) * 0.04);

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

    for (final (x, y, scale) in _sparkles) {
      final twinkle = (sin(t * 2 * pi * 2 + x * 11 + y * 5) + 1) / 2;
      _drawSparkle(
        canvas,
        Offset(size.width * x, size.height * y),
        size.width * 0.022 * scale * (0.6 + twinkle * 0.6),
        Colors.white.withValues(alpha: 0.35 + twinkle * 0.5),
      );
    }
  }

  /// Dört uçlu parıltı: iki dikey damla şeklinde.
  void _drawSparkle(Canvas canvas, Offset centre, double radius, Color color) {
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
