import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/board_game.dart';
import '../db/database_helper.dart';

class GameProvider with ChangeNotifier {
  final _db = DatabaseHelper();
  final _uuid = const Uuid();
  List<BoardGame> _games = [];

  List<BoardGame> get games => List.unmodifiable(_games);

  Future<void> loadGames() async {
    _games = await _db.getGames();
    notifyListeners();
  }

  Future<void> addGame({
    required String name,
    String? description,
    required int minPlayers,
    required int maxPlayers,
    String? setupHints,
    String? imageUrl,
    String? thumbnailUrl,
    int? minPlaytime,
    int? maxPlaytime,
    double? bggRating,
    double? complexity,
  }) async {
    final game = BoardGame(
      id: _uuid.v4(),
      name: name,
      description: description,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      setupHints: setupHints,
      createdAt: DateTime.now(),
      hasBeenPlayed: false,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      minPlaytime: minPlaytime,
      maxPlaytime: maxPlaytime,
      bggRating: bggRating,
      complexity: complexity,
    );
    await _db.insertGame(game);
    _games.add(game);
    _games.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> updateGame(BoardGame game) async {
    await _db.updateGame(game);
    final index = _games.indexWhere((g) => g.id == game.id);
    if (index != -1) {
      _games[index] = game;
      _games.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }
  }

  Future<void> togglePlayed(String id) async {
    final index = _games.indexWhere((g) => g.id == id);
    if (index == -1) return;
    final updated = _games[index].copyWith(hasBeenPlayed: !_games[index].hasBeenPlayed);
    await _db.updateGame(updated);
    _games[index] = updated;
    notifyListeners();
  }

  /// Marks a single game as played. No-op if already played or not found.
  Future<void> markAsPlayed(String gameId) async {
    final index = _games.indexWhere((g) => g.id == gameId);
    if (index == -1 || _games[index].hasBeenPlayed) return;
    final updated = _games[index].copyWith(hasBeenPlayed: true);
    await _db.updateGame(updated);
    _games[index] = updated;
    notifyListeners();
  }

  /// Called on startup to retroactively mark games that already have sessions.
  Future<void> autoMarkFromSessions(Iterable<String> gameIds) async {
    final ids = gameIds.toSet();
    bool changed = false;
    for (int i = 0; i < _games.length; i++) {
      if (!_games[i].hasBeenPlayed && ids.contains(_games[i].id)) {
        final updated = _games[i].copyWith(hasBeenPlayed: true);
        await _db.updateGame(updated);
        _games[i] = updated;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  Future<void> deleteGame(String id) async {
    await _db.deleteGame(id);
    _games.removeWhere((g) => g.id == id);
    notifyListeners();
  }
}
