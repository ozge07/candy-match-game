import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

final Random _random = Random();

/// Bir şeker patladığında savrulan renkli kırıntılar.
ParticleSystemComponent candyBurst({
  required Vector2 position,
  required Color color,
  required double cellSize,
  int count = 12,
  double speed = 220,
  double lifespan = 0.55,
}) {
  return ParticleSystemComponent(
    position: position,
    priority: 5,
    particle: Particle.generate(
      count: count,
      lifespan: lifespan,
      generator: (_) {
        final angle = _random.nextDouble() * 2 * pi;
        final magnitude = speed * (0.45 + _random.nextDouble() * 0.75);
        final radius = cellSize * (0.06 + _random.nextDouble() * 0.09);
        // Boya parçacık başına bir kez; renderer her karede çağrıldığı için
        // burada üretmek saniyede binlerce gereksiz nesne demekti.
        final paint = Paint();
        return AcceleratedParticle(
          speed: Vector2(cos(angle), sin(angle)) * magnitude,
          acceleration: Vector2(0, 900),
          lifespan: lifespan,
          child: ComputedParticle(
            lifespan: lifespan,
            renderer: (canvas, particle) {
              final t = particle.progress;
              canvas.drawCircle(
                Offset.zero,
                radius * (1 - t * 0.7),
                paint..color = color.withValues(alpha: 1 - t),
              );
            },
          ),
        );
      },
    ),
  );
}

/// Bomba patlamasının kıvılcımları: daha hızlı, daha uzun ömürlü, sıcak renkli.
///
/// [palette] verilmezse sıcak patlama renkleri kullanılır; renk bombası için
/// şekerlerin kendi paleti gönderiliyor.
ParticleSystemComponent bombBurst({
  required Vector2 position,
  required double cellSize,
  List<Color> palette = const [
    Color(0xFFFFF3B0),
    Color(0xFFFFC145),
    Color(0xFFFF6B35),
    Color(0xFFFFFFFF),
  ],
}) {
  return ParticleSystemComponent(
    position: position,
    priority: 6,
    particle: Particle.generate(
      count: 34,
      lifespan: 0.75,
      generator: (i) {
        final angle = _random.nextDouble() * 2 * pi;
        final magnitude = 260 + _random.nextDouble() * 420;
        final radius = cellSize * (0.05 + _random.nextDouble() * 0.13);
        final color = palette[i % palette.length];
        final paint = Paint()
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
        return AcceleratedParticle(
          speed: Vector2(cos(angle), sin(angle)) * magnitude,
          acceleration: Vector2(0, 620),
          lifespan: 0.75,
          child: ComputedParticle(
            lifespan: 0.75,
            renderer: (canvas, particle) {
              final t = particle.progress;
              canvas.drawCircle(
                Offset.zero,
                radius * (1 - t * 0.55),
                paint..color = color.withValues(alpha: (1 - t) * 0.95),
              );
            },
          ),
        );
      },
    ),
  );
}

/// Dışa doğru genişleyip sönen çember — patlamanın vurgusu.
class Shockwave extends PositionComponent {
  Shockwave({
    required super.position,
    required this.maxRadius,
    required this.color,
    this.duration = 0.45,
    this.thickness = 7,
  }) : super(anchor: Anchor.center, priority: 4);

  final double maxRadius;
  final Color color;
  final double duration;
  final double thickness;

  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  /// Rengi ve kalınlığı her karede değiştiği için nesne yeniden üretilmiyor.
  final Paint _paint = Paint()..style = PaintingStyle.stroke;

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / duration).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(t);
    canvas.drawCircle(
      Offset.zero,
      maxRadius * eased,
      _paint
        ..strokeWidth = thickness * (1 - t)
        ..color = color.withValues(alpha: (1 - t) * 0.85),
    );
  }
}

