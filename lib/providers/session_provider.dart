import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/game_session.dart';
import '../models/player_result.dart';
import '../db/database_helper.dart';

class SessionProvider with ChangeNotifier {
  final _db = DatabaseHelper();
  final _uuid = const Uuid();
  List<GameSession> _sessions = [];

  List<GameSession> get sessions => List.unmodifiable(_sessions);

  Future<void> loadSessions() async {
    _sessions = await _db.getSessions();
    notifyListeners();
  }

  Future<void> saveSession({
    required String gameId,
    required String gameName,
    required DateTime startTime,
    required DateTime endTime,
    required int durationSeconds,
    required List<Map<String, dynamic>> playerData,
    String? notes,
    bool isFromCollection = true,
    List<String> expansionIds = const [],
    String? location,
    String? tiebreaker,
  }) async {
    final sessionId = _uuid.v4();
    final players = playerData
        .map((p) => PlayerResult(
              id: _uuid.v4(),
              sessionId: sessionId,
              playerName: p['name'] as String,
              score: p['score'] as int?,
              rank: p['rank'] as int,
              startedGame: p['startedGame'] as bool? ?? false,
              teamName: p['teamName'] as String?,
            ))
        .toList();

    final session = GameSession(
      id: sessionId,
      gameId: gameId,
      gameName: gameName,
      startTime: startTime,
      endTime: endTime,
      durationSeconds: durationSeconds,
      players: players,
      notes: notes,
      isFromCollection: isFromCollection,
      expansionIds: expansionIds,
      location: location,
      tiebreaker: tiebreaker,
    );
    await _db.insertSession(session);
    _sessions.insert(0, session);
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    await _db.deleteSession(id);
    _sessions.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  List<GameSession> sessionsForGame(String gameId) =>
      _sessions.where((s) => s.gameId == gameId).toList();

  // ── Import ──────────────────────────────────────────────────────────────────

  /// Imports sessions from a parsed JSON export. Each map must have 'id' and
  /// a nested 'players' list. Skips sessions whose id already exists.
  Future<({int added, int skipped})> importSessionsFromJson(
      List<Map<String, dynamic>> maps) async {
    final existingIds = _sessions.map((s) => s.id).toSet();
    int added = 0, skipped = 0;
    for (final map in maps) {
      final id = map['id'] as String?;
      if (id == null || existingIds.contains(id)) {
        skipped++;
        continue;
      }
      try {
        final playerMaps =
            (map['players'] as List? ?? []).cast<Map<String, dynamic>>();
        final players = playerMaps
            .map((p) => PlayerResult(
                  id: _uuid.v4(),
                  sessionId: id,
                  playerName: p['player_name'] as String,
                  rank: p['rank'] as int? ?? 1,
                  score: p['score'] as int?,
                  startedGame: p['started_game'] as bool? ?? false,
                  teamName: p['team_name'] as String?,
                ))
            .toList();
        final sessionMap = Map<String, dynamic>.from(map)..remove('players');
        final session = GameSession.fromMap(sessionMap, players);
        await _db.insertSession(session);
        _sessions.add(session);
        existingIds.add(id);
        added++;
      } catch (_) {
        skipped++;
      }
    }
    if (added > 0) {
      _sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      notifyListeners();
    }
    return (added: added, skipped: skipped);
  }

  /// Imports sessions from a parsed Sessions CSV. Uses session_id for duplicate
  /// detection. Each map has a nested 'players' list with player data.
  Future<({int added, int skipped})> importSessionsFromCsv(
      List<Map<String, dynamic>> maps) async {
    final existingIds = _sessions.map((s) => s.id).toSet();
    int added = 0, skipped = 0;
    for (final map in maps) {
      final id = map['id'] as String? ?? '';
      if (id.isEmpty || existingIds.contains(id)) {
        skipped++;
        continue;
      }
      try {
        final playerMaps =
            (map['players'] as List? ?? []).cast<Map<String, dynamic>>();
        final players = playerMaps
            .map((p) => PlayerResult(
                  id: _uuid.v4(),
                  sessionId: id,
                  playerName: p['player_name'] as String,
                  rank: p['rank'] as int? ?? 1,
                  score: p['score'] as int?,
                  startedGame: p['started_game'] as bool? ?? false,
                  teamName: p['team_name'] as String?,
                ))
            .toList();
        final sessionMap = Map<String, dynamic>.from(map)..remove('players');
        final session = GameSession.fromMap(sessionMap, players);
        await _db.insertSession(session);
        _sessions.add(session);
        existingIds.add(id);
        added++;
      } catch (_) {
        skipped++;
      }
    }
    if (added > 0) {
      _sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      notifyListeners();
    }
    return (added: added, skipped: skipped);
  }
}
