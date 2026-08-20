import 'dart:math';
import 'dart:typed_data';
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
/// ## Görünüş
///
/// Her tür gerçek bir şekerin silueti: jöle damlası, karamel, fasulye, dilim,
/// taş, yıldız, kalp ve nane çarkı. Köşeler yuvarlatılmış — çıplak çokgen
/// "geometri" gibi duruyordu, yuvarlatınca ısırılabilir bir şey gibi duruyor.
/// Siluetin üstüne türe özgü bir süs geliyor (şerit, faset, pervane, şeker
/// taneleri), böylece iki şeker aynı renkte olsa bile ayrı okunuyor.
///
/// Hacim üç katmandan geliyor: alta düşen gölge, sol üstten aydınlatılmış
/// gradyan ve üstte keskin parlama. Gradyanın uçları beyaz/siyah değil; ışık
/// sıcak kreme, gölge tahtanın moruna kayıyor — sahneye ait duruyorlar.
///
/// Renk körlüğü olan oyuncular ayırt edebilsin diye her türün silueti farklı.
/// Şekiller ve renkler seviyeden bağımsız — oyuncu her seviyede aynı
/// elemanlarla oynuyor.
///
/// ## Hareket
///
/// Tahta hiç durmuyor: şekerler [clock] üzerinden ortak bir dalgayla usulca
/// sallanıyor, arada bir ışık tahtayı çaprazlama süpürüyor, düşen şeker yere
/// çarpınca eziliyor. Hepsi çizim dönüşümü ([Canvas.scale], [Canvas.rotate])
/// olarak uygulanıyor; gövde rasteri değişmediği için hareket bedavaya geliyor.
class Candy extends PositionComponent {
  Candy({
    required this.type,
    required this.row,
    required this.col,
    required super.position,
    required double cellSize,
    this.kind = CandyKind.normal,
  }) : _cellSize = cellSize,
       super(size: Vector2.all(cellSize * 0.9), anchor: Anchor.center);

  /// Tahtanın ortak saati; salınım ve ışık süpürmesi buna bağlı.
  ///
  /// Şekerler farklı anlarda doğuyor (yeni şekerler yukarıdan düşüyor), o
  /// yüzden her şekerin kendi sayacı kullanılsa dalga darmadağın olurdu.
  /// [BoardComponent] her karede bir kez ilerletiyor.
  static double clock = 0;

  /// Tanımlı en fazla şeker türü. Oyun seviyeye göre bunun bir kısmını
  /// kullanıyor (bkz. `CandyGame.activeTypes`) — tür sayısı arttıkça
  /// eşleşme bulmak zorlaşıyor.
  static const int typeCount = 8;

  /// [shapeOf] içinde tanımlı şekil sayısı. Oyunda ilk [typeCount] tanesi
  /// kullanılıyor; kalanlar illüstrasyon gibi yerler için duruyor.
  static const int shapeCount = 10;

  /// Şeker renkleri. Seviyeden bağımsız; menü illüstrasyonu ve konfeti de
  /// aynı paleti kullanıyor. Sıra siluetle eşleşiyor: kalp pembe, nane çarkı
  /// turkuaz.
  static const List<Color> palette = [
    Color(0xFFE84C3D),
    Color(0xFF3498DB),
    Color(0xFF2ECC71),
    Color(0xFFF1C40F),
    Color(0xFF9B59B6),
    Color(0xFFFF8A3D),
    Color(0xFFEC407A),
    Color(0xFF1ABC9C),
  ];

  /// Gradyanın parlak ucu. Beyaz yerine sıcak krem: şeker cilası beyaz değil.
  static const Color _lightSource = Color(0xFFFFF6E6);

  /// Gradyanın karanlık ucu. Siyah yerine tahtanın moru: gölge sahneye ait
  /// oluyor, şekil zeminden kesilmiş gibi durmuyor.
  static const Color _shadowTone = Color(0xFF2A1B4A);

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

  /// Yere çarpma ezilmesi: 1'den 0'a iniyor, 0 ise şeker dinlenmede.
  double _squash = 0;

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

  /// Düşüş bitti: şeker yere çarpıp bir kez eziliyor.
  void land() => _squash = 1;

