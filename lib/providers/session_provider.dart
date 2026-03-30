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
}
