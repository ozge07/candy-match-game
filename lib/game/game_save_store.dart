import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Yarım kalmış bir oyunun tam durumu.
///
/// Izgara iki düz liste hâlinde saklanıyor: her hücrenin türü ve özel şeker
/// cinsi. Böylece kayıt hem küçük hem de sürüm değişikliklerine dayanıklı.
@immutable
class SavedGame {
  const SavedGame({
    required this.score,
    required this.moves,
    required this.level,
    required this.rows,
    required this.cols,
    required this.types,
    required this.kinds,
  });

  final int score;
  final int moves;
  final int level;
  final int rows;
  final int cols;

  /// `rows * cols` uzunluğunda, satır satır.
  final List<int> types;

  /// Aynı sırada `CandyKind` indeksleri.
  final List<int> kinds;

  bool get isValid =>
      types.length == rows * cols && kinds.length == types.length;

  Map<String, dynamic> toJson() => {
    'score': score,
    'moves': moves,
    'level': level,
    'rows': rows,
    'cols': cols,
    'types': types,
    'kinds': kinds,
  };

  static SavedGame? fromJson(Map<String, dynamic> json) {
    try {
      final save = SavedGame(
        score: json['score'] as int,
        moves: json['moves'] as int,
        level: json['level'] as int,
        rows: json['rows'] as int,
        cols: json['cols'] as int,
        types: (json['types'] as List).cast<int>(),
        kinds: (json['kinds'] as List).cast<int>(),
      );
      return save.isValid ? save : null;
    } catch (_) {
      return null;
    }
  }
}

/// Yarım kalan oyunu cihazda saklar; menüdeki "Devam Et" bunu kullanıyor.
class GameSaveStore {
  static const String _key = 'candy_match.saved_game';
  static const Duration _timeout = Duration(seconds: 5);

  /// Menü düğmesinin görünürlüğü bunu dinliyor.
  final ValueNotifier<bool> hasSave = ValueNotifier<bool>(false);

  SavedGame? _cached;

  /// En son kaydedilen oyun (varsa).
  SavedGame? get saved => _cached;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(_timeout);
      final raw = prefs.getString(_key);
      if (raw == null) {
        return;
      }
      final decoded = jsonDecode(raw);
      // Tahta boyutu değişmiş bir sürümden kalan kayıt yüklenemez; sessizce
      // atılıyor, oyuncu yeni oyuna başlıyor.
      _cached = decoded is Map<String, dynamic>
          ? SavedGame.fromJson(decoded)
          : null;
      hasSave.value = _cached != null;
    } catch (error) {
      debugPrint('Kayıtlı oyun okunamadı: $error');
    }
  }

  Future<void> save(SavedGame game) async {
    _cached = game;
    hasSave.value = true;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(_timeout);
      await prefs.setString(_key, jsonEncode(game.toJson())).timeout(_timeout);
    } catch (error) {
      debugPrint('Oyun kaydedilemedi: $error');
    }
  }

  Future<void> clear() async {
    _cached = null;
    hasSave.value = false;
    try {
      final prefs = await SharedPreferences.getInstance().timeout(_timeout);
      await prefs.remove(_key).timeout(_timeout);
    } catch (error) {
      debugPrint('Kayıt silinemedi: $error');
    }
  }

  void dispose() => hasSave.dispose();
}
