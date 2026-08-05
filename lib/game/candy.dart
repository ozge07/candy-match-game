import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../app_log.dart';

/// Bir şekerin türü.
///
/// - [bomb]: 2x2 kare veya 4'lü kümeden doğar, patlayınca 3x3 alanı siler.
/// - [rainbow]: 5'li sıradan doğar, patlayınca tahtadaki kendi renginin
///   **tamamını** siler.
enum CandyKind { normal, bomb, rainbow }

/// Tahtadaki tek bir şeker.
///
/// Hacim hissi için üç katman kullanıyoruz: altta yumuşak bir gölge, gövdede
/// sol üstten aydınlatılmış radyal gradyan, altta ters ışık (rim light) ve
/// üstte keskin bir parlama. Renk körlüğü olan oyuncular ayırt edebilsin diye
/// her tür ayrıca farklı bir şekille çiziliyor. Şekiller ve renkler seviyeden
/// bağımsız — oyuncu her seviyede aynı elemanlarla oynuyor.
class Candy extends PositionComponent {
  Candy({
    required this.type,
    required this.row,
    required this.col,
    required super.position,
    required double cellSize,
    this.kind = CandyKind.normal,
  }) : _cellSize = cellSize,
       super(size: Vector2.all(cellSize * 0.84), anchor: Anchor.center);

  /// Tanımlı en fazla şeker türü. Oyun seviyeye göre bunun bir kısmını
  /// kullanıyor (bkz. `CandyGame.activeTypes`) — tür sayısı arttıkça
  /// eşleşme bulmak zorlaşıyor.
  static const int typeCount = 8;

  /// [shapeOf] içinde tanımlı şekil sayısı. Oyunda ilk [typeCount] tanesi
  /// kullanılıyor; kalanlar illüstrasyon gibi yerler için duruyor.
  static const int shapeCount = 10;

  /// Şeker renkleri. Seviyeden bağımsız; menü illüstrasyonu ve konfeti de
  /// aynı paleti kullanıyor.
  static const List<Color> palette = [
    Color(0xFFE84C3D),
    Color(0xFF3498DB),
    Color(0xFF2ECC71),
    Color(0xFFF1C40F),
    Color(0xFF9B59B6),
    Color(0xFFFF8A3D),
    Color(0xFF1ABC9C),
    Color(0xFFEC407A),
  ];

  final double _cellSize;

  int type;
  int row;
  int col;
  CandyKind kind;

  /// Tıklanarak seçildiğinde beyaz çerçeve çiziyoruz.
  bool selected = false;

  /// Patlamadan hemen önce bombayı beyaza boyuyoruz; oyuncu neyin patladığını
  /// görsün diye kısa bir "fitil yandı" anı.
  bool flashing = false;

  /// Renk bombası çaktığında hedef şekerler elektrikleniyor.
  bool charged = false;

  /// Oyuncu bir süre hamle yapmadığında önerilen hamlenin iki şekeri
  /// nefes alır gibi parlıyor.
  bool hinting = false;

  /// Bombanın nabız animasyonu için serbest akan faz.
  double _pulse = 0;

  Color get color => palette[type % palette.length];

  /// Türün şekli. Seviyeden bağımsız: oyuncu hep aynı elemanlarla oynuyor.
  int get shape => type % shapeCount;

  bool get isBomb => kind == CandyKind.bomb;

  bool get isRainbow => kind == CandyKind.rainbow;

  bool get isSpecial => kind != CandyKind.normal;

  /// Sıradan şekeri bombaya dönüştürür ve biraz büyütür.
  void promoteToBomb() {
    kind = CandyKind.bomb;
    size.setAll(_cellSize * 0.94);
  }

  /// Sıradan şekeri renk bombasına dönüştürür.
  void promoteToRainbow() {
    kind = CandyKind.rainbow;
    size.setAll(_cellSize * 0.96);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isSpecial || charged || hinting) {
      _pulse += dt * 4.5;
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, width, height);

