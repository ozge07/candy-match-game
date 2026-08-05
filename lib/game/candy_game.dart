import 'dart:async';
import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'audio_controller.dart';
import 'board.dart';
import 'candy.dart';
import 'effects.dart';
import 'game_save_store.dart';
import 'high_score_store.dart';
import 'level_theme.dart';
import 'tip_store.dart';

/// Oyunun kökü.
///
/// Sabit çözünürlüklü bir kamera kullanıyoruz: dünya koordinatları her cihazda
/// [gameWidth] x [gameHeight] olarak kalıyor, Flame de görüntüyü ekrana göre
/// ölçekliyor. Böylece tahta yerleşimi için cihaz boyutuyla uğraşmıyoruz.
class CandyGame extends FlameGame {
  CandyGame({
    AudioController? audio,
    HighScoreStore? highScores,
    GameSaveStore? saves,
    TipStore? tips,
    this.resume,
  }) : audio = audio ?? AudioController(),
       highScores = highScores ?? HighScoreStore(),
       saves = saves ?? GameSaveStore(),
       tips = tips ?? TipStore();

  /// Dünya her cihazda tam olarak bu kadar geniş; yükseklik ekran oranından
  /// hesaplanıyor. Böylece hem tüm ölçüler tek bir referansa göre ayarlanabiliyor
  /// hem de ekranın üstünde/altında siyah bant kalmıyor.
  static const double gameWidth = 720;

  static const int rows = 11;
  static const int cols = 8;

  /// Tahtanın yanlarında bırakılan boşluk. Küçük tutuluyor: tahta ekranın
  /// enini neredeyse tamamen kaplasın.
  static const double _boardMargin = 14;

  /// HUD'a ayrılan üst şerit (dünya birimi).
  static const double _hudSpace = 215;

  /// Seviye çubuğuna ayrılan alt şerit (dünya birimi).
  static const double _levelBarSpace = 150;

  /// Kaç puanda bir seviye atlanıyor.
  static const int pointsPerLevel = 2000;

  /// Birinci seviyede kaç farklı şeker türü var.
  static const int startingTypes = 6;

  /// Kaç seviyede bir yeni bir şeker türü ekleniyor.
  static const int levelsPerNewType = 2;

  /// Dünyanın görünen yüksekliği; ekran oranına göre değişiyor.
  double worldHeight = 1280;

  /// HUD katmanı bu değerleri dinliyor.
  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> moves = ValueNotifier<int>(0);

  /// Hamle kalmadığında true olur; oyun sonu kartını bu tetikliyor.
  final ValueNotifier<bool> isOver = ValueNotifier<bool>(false);

  /// Ses altyapısı uygulama boyunca paylaşılıyor, oyunla birlikte doğup
  /// ölmüyor — bu yüzden burada `dispose` edilmiyor.
  final AudioController audio;

  /// Rekor da uygulama boyunca paylaşılıyor, oyunla birlikte ölmüyor.
  final HighScoreStore highScores;

  /// Yarım kalan oyunun kaydı.
  final GameSaveStore saves;

  /// Açılış ipucunun durumu.
  final TipStore tips;

  /// Verilirse oyun bu kayıttan devam ediyor.
  final SavedGame? resume;

  /// Oyuna başlarken geçerli olan rekor. Kutlamayı bir kez tetiklemek ve
  /// "ilk oyunda 0'ı geçtin" gibi anlamsız bir kutlama yapmamak için lazım.
  int _bestAtStart = 0;
  bool _recordCelebrated = false;

  _CameraShake? _shake;
  BoardComponent? _board;

  /// Oyuncunun bulunduğu seviye; HUD ve tema bunu izliyor.
  final ValueNotifier<int> level = ValueNotifier<int>(1);

  LevelTheme theme = LevelTheme.forLevel(1);

  /// Tahtanın dünya koordinatındaki üst kenarı — tebrik yazısı ve efektler
  /// buna göre konumlanıyor.
  double _boardTop = 0;