/// Rekor kırıldığında ekranın üstünden dökülen konfeti.
///
/// Kâğıt parçaları dönerken genişlik-yükseklik oranı değiştiği için kendi
/// etraflarında dönüyormuş gibi görünüyorlar.
ParticleSystemComponent confetti({
  required Vector2 position,
  required double width,
  required List<Color> palette,
  int count = 90,
  double lifespan = 2.4,
}) {
  return ParticleSystemComponent(
    position: position,
    priority: 25,
    particle: Particle.generate(
      count: count,
      lifespan: lifespan,
      generator: (i) {
        final offsetX = (_random.nextDouble() - 0.5) * width;
        final size = 7 + _random.nextDouble() * 9;
        final color = palette[i % palette.length];
        final spin = 3 + _random.nextDouble() * 7;
        final phase = _random.nextDouble() * pi;
        final drift = (_random.nextDouble() - 0.5) * 90;
        final paint = Paint();

        return AcceleratedParticle(
          position: Vector2(offsetX, -_random.nextDouble() * 160),
          speed: Vector2(drift, 40 + _random.nextDouble() * 130),
          acceleration: Vector2(0, 220),
          lifespan: lifespan,
          child: ComputedParticle(
            lifespan: lifespan,
            renderer: (canvas, particle) {
              final t = particle.progress;
              // Son çeyrekte sön.
              final alpha = t < 0.75 ? 1.0 : 1 - (t - 0.75) / 0.25;
              final squash = cos(phase + t * lifespan * spin).abs();
              canvas.drawRect(
                Rect.fromCenter(
                  center: Offset.zero,
                  width: size * (0.25 + squash * 0.75),
                  height: size * 1.5,
                ),
                paint..color = color.withValues(alpha: alpha.clamp(0.0, 1.0)),
              );
            },
          ),
        );
      },
    ),
  );
}

/// Bir satırı ya da sütunu boydan boya süpüren parlak ışın.
///
/// İki bomba yan yana geldiğinde patlayan satır/sütunları gösteriyor.
class Beam extends PositionComponent {
  Beam({
    required super.position,
    required super.size,
    required this.color,
    this.duration = 0.5,
  }) : super(anchor: Anchor.center, priority: 16);

  final Color color;
  final double duration;

  double _elapsed = 0;

  /// Halesi ve çekirdeği her karede yalnızca renk değiştiriyor; boyalar bir
  /// kez kuruluyor.
  final Paint _glowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
  final Paint _corePaint = Paint();

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / duration).clamp(0.0, 1.0);
    // Hızlı parla, yavaş sön.
    final alpha = t < 0.12 ? t / 0.12 : 1 - (t - 0.12) / 0.88;
    final rect = size.toRect();
    final radius = Radius.circular(min(rect.width, rect.height) / 2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      _glowPaint..color = color.withValues(alpha: alpha * 0.5),
    );

    // İnce beyaz çekirdek.
    final core = rect.deflate(min(rect.width, rect.height) * 0.3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        core,
        Radius.circular(min(core.width, core.height) / 2),
      ),
      _corePaint..color = Colors.white.withValues(alpha: alpha),
    );
  }
}

/// Renk bombasından hedef şekere uzanan, titreşen şimşek.
///
/// Yol her ~45 ms'de yeniden üretiliyor; bu titreme onu durağan bir çizgi
/// yerine gerçekten çakan bir elektrik gibi gösteriyor.
class LightningBolt extends PositionComponent {
  LightningBolt({
    required this.from,
    required this.to,
    required this.color,
    this.duration = 0.42,
    this.segments = 9,
  }) : super(priority: 15);

  final Vector2 from;
  final Vector2 to;
  final Color color;
  final double duration;
  final int segments;

  double _elapsed = 0;

  /// Şimşeğin hale ve çekirdek boyaları; karede yalnızca renk değişiyor.
  final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
  final Paint _corePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round;
  double _sinceFlicker = 0;
  late List<Offset> _points = _buildPath();

  List<Offset> _buildPath() {
    final direction = to - from;
    final distance = direction.length;
    if (distance < 0.001) {
      return [Offset(from.x, from.y), Offset(to.x, to.y)];
    }
    final normal = Vector2(-direction.y, direction.x)..normalize();

    return [
      for (var i = 0; i <= segments; i++)
        () {
          final t = i / segments;
          // Uçlar sabit, sapma ortada en yüksek.
          final wobble =
              sin(t * pi) * distance * 0.1 * (_random.nextDouble() * 2 - 1);
          final point = from + direction * t + normal * wobble;
          return Offset(point.x, point.y);
        }(),
    ];
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    _sinceFlicker += dt;
    if (_sinceFlicker >= 0.045) {
      _sinceFlicker = 0;
      _points = _buildPath();
    }
    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / duration).clamp(0.0, 1.0);
    final alpha = 1 - t * t;
    final path = Path()..addPolygon(_points, false);

