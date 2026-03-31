import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/board_game.dart';
import '../db/database_helper.dart';
import '../services/bgg_service.dart';

class GameProvider with ChangeNotifier {
  final _db = DatabaseHelper();
  final _uuid = const Uuid();
  List<BoardGame> _games = [];

  List<BoardGame> get games => List.unmodifiable(_games);

  Future<void> loadGames() async {
    _games = await _db.getGames();
    notifyListeners();
  }

  Future<BoardGame> addGame({
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
    double? myRating,
    double? myWeight,
    String? bggId,
    bool isExpansion = false,
    String? baseGameId,
    List<String> categories = const [],
    List<String> mechanics = const [],
    int? yearPublished,
    int? minAge,
    double? boughtPrice,
    double? currentPrice,
    DateTime? acquiredAt,
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
      myRating: myRating,
      myWeight: myWeight,
      bggId: bggId,
      isExpansion: isExpansion,
      baseGameId: baseGameId,
      categories: categories,
      mechanics: mechanics,
      yearPublished: yearPublished,
      minAge: minAge,
      boughtPrice: boughtPrice,
      currentPrice: currentPrice,
      acquiredAt: acquiredAt ?? DateTime.now(),
    );
    await _db.insertGame(game);
    _games.add(game);
    _games.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    return game;
  }

  Future<BoardGame> addExpansion({
    required BggExpansionItem item,
    required String baseGameId,
  }) async {
    return addGame(
      name: item.name,
      minPlayers: item.minPlayers ?? 2,
      maxPlayers: item.maxPlayers ?? 4,
      imageUrl: item.imageUrl,
      thumbnailUrl: item.thumbnailUrl,
      minPlaytime: item.minPlaytime,
      maxPlaytime: item.maxPlaytime,
      bggRating: item.bggRating,
      complexity: item.complexity,
      bggId: item.bggId,
      isExpansion: true,
      baseGameId: baseGameId,
    );
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

  // ── Import ──────────────────────────────────────────────────────────────────

  /// Imports games from a parsed JSON export (each map has an 'id' field).
  /// Skips games whose id already exists. Returns added/skipped counts.
  Future<({int added, int skipped})> importGamesFromJson(
      List<Map<String, dynamic>> maps) async {
    final existingIds = _games.map((g) => g.id).toSet();
    int added = 0, skipped = 0;
    for (final map in maps) {
      final id = map['id'] as String?;
      if (id == null || existingIds.contains(id)) {
        skipped++;
        continue;
      }
      try {
        final game = BoardGame.fromMap(map);
        await _db.insertGame(game);
        _games.add(game);
        existingIds.add(id);
        added++;
      } catch (_) {
        skipped++;
      }
    }
    if (added > 0) {
      _games.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }
    return (added: added, skipped: skipped);
  }

  /// Imports games from a parsed Collection CSV (no 'id'; matched by lowercase name).
  /// Categories/mechanics in CSV are '; '-separated strings.
  Future<({int added, int skipped})> importGamesFromCsv(
      List<Map<String, dynamic>> maps) async {
    final existingNames =
        _games.map((g) => g.name.toLowerCase()).toSet();
    int added = 0, skipped = 0;
    for (final map in maps) {
      final name = (map['name'] as String? ?? '').trim();
      if (name.isEmpty || existingNames.contains(name.toLowerCase())) {
        skipped++;
        continue;
      }
      try {
        final cats = (map['categories'] as String? ?? '')
            .split(';')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        final mechs = (map['mechanics'] as String? ?? '')
            .split(';')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        final addedAt = DateTime.tryParse(
                map['added_at'] as String? ?? '') ??
            DateTime.now();
        final game = BoardGame(
          id: _uuid.v4(),
          name: name,
          minPlayers: map['min_players'] as int? ?? 2,
          maxPlayers: map['max_players'] as int? ?? 4,
          createdAt: addedAt,
          hasBeenPlayed: (map['has_been_played'] as int? ?? 0) == 1,
          minPlaytime: map['min_playtime'] as int?,
          maxPlaytime: map['max_playtime'] as int?,
          bggRating: map['bgg_rating'] as double?,
          complexity: map['complexity'] as double?,
          myRating: map['my_rating'] as double?,
          isExpansion: (map['is_expansion'] as int? ?? 0) == 1,
          categories: cats,
          mechanics: mechs,
          yearPublished: map['year_published'] as int?,
          minAge: map['min_age'] as int?,
        );
        await _db.insertGame(game);
        _games.add(game);
        existingNames.add(name.toLowerCase());
        added++;
      } catch (_) {
        skipped++;
      }
    }
    if (added > 0) {
      _games.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }
    return (added: added, skipped: skipped);
  }

  /// Syncs the BGG collection for [username].
  /// Returns how many games were added vs already in collection.
  /// Throws if the username is not found or network fails.
  Future<({int added, int skipped})> syncBggCollection(String username) async {
    final bgg = BggService();

    final collectionIds = await bgg.fetchCollectionIds(username);
    if (collectionIds.isEmpty) {
      throw Exception('notfound');
    }

    final existingBggIds = _games
        .where((g) => g.bggId != null)
        .map((g) => g.bggId!)
        .toSet();

    final newIds = collectionIds
        .where((id) => !existingBggIds.contains(id))
        .toList();

    final skipped = collectionIds.length - newIds.length;

    if (newIds.isEmpty) {
      return (added: 0, skipped: skipped);
    }

    final details = await bgg.fetchGameDetailsBatch(newIds);

    for (final d in details) {
      await addGame(
        name: d.name,
        description: d.description,
        minPlayers: d.minPlayers,
        maxPlayers: d.maxPlayers,
        imageUrl: d.imageUrl,
        thumbnailUrl: d.thumbnailUrl,
        minPlaytime: d.minPlaytime,
        maxPlaytime: d.maxPlaytime,
        bggRating: d.bggRating,
        complexity: d.complexity,
        bggId: d.id,
        categories: d.categories,
        mechanics: d.mechanics,
        yearPublished: d.yearPublished,
        minAge: d.minAge,
      );
    }

    return (added: details.length, skipped: skipped);
  }
}
