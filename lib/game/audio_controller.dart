import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Tüm ses efektlerini yönetir.
///
/// Sık çalınan efektler (patlama, takas) için `AudioPool` kullanıyoruz: her
/// seferinde yeni bir oynatıcı kurmak Android'de gözle görülür gecikme
/// yaratıyor, havuz ise önceden hazırlanmış oynatıcıları geri dönüştürüyor.
class AudioController {
  /// `pop1..pop6` — zincir uzadıkça bir üst nota çalınıyor.
  static const int popVariants = 6;

  static final List<String> _pooled = [
    'swap',
    'invalid',
    'bomb',
    'bomb_create',
    'rainbow',
    'cross',
    'mega',
    'pour',
    for (var i = 1; i <= popVariants; i++) 'pop$i',
  ];

  static const List<String> _oneShots = [
    'praise1.wav',
    'praise2.wav',
    'praise3.wav',
    'gameover.wav',
    'record.wav',
    'levelup.wav',
  ];

  final ValueNotifier<bool> muted = ValueNotifier<bool>(false);

  /// Açılış ekranındaki yükleme çubuğu bunu dinliyor: 0 → 1.
  final ValueNotifier<double> progress = ValueNotifier<double>(0);

  final Map<String, AudioPool> _pools = {};
  bool _ready = false;

  /// Sesleri hazırlar. Ses altyapısı kullanılamıyorsa (test ortamı, eksik
  /// asset, ses aygıtı yok) oyun sessiz çalışmaya devam eder — bu yüzden hata
  /// yutuluyor, yeniden fırlatılmıyor.
  /// Ses altyapısı yanıt vermezse açılış ekranında sonsuza kadar beklemeyelim.
  static const Duration _loadTimeout = Duration(seconds: 8);

  Future<void> load() async {
    if (_ready) {
      return;
    }
    try {
      await _loadAll().timeout(_loadTimeout);
      _ready = true;
    } catch (error, stackTrace) {
      _ready = false;
      debugPrint('Ses yüklenemedi, oyun sessiz devam ediyor: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      progress.value = 1;
    }
  }

  Future<void> _loadAll() async {
    final total = _pooled.length + _oneShots.length;
    var done = 0;
    for (final name in _pooled) {
      _pools[name] = await FlameAudio.createPool(
        '$name.wav',
        minPlayers: 1,
        maxPlayers: 4,
      );
      progress.value = ++done / total;
    }
    for (final name in _oneShots) {
      await FlameAudio.audioCache.load(name);
      progress.value = ++done / total;
    }
  }

  void _play(String name, double volume) {
    if (muted.value || !_ready) {
      return;
    }
    final pool = _pools[name];
    if (pool != null) {
      unawaited(pool.start(volume: volume));
    }
  }

  void swap() => _play('swap', 0.7);

  /// Yeni tahta yukarıdan dökülürken çalan boncuk akışı.
  void pour() => _play('pour', 0.85);

  void invalidMove() => _play('invalid', 0.6);

  void bombArmed() => _play('bomb_create', 1.0);

  /// Zincirin kaçıncı adımında olduğumuza göre gittikçe tizleşen patlama sesi;
  /// arka arkaya patlamalar pentatonik bir ezgi gibi duyuluyor.
  void pop(int chain) => _play('pop${chain.clamp(1, popVariants)}', 0.95);

  void bomb() {
    _play('bomb', 1.0);
    unawaited(HapticFeedback.mediumImpact());
  }

  /// Renk bombası: tahtadaki bir rengin tamamı silinirken.
  void rainbow() {
    _play('rainbow', 1.0);
    unawaited(HapticFeedback.heavyImpact());
  }

  /// Çapraz patlama: iki bomba yan yana gelip satır/sütun süpürülürken.
  void cross() {
    _play('cross', 1.0);
    unawaited(HapticFeedback.mediumImpact());
  }

  /// Mega patlama: iki renk bombası yan yana gelip tahtanın tamamı uçarken.
  void mega() {
    _play('mega', 1.0);
    unawaited(HapticFeedback.heavyImpact());
  }

  /// [level] 1..3 — zincir uzadıkça daha görkemli fanfar.
  void praise(int level) {
    if (muted.value || !_ready) {
      return;
    }
    unawaited(
      FlameAudio.play('praise${level.clamp(1, 3)}.wav', volume: 1.0),
    );
  }

  /// Yeni seviyeye geçilirken.
  void levelUp() {
    if (muted.value || !_ready) {
      return;
    }
    unawaited(FlameAudio.play('levelup.wav', volume: 1.0));
    unawaited(HapticFeedback.mediumImpact());
  }

  /// En yüksek skor kırıldığı an.
  void record() {
    if (muted.value || !_ready) {
      return;
    }
    unawaited(FlameAudio.play('record.wav', volume: 1.0));
    unawaited(HapticFeedback.heavyImpact());
  }

  /// Hamle kalmadığında çalan iniş motifi.
  void gameOver() {
    if (muted.value || !_ready) {
      return;
    }
    unawaited(FlameAudio.play('gameover.wav', volume: 1.0));
    unawaited(HapticFeedback.heavyImpact());
  }

  void toggleMute() => muted.value = !muted.value;

  void dispose() {
    muted.dispose();
    progress.dispose();
    for (final pool in _pools.values) {
      unawaited(pool.dispose());
    }
  }
}