    // Renkli hale + beyaz çekirdek: klasik şimşek görünümü.
    canvas.drawPath(
      path,
      _glowPaint..color = color.withValues(alpha: alpha * 0.55),
    );
    canvas.drawPath(
      path,
      _corePaint..color = Colors.white.withValues(alpha: alpha),
    );
  }
}

/// [delay] saniye sonra [builder]'ın ürettiği bileşeni ebeveynine ekler.
///
/// Mega patlamada kırıntıların merkezden dışa doğru dalga hâlinde savrulmasını
/// sağlıyor.
class Delayed extends Component {
  Delayed(this.delay, this.builder);

  final double delay;
  final Component Function() builder;

  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= delay) {
      parent?.add(builder());
      removeFromParent();
    }
  }
}

/// Tüm ekranı bir an için beyazlatıp sönen katman. Mega patlamanın vurgusu.
class ScreenFlash extends PositionComponent {
  ScreenFlash({
    required Vector2 size,
    this.color = Colors.white,
    this.duration = 0.4,
    this.peak = 0.8,
  }) : super(size: size, priority: 30);

  final Color color;
  final double duration;

  /// En parlak andaki saydamlık.
  final double peak;

  double _elapsed = 0;

  /// Yalnızca saydamlığı değişiyor.
  final Paint _paint = Paint();

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / duration).clamp(0.0, 1.0);
    // Hızlı parla, yavaş sön.
    final alpha = t < 0.15
        ? peak * (t / 0.15)
        : peak * (1 - (t - 0.15) / 0.85);
    canvas.drawRect(
      size.toRect(),
      _paint..color = color.withValues(alpha: alpha.clamp(0.0, 1.0)),
    );
  }
}

/// Yükselerek sönen yazı. Hem "+120" puan baloncukları hem de "SÜPER!" gibi
/// tebrik mesajları için kullanılıyor.
///
/// Metni her karede yeniden ölçmemek için [TextPainter] bir kez kuruluyor;
/// saydamlık `saveLayer` ile, büyüme `scale` ile veriliyor.
class FloatingText extends PositionComponent {
  FloatingText({
    required this.text,
    required this.style,
    required super.position,
    this.duration = 0.85,
    this.rise = 64,
    this.popIn = false,
  }) : super(anchor: Anchor.center, priority: 20);

  final String text;
  final TextStyle style;
  final double duration;
  final double rise;

  /// Açılışta elastik bir "zıplama" — tebrik mesajlarında kullanılıyor.
  final bool popIn;

  late final TextPainter _painter;
  double _elapsed = 0;

  @override
  Future<void> onLoad() async {
    _painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  /// Sönme katmanının boyası; saydamlığı her karede değiştiği için nesneyi
  /// yeniden üretmek yerine üzerine yazıyoruz.
  final Paint _layerPaint = Paint();

  /// Katman sınırları metnin ölçüsüne bağlı, bir kez hesaplanıyor.
  late final Rect _layerBounds = Rect.fromCenter(
    center: Offset.zero,
    width: _painter.width * 2 + 40,
    height: _painter.height * 2 + 40,
  );

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / duration).clamp(0.0, 1.0);

    // Son %30'da sön.
    final alpha = t < 0.7 ? 1.0 : 1.0 - (t - 0.7) / 0.3;
    final scale = popIn
        ? 0.55 + Curves.elasticOut.transform(min(1.0, t * 3.2)) * 0.45
        : 1.0;
    final dy = -rise * Curves.easeOutCubic.transform(t);

    canvas.save();
    canvas.translate(0, dy);
    canvas.scale(scale);

    // `saveLayer` ekran dışı bir tampon ayırıyor — pahalı. Yazı ömrünün ilk
    // %70'inde tamamen opak olduğu için o karelerde katmana gerek yok.
    final fading = alpha < 1;
    if (fading) {
      canvas.saveLayer(
        _layerBounds,
        _layerPaint..color = Colors.white.withValues(
          alpha: alpha.clamp(0.0, 1.0),
        ),
      );
    }
    _painter.paint(
      canvas,
      Offset(-_painter.width / 2, -_painter.height / 2),
    );
    if (fading) {
      canvas.restore();
    }
    canvas.restore();
  }
}
