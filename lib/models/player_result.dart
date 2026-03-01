class PlayerResult {
  final String id;
  final String sessionId;
  final String playerName;
  final int? score;
  final int rank;
  final bool startedGame;

  const PlayerResult({
    required this.id,
    required this.sessionId,
    required this.playerName,
    this.score,
    required this.rank,
    required this.startedGame,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'session_id': sessionId,
        'player_name': playerName,
        'score': score,
        'rank': rank,
        'started_game': startedGame ? 1 : 0,
      };

  factory PlayerResult.fromMap(Map<String, dynamic> map) => PlayerResult(
        id: map['id'] as String,
        sessionId: map['session_id'] as String,
        playerName: map['player_name'] as String,
        score: map['score'] as int?,
        rank: map['rank'] as int,
        startedGame: (map['started_game'] as int) == 1,
      );
}