    // İpucu verilirken şeker bütünüyle hafifçe büyüyüp küçülüyor.
    if (hinting) {
      canvas.save();
      final grow = 1 + 0.07 * _breath;
      canvas.translate(width / 2, height / 2);
      canvas.scale(grow);
      canvas.translate(-width / 2, -height / 2);
    }

    switch (kind) {
      case CandyKind.normal:
        _renderNormal(canvas, rect);
      case CandyKind.bomb:
        _renderBomb(canvas, rect);
      case CandyKind.rainbow:
        _renderRainbow(canvas, rect);
    }

    if (charged) {
      _renderCharge(canvas, rect);
    }

    if (hinting) {
      _renderHint(canvas, rect);
      canvas.restore();
    }

    if (selected) {
      canvas.drawPath(
        isSpecial ? (Path()..addOval(rect)) : shapeOf(rect, shape),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 0.1
          ..color = Colors.white,
      );
    }
  }

  /// 0..1 arası yavaş nefes; ipucu parlaması buna göre gidip geliyor.
  double get _breath => (sin(_pulse * 0.42) + 1) / 2;

  /// İpucu halkası: kenarda nefes alan sıcak bir parlama.
  void _renderHint(Canvas canvas, Rect rect) {
    final path = isSpecial ? (Path()..addOval(rect)) : shapeOf(rect, shape);
    final beat = _breath;

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * (0.13 + beat * 0.12)
        ..color = const Color(0xFFFFF3B0).withValues(alpha: 0.3 + beat * 0.5)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          width * (0.05 + beat * 0.05),
        ),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.045
        ..color = Colors.white.withValues(alpha: 0.45 + beat * 0.5),
    );
  }

  void _renderNormal(Canvas canvas, Rect rect) {
    // Sıradan şekerin görünüşü karede hiç değişmiyor: şekil, renk ve boyut
    // sabit, hareketi bileşenin dönüşümü veriyor. Buna rağmen her kare üç ayrı
    // blur, bir radyal gradyan ve iki kırpma çiziliyordu — 64 hücrelik tahtada
    // saniyede ~12.000 pahalı çizim. Bir kez rasterleştirip saklıyoruz;
    // tahtadaki bütün aynı türden şekerler aynı görüntüyü paylaşıyor.
    final image = _bodyImage(canvas);
    if (image == null) {
      // Rasterleştirme başarısızsa (ör. test ortamı) doğrudan çiziyoruz;
      // görüntü aynı, yalnızca daha pahalı.
      _renderVolume(canvas, rect, shapeOf(rect, shape), color);
      return;
    }
    final pad = width * _bodyPadRatio;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(-pad, -pad, width + pad * 2, height + pad * 2),
      _imagePaint,
    );
  }

  /// Gövde görüntüsünün şeklin dışına taşan payı: aşağı kaydırılmış gölge ve
  /// blur kenarları kesilmesin diye.
  static const double _bodyPadRatio = 0.35;

  static final Paint _imagePaint = Paint()..filterQuality = FilterQuality.medium;

  /// (şekil, renk, çözünürlük) başına bir görüntü. Tahtada 8 tür ve tek bir
  /// hücre boyutu var, yani sözlük birkaç girdiden ibaret kalıyor.
  static final Map<String, ui.Image?> _bodyCache = {};

  /// Ekrandaki gerçek ölçek: kamera yakınlaştırması ve cihazın piksel oranı
  /// birlikte. Rasteri buna göre üretmezsek büyük ekranda bulanık görünür.
  double _canvasScale(Canvas canvas) {
    final m = canvas.getTransform();
    // Ölçek eşit olduğu için ilk sütunun uzunluğu yeterli.
    final scale = sqrt(m[0] * m[0] + m[1] * m[1]);
    return scale.isFinite && scale > 0 ? scale.clamp(0.5, 4.0) : 1.0;
  }

  ui.Image? _bodyImage(Canvas canvas) {
    // Ölçeği kabaca gruplandırıyoruz; yoksa en ufak oynamada yeniden
    // rasterleştirme yapardık.
    final bucket = (_canvasScale(canvas) * 4).round();
    final key = '$shape-${color.toARGB32()}-${width.round()}-$bucket';
    if (_bodyCache.containsKey(key)) {
      return _bodyCache[key];
    }
    final image = _rasterizeBody(bucket / 4);
    _bodyCache[key] = image;
    return image;
  }

  ui.Image? _rasterizeBody(double scale) {
    final pad = width * _bodyPadRatio;
    final logicalWidth = width + pad * 2;
    final logicalHeight = height + pad * 2;
    final pixelWidth = (logicalWidth * scale).ceil();
    final pixelHeight = (logicalHeight * scale).ceil();
    if (pixelWidth <= 0 || pixelHeight <= 0) {
      return null;
    }

    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.scale(scale);
      canvas.translate(pad, pad);
      final rect = Rect.fromLTWH(0, 0, width, height);
      _renderVolume(canvas, rect, shapeOf(rect, shape), color);
      final picture = recorder.endRecording();
      final image = picture.toImageSync(pixelWidth, pixelHeight);
      picture.dispose();
      return image;
    } catch (error) {
      AppLog.warn('render', 'şeker gövdesi rasterleştirilemedi', error);
      return null;
    }
  }

  /// Bir şekli hacimli gösteren ortak çizim.
  void _renderVolume(Canvas canvas, Rect rect, Path path, Color base) {
    // 1) Alta düşen yumuşak gölge.
    canvas.save();
    canvas.translate(0, height * 0.075);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.42)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.07),
    );
    canvas.restore();

    // 2) Gövde: sol üstten gelen ışığa göre radyal gradyan.
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 1.05,
          colors: [
            Color.lerp(base, Colors.white, 0.55)!,
            base,
            Color.lerp(base, Colors.black, 0.42)!,
          ],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );

    // 3) Alt kenarda ters ışık: şekli zeminden ayırıyor.
    canvas.save();
    canvas.clipPath(path);
    canvas.translate(0, -height * 0.13);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.16
        ..color = Color.lerp(base, Colors.white, 0.4)!.withValues(alpha: 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.06),
    );
    canvas.restore();

    // 4) Üstte keskin parlama.
    canvas.save();
    canvas.clipPath(path);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width * 0.34, height * 0.24),
        width: width * 0.42,
        height: height * 0.3,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.05),
    );
    canvas.restore();

    // 5) İnce koyu kontur, şekli keskinleştiriyor.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.045
        ..color = Color.lerp(base, Colors.black, 0.55)!.withValues(alpha: 0.7),
    );
  }

  void _renderBomb(Canvas canvas, Rect rect) {
    final center = rect.center;
    final radius = width / 2;
    final beat = (sin(_pulse) + 1) / 2;

    canvas.drawCircle(
      center,
      radius * (0.95 + beat * 0.18),
      Paint()..color = color.withValues(alpha: 0.22 + beat * 0.18),
    );

    final body = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius * 0.82));
    _renderVolume(canvas, rect, body, const Color(0xFF2A2450));

    canvas.drawCircle(
      center,
      radius * 0.82,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.13
        ..color = color,
    );

    // Ortada şekerin kendi şekli: bombanın hangi türle eşleştiği renkten
    // bağımsız olarak da anlaşılsın diye.
    final inner = width * (0.44 + beat * 0.04);
    final innerRect = Rect.fromCenter(
      center: center,
      width: inner,
      height: inner,
    );
    canvas.drawPath(
      shapeOf(innerRect, shape),
      Paint()..color = Color.lerp(Colors.white, color, 0.3)!,
    );

    if (flashing) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }
  }

  /// Renk bombası: dönen renk dilimleri + ortada kendi şekli.
  void _renderRainbow(Canvas canvas, Rect rect) {
    final center = rect.center;
    final radius = width / 2;
    final beat = (sin(_pulse) + 1) / 2;

    canvas.drawCircle(
      center,
      radius * (0.96 + beat * 0.14),
      Paint()..color = Colors.white.withValues(alpha: 0.16 + beat * 0.14),
    );

    canvas.save();
    canvas.translate(0, height * 0.07);
    canvas.drawCircle(
      center,
      radius * 0.9,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.42)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.07),
    );
    canvas.restore();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_pulse * 0.3);
    final disc = Rect.fromCircle(center: Offset.zero, radius: radius * 0.9);
    for (var i = 0; i < palette.length; i++) {
      canvas.drawArc(
        disc,
        i * 2 * pi / palette.length,
        2 * pi / palette.length,
        true,
        Paint()..color = palette[i],
      );
    }
    canvas.restore();

    // Küresel hissi veren üst parlama ve alt gölge.
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius * 0.9)),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width * 0.34, height * 0.24),
        width: width * 0.44,
        height: height * 0.3,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.05),
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy + radius * 0.75),
      radius * 0.6,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.09),
    );
    canvas.restore();

    canvas.drawCircle(
      center,
      radius * 0.9,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.07
        ..color = Colors.white.withValues(alpha: 0.92),
    );

    final inner = width * 0.5;
    final innerPath = shapeOf(
      Rect.fromCenter(center: center, width: inner, height: inner),
      shape,
    );
    canvas.drawCircle(
      center,
      inner * 0.62,
      Paint()..color = const Color(0xFF1C1836),
    );
    canvas.drawPath(innerPath, Paint()..color = color);
    canvas.drawPath(
      innerPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.035
        ..color = Colors.white,
    );

    if (flashing) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }
  }

  /// Elektriklenme: mavi-beyaz hale + şeklin üzerinde parlak dolgu.
  void _renderCharge(Canvas canvas, Rect rect) {
    final path = isSpecial ? (Path()..addOval(rect)) : shapeOf(rect, shape);
    final flicker = 0.7 + 0.3 * sin(_pulse * 9);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.2
        ..color = const Color(0xFF9FE8FF).withValues(alpha: 0.85 * flicker)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawPath(
      path,
      Paint()..color = Colors.white.withValues(alpha: 0.55 * flicker),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.05
        ..color = Colors.white,
    );
  }

  /// Bir şekil indeksinin silueti. Açılış ekranındaki görsel de bunu kullanıyor.
  static Path shapeOf(Rect r, int shape) => switch (shape % shapeCount) {
    0 => Path()..addOval(r.deflate(r.width * 0.02)),
    1 => Path()..addRRect(
      RRect.fromRectAndRadius(
        r.deflate(r.width * 0.06),
        Radius.circular(r.width * 0.24),
      ),
    ),
    2 => _polygon(r.center, r.width / 2, 4, 0),
    3 => _polygon(r.center, r.width / 2, 3, -pi / 2),
    4 => _polygon(r.center, r.width / 2, 6, -pi / 2),
    5 => _star(r.center, r.width / 2, r.width * 0.22, 5),
    6 => _polygon(r.center, r.width / 2, 5, -pi / 2),
    7 => _star(r.center, r.width / 2, r.width * 0.26, 6),
    8 => _polygon(r.center, r.width / 2, 8, pi / 8),
    _ => _star(r.center, r.width / 2, r.width * 0.2, 4),
  };

  static Path _polygon(Offset center, double radius, int sides, double start) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final angle = start + i * 2 * pi / sides;
      final point = center + Offset(cos(angle) * radius, sin(angle) * radius);
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  static Path _star(
    Offset center,
    double outerRadius,
    double innerRadius,
    int points,
  ) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = -pi / 2 + i * pi / points;
      final point = center + Offset(cos(angle) * radius, sin(angle) * radius);
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }
}