  @override
  Color backgroundColor() => LevelTheme.background;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Dünyanın genişliği sabit; yükseklik ekran oranından geliyor. Zoom'u
    // buna göre ayarlayınca ekranın üstünde/altında bant kalmıyor.
    camera.viewfinder.zoom = size.x / gameWidth;
    worldHeight = size.y / camera.viewfinder.zoom;
    _layoutBoard();
  }

  @override
  Future<void> onLoad() async {
    final save = resume;
    if (save != null) {
      score.value = save.score;
      moves.value = save.moves;
      level.value = save.level;
      theme = LevelTheme.forLevel(save.level);
    }
    camera.viewfinder.anchor = Anchor.topLeft;
    // Sesleri açılış ekranı yüklüyor; oyun sadece kullanıyor. Hazır değilse
    // efektler sessizce atlanıyor (bkz. AudioController).
    _addBoard();
  }

  double get _cellSize => (gameWidth - _boardMargin * 2) / cols;

  @visibleForTesting
  double get debugCellSize => _cellSize;

  /// Tahtayı HUD ile seviye çubuğu arasındaki alanın ortasına yerleştirir.
  void _layoutBoard() {
    final boardHeight = _cellSize * rows;
    final available = worldHeight - _hudSpace - _levelBarSpace;
    _boardTop = _hudSpace + (available - boardHeight) / 2;
    _board?.position.setValues(_boardMargin, _boardTop);
  }

  void _addBoard() {
    _bestAtStart = highScores.best.value;
    _recordCelebrated = false;
    final board = BoardComponent(
      rows: rows,
      cols: cols,
      cellSize: _cellSize,
      theme: theme,
      restore: resume,
      position: Vector2(_boardMargin, _boardTop),
    );
    _board = board;
    world.add(board);
    _layoutBoard();
  }

  void addScore(int amount) {
    score.value += amount;
    _checkLevelUp();

    if (score.value <= highScores.best.value) {
      return;
    }

    // Rekoru anında güncelliyoruz ki HUD'daki kupa canlı olarak yükselsin.
    unawaited(highScores.submit(score.value));

    // Kutlama sadece gerçekten bir rekor kırıldığında ve bir kez.
    if (!_recordCelebrated && _bestAtStart > 0) {
      _recordCelebrated = true;
      _celebrateRecord();
    }
  }

  /// Rekor kırıldığı an: konfeti, altın parlama, hafif sarsıntı ve fanfar.
  void _celebrateRecord() {
    audio.record();
    flashScreen();
    shakeCamera(intensity: 8, duration: 0.35);
    showPraise('YENİ REKOR!', level: 3, color: const Color(0xFFFFD54A));
    world.add(
      confetti(
        position: Vector2(gameWidth / 2, 0),
        width: gameWidth,
        palette: Candy.palette,
      ),
    );
  }

  void registerMove() => moves.value++;

  /// Bu seviyede tahtaya kaç farklı şeker türü düşüyor.
  ///
  /// Zorluk buradan geliyor: tür sayısı arttıkça üçlü bulmak zorlaşıyor,
  /// büyük kümeler ve özel şekerler doğal olarak seyrekleşiyor. Tanımlı tür
  /// sayısında tavan yapıyor.
  int get activeTypes =>
      (startingTypes + (level.value - 1) ~/ levelsPerNewType).clamp(
        startingTypes,
        Candy.typeCount,
      );

  /// Skor eşiği geçildiyse seviye atlatır. Seviye sayısı sınırsız.
  void _checkLevelUp() {
    final next = score.value ~/ pointsPerLevel + 1;
    if (next <= level.value) {
      return;
    }
    level.value = next;
    theme = LevelTheme.forLevel(next);
    _board?.applyTheme(theme);
    _celebrateLevelUp(next);
  }

  /// Seviye atlama kutlaması. Efekt her seviyede değişiyor ki tekrar
  /// etmesin — dört çeşit sırayla dönüyor.
  void _celebrateLevelUp(int newLevel) {
    audio.levelUp();
    showPraise(
      'SEVİYE $newLevel',
      level: 3,
      color: LevelTheme.accent,
      atY: _levelBannerY,
    );
    final centre = Vector2(gameWidth / 2, _boardTop + _cellSize * rows / 2);

    switch (newLevel % 4) {
      case 0:
        // Konfeti yağmuru
        flashScreen();
        world.add(
          confetti(
            position: Vector2(gameWidth / 2, 0),
            width: gameWidth,
            palette: Candy.palette,
          ),
        );
      case 1:
        // Merkezden açılan halkalar
        shakeCamera(intensity: 12, duration: 0.5);
        for (var i = 0; i < 4; i++) {
          world.add(
            Shockwave(
              position: centre,
              maxRadius: _cellSize * (3.0 + i * 2.0),
              color: i.isEven ? LevelTheme.accent : Colors.white,
              duration: 0.55 + i * 0.15,
              thickness: 14 - i * 3.0,
            ),
          );
        }
      case 2:
        // Tahtayı tarayan ışınlar
        shakeCamera(intensity: 10, duration: 0.45);
        for (var r = 0; r < rows; r += 2) {
          world.add(
            Beam(
              position: Vector2(
                gameWidth / 2,
                _boardTop + (r + 0.5) * _cellSize,
              ),
              size: Vector2(gameWidth, _cellSize * 0.5),
              color: LevelTheme.accent,
              duration: 0.6,
            ),
          );
        }
      default:
        // Yıldız patlaması
        flashScreen();
        shakeCamera(intensity: 14, duration: 0.5);
        world.add(
          bombBurst(
            position: centre,
            cellSize: _cellSize * 2,
            palette: Candy.palette,
          ),
        );
    }
  }

  /// Zincir tebriklerinin çıktığı yükseklik: tahtanın üst kısmı. HUD'un
  /// altında kalıyor ki kartların üstüne binmesin.
  double get _praiseY => _boardTop + _cellSize * rows * 0.22;

  /// Seviye bildirimi tahtanın ortasında beliriyor; böylece aynı anda çıkan
  /// zincir tebrikiyle üst üste binmiyor.
  double get _levelBannerY => _boardTop + _cellSize * rows * 0.55;

  /// Tahtanın üstünde beliren tebrik mesajı.
  void showPraise(
    String text, {
    required int level,
    Color? color,
    double? atY,
  }) {
    audio.praise(level);
    world.add(
      FloatingText(
        text: text,
        position: Vector2(gameWidth / 2, atY ?? _praiseY),
        duration: 1.15,
        rise: 44,
        popIn: true,
        style: TextStyle(
          fontSize: 56 + level * 6,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: color ?? const Color(0xFFF1C40F),
          shadows: const [
            Shadow(blurRadius: 14, color: Colors.black87),
            Shadow(blurRadius: 30, color: Color(0x88FFC145)),
          ],
        ),
      ),
    );
  }

  /// Mega patlamada ekranı bir an beyazlatır.
  void flashScreen() {
    world.add(ScreenFlash(size: Vector2(gameWidth, worldHeight)));
  }

  /// Bomba patlamasında ekranı sarsar.
  void shakeCamera({double intensity = 9, double duration = 0.35}) {
    _shake?.restore();
    _shake?.removeFromParent();
    final shake = _CameraShake(
      camera.viewfinder,
      intensity: intensity,
      duration: duration,
    );
    _shake = shake;
    add(shake);
  }

  /// Tahtanın o anki hâlini kaydeder; oyun bittiyse kaydı siler.
  ///
  /// Animasyon ortasında çağrılırsa ızgara eksik olabilir — o durumda
  /// `snapshot()` null döner ve kayıt atlanır, bir önceki kayıt geçerli kalır.
  void saveProgress() {
    if (isOver.value) {
      return;
    }
    final grid = _board?.snapshot();
    if (grid == null) {
      return;
    }
    unawaited(
      saves.save(
        SavedGame(
          score: score.value,
          moves: moves.value,
          level: level.value,
          rows: rows,
          cols: cols,
          types: grid.types,
          kinds: grid.kinds,
        ),
      ),
    );
  }

  /// Reklamla devam etme tur başına bir kez.
  bool _usedContinue = false;

  bool get canContinue => !_usedContinue;

  /// Reklam izlendi: tahta karıştırılıp oyun kaldığı yerden sürüyor.
  void continueAfterAd() {
    if (!canContinue || !isOver.value) {
      return;
    }
    _usedContinue = true;
    isOver.value = false;
    _board?.reshuffleForContinue();
    // Oyun sürdüğü için kayıt geri geliyor: menüdeki "Devam Et" tekrar çıksın.
    saveProgress();
  }

  /// Hamle kalmadı: skoru dondurup oyun sonu kartını açıyoruz.
  void endGame() {
    if (isOver.value) {
      return;
    }
    isOver.value = true;
    // Biten oyuna dönülemez; menüdeki "Devam Et" kaybolsun.
    unawaited(saves.clear());
    audio.gameOver();
    shakeCamera(intensity: 14, duration: 0.5);
    flashScreen();
  }

  @override
  void onRemove() {
    score.dispose();
    moves.dispose();
    isOver.dispose();
    level.dispose();
    super.onRemove();
  }
}

/// Sönümlenen rastgele kamera titreşimi.
class _CameraShake extends Component {
  _CameraShake(this.viewfinder, {required this.intensity, required this.duration});

  final Viewfinder viewfinder;
  final double intensity;
  final double duration;

  final Random _random = Random();
  late final Vector2 _origin = viewfinder.position.clone();
  double _elapsed = 0;

  void restore() => viewfinder.position = _origin;

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= duration) {
      restore();
      removeFromParent();
      return;
    }
    final decay = 1 - _elapsed / duration;
    final offset =
        Vector2(_random.nextDouble() * 2 - 1, _random.nextDouble() * 2 - 1)
          ..scale(intensity * decay);
    viewfinder.position = _origin + offset;
  }
}