  /// Ezilmenin sönme süresi.
  static const double _squashDuration = 0.28;

  @override
  void update(double dt) {
    super.update(dt);
    if (isSpecial || charged || hinting) {
      _pulse += dt * 4.5;
    }
    if (_squash > 0) {
      _squash = max(0, _squash - dt / _squashDuration);
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, width, height);

    canvas.save();
    canvas.translate(width / 2, height / 2);

    // 1) Tahtayı boydan boya geçen sakin salınım.
    final sway = _sway;
    canvas.translate(0, height * 0.022 * sway);
    canvas.rotate(0.038 * sway);

    // 2) Yere çarpma: önce yayılıp basılıyor, sonra bir kez uzayıp oturuyor.
    if (_squash > 0) {
      final amount = _squashAmount;
      canvas.scale(1 + 0.22 * amount, 1 - 0.22 * amount);
    }

    // 3) İpucu verilirken şeker bütünüyle hafifçe büyüyüp küçülüyor.
    if (hinting) {
      canvas.scale(1 + 0.07 * _breath);
    }

    canvas.translate(-width / 2, -height / 2);

    switch (kind) {
      case CandyKind.normal:
        _renderNormal(canvas, rect);
      case CandyKind.bomb:
        _renderBomb(canvas, rect);
      case CandyKind.rainbow:
        _renderRainbow(canvas, rect);
    }

    // Işık süpürmesi gövdenin üstünde, süslerin de üstünde.
    final glint = _glint;
    if (glint != null) {
      _renderGlint(canvas, rect, glint);
    }

    if (charged) {
      _renderCharge(canvas, rect);
    }

    if (hinting) {
      _renderHint(canvas, rect);
    }

    if (selected) {
      _renderSelection(canvas, rect);
    }

    canvas.restore();
  }

  /// -1..1 arası salınım. Faz satır+sütuna bağlı olduğu için tahta hep birlikte
  /// değil, çaprazlama bir dalga hâlinde kıpırdıyor.
  double get _sway => sin(clock * 1.7 + (row + col) * 0.55);

  /// Ezilmenin o andaki şiddeti: çarpma anında en yüksek, sönerken bir kez
  /// ters yöne geçiyor — klasik ez-uzat.
  double get _squashAmount {
    final progress = 1 - _squash;
    return cos(progress * pi * 2.4) * _squash;
  }

  /// 0..1 arası yavaş nefes; ipucu parlaması buna göre gidip geliyor.
  double get _breath => (sin(_pulse * 0.42) + 1) / 2;

  // ------------------------------------------------------- ışık süpürmesi ---

  /// İki süpürme arasındaki bekleme.
  static const double _glintPeriod = 5.2;

  /// Işığın tek bir şekerin üstünden geçme süresi.
  static const double _glintSpan = 0.45;

  /// Komşu köşegenler arasındaki gecikme. Küçük tutmak ışığı tahtaya yayıyor;
  /// büyük tutmak dar bir şerit hâlinde geçirtiyor — dar olan hem daha çok
  /// "ışık" gibi duruyor hem de aynı anda yalnızca birkaç şeker çiziyor.
  static const double _glintStagger = 0.14;

  /// Işık şu an bu şekerin üstündeyse 0..1 arası ilerlemesi, değilse null.
  double? get _glint {
    final local = clock % _glintPeriod - (row + col) * _glintStagger;
    if (local < 0 || local > _glintSpan) {
      return null;
    }
    return local / _glintSpan;
  }

  /// Eğik, yumuşak bir ışık şeridi şeklin içinden geçiyor.
  void _renderGlint(Canvas canvas, Rect rect, double progress) {
    final paint = _glintPaint(width, height);
    if (paint == null) {
      return;
    }
    // Uçlarda tamamen sönük: siluetin kenarında sert bir kesik kalmasın.
    paint.color = Colors.white.withValues(alpha: sin(progress * pi) * 0.4);

    canvas.save();
    canvas.clipPath(_outline(rect));
    canvas.translate(-width * 0.7 + progress * width * 2.4, 0);
    canvas.rotate(-0.42);
    canvas.drawRect(_glintBand(width, height), paint);
    canvas.restore();
  }

