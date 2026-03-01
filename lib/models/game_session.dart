import 'player_result.dart';

class GameSession {
  final String id;
  final String gameId;
  final String gameName;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationSeconds;
  final List<PlayerResult> players;
  final String? notes;

  const GameSession({
    required this.id,
    required this.gameId,
    required this.gameName,
    required this.startTime,
    this.endTime,
    required this.durationSeconds,
    required this.players,
    this.notes,
  });

  String get durationFormatted {
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'game_id': gameId,
        'game_name': gameName,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime?.toIso8601String(),
        'duration_seconds': durationSeconds,
        'notes': notes,
      };

  factory GameSession.fromMap(
    Map<String, dynamic> map,
    List<PlayerResult> players,
  ) =>
      GameSession(
        id: map['id'] as String,
        gameId: map['game_id'] as String,
        gameName: map['game_name'] as String,
        startTime: DateTime.parse(map['start_time'] as String),
        endTime: map['end_time'] != null
            ? DateTime.parse(map['end_time'] as String)
            : null,
        durationSeconds: map['duration_seconds'] as int,
        players: players,
        notes: map['notes'] as String?,
      );
}