  /// Şeridin boyası ve dikdörtgeni bütün şekerlerde aynı ölçüde; her karede
  /// yeniden kurmak yerine ölçü başına bir kez üretiliyor.
  ///
  /// Şerit gradyanlı bir shader değil, bulanıklaştırılmış düz beyaz. Sebebi:
  /// `Paint.shader` atanınca `Paint.color` yok sayılıyor, yani şeridi
  /// sönümlemek için her karede yeni bir shader kurmak gerekirdi. Blur ile
  /// hem yumuşaklık aynı hem de sönümleme tek alanı değiştirerek oluyor.
  static final Map<int, Paint> _glintPaints = {};
  static final Map<int, Rect> _glintBands = {};

  static Rect _glintBand(double width, double height) => _glintBands.putIfAbsent(
    width.round(),
    () => Rect.fromCenter(
      center: Offset(0, height / 2),
      width: width * 0.17,
      height: height * 3,
    ),
  );

  static Paint? _glintPaint(double width, double height) {
    if (width <= 0) {
      return null;
    }
    return _glintPaints.putIfAbsent(
      width.round(),
      () => Paint()
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.09),
    );
  }

  // -------------------------------------------------------------- seçim ---

  /// Seçim halkası: dönen kesik çember + içte ince beyaz kontur.
  ///
  /// Önce düz beyaz bir konturdu; hangi şekerin seçili olduğu belliydi ama
  /// duruyordu. Dönen halka seçimin "canlı" olduğunu, oyunun sıradaki
  /// hamleyi beklediğini gösteriyor.
  void _renderSelection(Canvas canvas, Rect rect) {
    final path = _outline(rect);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.075
        ..color = Colors.white,
    );

    canvas.save();
    canvas.translate(width / 2, height / 2);
    canvas.rotate(clock * 1.6);
    final radius = width * 0.58;
    const dashes = 10;
    for (var i = 0; i < dashes; i++) {
      final angle = i * 2 * pi / dashes;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        angle,
        pi / dashes,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 0.055
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: 0.9),
      );
    }
    canvas.restore();
  }

  /// İpucu halkası: kenarda nefes alan sıcak bir parlama.
  void _renderHint(Canvas canvas, Rect rect) {
    final path = _outline(rect);
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

  /// Şekerin dış hattı. Özel şekerler yuvarlak, sıradanlar kendi silueti.
  Path _outline(Rect rect) =>
      isSpecial ? (Path()..addOval(rect)) : shapeOf(rect, shape);

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
      _renderVolume(canvas, rect, shapeOf(rect, shape), color, shape);
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
      _renderVolume(canvas, rect, shapeOf(rect, shape), color, shape);
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
  ///
  /// [decoration] verilirse siluetin içine o türün süsü çiziliyor; bomba ve
  /// renk bombasının gövdesi süssüz kalsın diye ayrı geçiliyor.
  void _renderVolume(
    Canvas canvas,
    Rect rect,
    Path path,
    Color base,
    int? decoration,
  ) {
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

    // 2) Gövde: sol üstten gelen ışığa göre radyal gradyan. Uçlar beyaz/siyah
    // değil, sıcak krem ile tahtanın moru — şeker sahneye ait duruyor.
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 1.05,
          colors: [
            Color.lerp(base, _lightSource, 0.62)!,
            base,
            Color.lerp(base, _shadowTone, 0.5)!,
          ],
          stops: const [0, 0.5, 1],
        ).createShader(rect),
    );

    // 3) Türün kendi süsü.
    if (decoration != null) {
      canvas.save();
      canvas.clipPath(path);
      _decorate(canvas, rect, base, decoration);
      canvas.restore();
    }

    // 4) Alt kenarda ters ışık: şekli zeminden ayırıyor.
    canvas.save();
    canvas.clipPath(path);
    canvas.translate(0, -height * 0.13);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.16
        ..color = Color.lerp(base, _lightSource, 0.45)!.withValues(alpha: 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.06),
    );
    canvas.restore();

    // 5) Üstte keskin parlama.
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

    // 6) İnce koyu kontur, şekli keskinleştiriyor.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.045
        ..color = Color.lerp(base, _shadowTone, 0.62)!.withValues(alpha: 0.75),
    );
  }

  /// Türe özgü yüzey süsü. Çağıran siluete kırpmış oluyor.
  ///
  /// Süsler rastere giriyor, yani karede bir kez değil ömürde bir kez
  /// çiziliyorlar; bu yüzden burada cömert davranabiliyoruz.
  void _decorate(Canvas canvas, Rect rect, Color base, int shape) {
    final light = Color.lerp(base, _lightSource, 0.72)!;
    final dark = Color.lerp(base, _shadowTone, 0.4)!;
    final w = rect.width;
    final h = rect.height;
    final centre = rect.center;

    switch (shape % shapeCount) {
      // Jöle damlası: üstüne serpilmiş şeker taneleri.
      case 0:
        for (final (x, y, r) in _grains) {
          canvas.drawCircle(
            Offset(rect.left + w * x, rect.top + h * y),
            w * r,
            Paint()..color = light.withValues(alpha: 0.6),
          );
        }

      // Karamel: iki çapraz krem şerit.
      case 1:
        canvas.save();
        canvas.translate(centre.dx, centre.dy);
        canvas.rotate(-pi / 4);
        for (final offset in [-0.19, 0.19]) {
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset(0, h * offset),
              width: w * 2,
              height: h * 0.15,
            ),
            Paint()..color = light.withValues(alpha: 0.85),
          );
        }
        canvas.restore();

      // Fasulye: sırtı boyunca uzanan tek parlak çizgi.
      case 2:
        canvas.save();
        canvas.translate(centre.dx, centre.dy);
        canvas.rotate(-0.5);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(0, -h * 0.16),
              width: w * 0.52,
              height: h * 0.12,
            ),
            Radius.circular(h * 0.06),
          ),
          Paint()..color = light.withValues(alpha: 0.8),
        );
        canvas.restore();

      // Dilim: mısır şekeri gibi yatay bantlar.
      case 3:
        canvas.drawRect(
          Rect.fromLTWH(rect.left, rect.top + h * 0.46, w, h * 0.13),
          Paint()..color = light.withValues(alpha: 0.8),
        );
        canvas.drawRect(
          Rect.fromLTWH(rect.left, rect.top + h * 0.72, w, h * 0.1),
          Paint()..color = dark.withValues(alpha: 0.45),
        );

      // Taş: merkezden köşelere giden faset çizgileri.
      case 4:
        final radius = w / 2;
        for (var i = 0; i < 6; i++) {
          final angle = -pi / 2 + i * pi / 3;
          canvas.drawLine(
            centre,
            centre + Offset(cos(angle), sin(angle)) * radius,
            Paint()
              ..strokeWidth = w * 0.03
              ..color = (i.isEven ? light : dark).withValues(alpha: 0.5),
          );
        }
        canvas.drawPath(
          _roundedPoints(_polygonPoints(centre, w * 0.26, 6, -pi / 2), 0.16),
          Paint()..color = light.withValues(alpha: 0.5),
        );

      // Yıldız: içte açık tonda ikinci bir yıldız + şeker taneleri.
      case 5:
        canvas.drawPath(
          _roundedPoints(_starPoints(centre, w * 0.31, w * 0.14, 5), 0.22),
          Paint()..color = light.withValues(alpha: 0.75),
        );

      // Kalp: iki parlak oval — klasik jelibon cilası.
      case 6:
        for (final (x, y, rx, ry) in const [
          (0.34, 0.32, 0.11, 0.075),
          (0.46, 0.24, 0.05, 0.035),
        ]) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(rect.left + w * x, rect.top + h * y),
              width: w * rx * 2,
              height: h * ry * 2,
            ),
            Paint()..color = Colors.white.withValues(alpha: 0.55),
          );
        }

      // Nane çarkı: merkezden dışa dönen beyaz pervane dilimleri.
      case 7:
        final disc = Rect.fromCircle(center: centre, radius: w * 0.62);
        for (var i = 0; i < 6; i++) {
          canvas.drawArc(
            disc,
            i * pi / 3,
            pi / 6,
            true,
            Paint()..color = Colors.white.withValues(alpha: 0.6),
          );
        }
        canvas.drawCircle(
          centre,
          w * 0.1,
          Paint()..color = light.withValues(alpha: 0.9),
        );
    }
  }

  /// Jöle damlasının üstündeki şeker taneleri: (x, y, yarıçap), hepsi şekerin
  /// ölçüsüne oranlı. Sabit liste — her şeker aynı görünsün ve raster
  /// paylaşılabilsin diye rastgele değil.
  static const List<(double, double, double)> _grains = [
    (0.30, 0.26, 0.045),
    (0.55, 0.20, 0.032),
    (0.72, 0.38, 0.038),
    (0.24, 0.52, 0.034),
    (0.46, 0.44, 0.028),
    (0.66, 0.62, 0.042),
    (0.38, 0.72, 0.036),
    (0.58, 0.80, 0.026),
  ];

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
    _renderVolume(canvas, rect, body, const Color(0xFF2A2450), null);

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
    final path = _outline(rect);
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

  // ------------------------------------------------------------ siluetler ---

  /// Bir şekil indeksinin silueti. Açılış ekranındaki görsel de bunu kullanıyor.
  ///
  /// Hepsinin köşesi yuvarlatılmış: sivri çokgen "şekil" gibi duruyor,
  /// yuvarlatılmışı şekere benziyor.
  static Path shapeOf(Rect r, int shape) {
    final c = r.center;
    final radius = r.width / 2;
    return switch (shape % shapeCount) {
      // Jöle damlası.
      0 => Path()..addOval(r.deflate(r.width * 0.02)),
      // Karamel.
      1 => Path()..addRRect(
        RRect.fromRectAndRadius(
          r.deflate(r.width * 0.06),
          Radius.circular(r.width * 0.26),
        ),
      ),
      // Fasulye: eğik kapsül.
      2 => _bean(r),
      // Dilim: yumuşatılmış üçgen, biraz büyütülüp aşağı oturtulmuş.
      3 => _roundedPoints(
        _polygonPoints(
          c.translate(0, r.height * 0.04),
          radius * 1.08,
          3,
          -pi / 2,
        ),
        0.26,
      ),
      // Taş: yumuşatılmış altıgen.
      4 => _roundedPoints(_polygonPoints(c, radius, 6, -pi / 2), 0.16),
      // Yıldız jöle.
      5 => _roundedPoints(_starPoints(c, radius, radius * 0.46, 5), 0.22),
      // Kalp.
      6 => _heart(r),
      // Nane çarkı: taraklı çember.
      7 => _scallop(c, radius, 8),
      // Baklava (yedek).
      8 => _roundedPoints(_polygonPoints(c, radius, 4, -pi / 2), 0.2),
      // Altı uçlu yıldız (yedek).
      _ => _roundedPoints(_starPoints(c, radius, radius * 0.52, 6), 0.28),
    };
  }

  static List<Offset> _polygonPoints(
    Offset center,
    double radius,
    int sides,
    double start,
  ) => [
    for (var i = 0; i < sides; i++)
      center +
          Offset(
            cos(start + i * 2 * pi / sides),
            sin(start + i * 2 * pi / sides),
          ) *
              radius,
  ];

  static List<Offset> _starPoints(
    Offset center,
    double outerRadius,
    double innerRadius,
    int points,
  ) => [
    for (var i = 0; i < points * 2; i++)
      center +
          Offset(
            cos(-pi / 2 + i * pi / points),
            sin(-pi / 2 + i * pi / points),
          ) *
              (i.isEven ? outerRadius : innerRadius),
  ];

  /// Köşeli bir noktalar dizisini yuvarlatılmış bir yola çevirir.
  ///
  /// [round] her kenarın köşede kısaltılan oranı (0 = sivri, 0.5 = tamamen
  /// yuvarlak). Köşe noktası eğrinin kontrol noktası oluyor, yani şeklin
  /// oranları korunuyor, yalnızca uçları yumuşuyor.
  static Path _roundedPoints(List<Offset> points, double round) {
    final path = Path();
    final n = points.length;
    for (var i = 0; i < n; i++) {
      final previous = points[(i - 1 + n) % n];
      final current = points[i];
      final next = points[(i + 1) % n];

      final toPrevious = previous - current;
      final toNext = next - current;
      final entry = current + toPrevious * round;
      final exit = current + toNext * round;

      i == 0 ? path.moveTo(entry.dx, entry.dy) : path.lineTo(entry.dx, entry.dy);
      path.quadraticBezierTo(current.dx, current.dy, exit.dx, exit.dy);
    }
    return path..close();
  }

  /// Eğik duran jöle fasulyesi.
  ///
  /// Kapsül doğrudan [r]'nin merkezine kuruluyor: [_rotation] yalnızca
  /// döndürüyor, ötelemiyor. Origin'de kurulup döndürülseydi şekil kutusunun
  /// dışına düşerdi.
  ///
  /// Ölçüler döndürülmüş hâline göre seçili. Eğik bir kapsülün yatay yarı
  /// genişliği `(w/2)·cos θ + (h/2)·sin θ`; bu hesaba bakılmadan verilen
  /// 0.94 x 0.62 kutudan iki yana 5-6 piksel taşıyor ve komşu hücreye
  /// giriyordu.
  static Path _bean(Rect r) {
    const tilt = -0.42;
    final capsule = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: r.center,
        width: r.width * 0.84,
        height: r.height * 0.56,
      ),
      Radius.circular(r.height * 0.28),
    );
    return (Path()..addRRect(capsule)).transform(_rotation(r.center, tilt));
  }

  /// [center] etrafında [angle] radyan döndüren 4x4 dönüşüm.
  ///
  /// `Matrix4` kullanmıyoruz: adı hem vector_math hem vector_math_64
  /// üzerinden geliyor ve Flame ile Flutter aynı dosyaya ikisini birden
  /// taşıdığı için çakışıyor. Matris zaten tek satırlık.
  static Float64List _rotation(Offset center, double angle) {
    final c = cos(angle);
    final s = sin(angle);
    // Sütun öncelikli. Öteleme, merkez yerinde kalsın diye seçiliyor: t = m - R*m.
    return Float64List.fromList([
      c, s, 0, 0, //
      -s, c, 0, 0, //
      0, 0, 1, 0, //
      center.dx - c * center.dx + s * center.dy,
      center.dy - s * center.dx - c * center.dy,
      0, 1, //
    ]);
  }

  /// Kalp. Üstte iki kavis, altta sivrilen uç.
  static Path _heart(Rect r) {
    final w = r.width;
    final h = r.height;
    final left = r.left;
    final top = r.top;
    // Kalp kendi kutusunda dikeyde biraz aşağı oturuyor; kareye ortalamak için
    // üstten küçük bir pay bırakıyoruz.
    final y = top + h * 0.06;

    return Path()
      ..moveTo(left + w * 0.5, y + h * 0.9)
      ..cubicTo(
        left + w * 0.02,
        y + h * 0.56,
        left + w * 0.06,
        y + h * 0.05,
        left + w * 0.5,
        y + h * 0.27,
      )
      ..cubicTo(
        left + w * 0.94,
        y + h * 0.05,
        left + w * 0.98,
        y + h * 0.56,
        left + w * 0.5,
        y + h * 0.9,
      )
      ..close();
  }

  /// Taraklı çember: nane çarkının dalgalı kenarı.
  ///
  /// Loblar sığ tutuluyor; derin olunca papatyaya benziyor, sığ olunca
  /// kenarı tırtıklı bir şeker gibi duruyor.
  static Path _scallop(Offset center, double radius, int lobes) {
    final path = Path();
    final step = pi / lobes;
    final inner = radius * 0.9;
    for (var i = 0; i < lobes * 2; i++) {
      final angle = i * step;
      final point = center + Offset(cos(angle), sin(angle)) * inner;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
        continue;
      }
      // Kontrol noktası iki tepe arasının dışında: kenar dışa doğru kabarıyor.
      final mid = angle - step / 2;
      final control = center + Offset(cos(mid), sin(mid)) * radius * 1.04;
      path.quadraticBezierTo(control.dx, control.dy, point.dx, point.dy);
    }
    final start = center + Offset(inner, 0);
    final mid = -step / 2;
    final control = center + Offset(cos(mid), sin(mid)) * radius * 1.04;
    path.quadraticBezierTo(control.dx, control.dy, start.dx, start.dy);
    return path..close();
  }
}
