import 'package:flutter_test/flutter_test.dart';
import 'package:board_game_manager/models/game_session.dart';
import 'package:board_game_manager/models/player_result.dart';
import 'package:board_game_manager/services/stats_service.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

GameSession _session({
  required String id,
  required String gameId,
  required String gameName,
  required int durationSeconds,
  required List<PlayerResult> players,
  DateTime? startTime,
  List<String> expansionIds = const [],
}) =>
    GameSession(
      id: id,
      gameId: gameId,
      gameName: gameName,
      startTime: startTime ?? DateTime(2024, 1, 1),
      durationSeconds: durationSeconds,
      players: players,
      expansionIds: expansionIds,
    );

PlayerResult _player(
  String name, {
  required int rank,
  int? score,
  String? teamName,
}) =>
    PlayerResult(
      id: '$name-id',
      sessionId: 'sess',
      playerName: name,
      rank: rank,
      score: score,
      startedGame: false,
      teamName: teamName,
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('StatsService.computeGameStats', () {
    test('counts sessions and accumulates duration', () {
      final sessions = [
        _session(id: 's1', gameId: 'g1', gameName: 'Chess', durationSeconds: 600, players: [
          _player('Alice', rank: 1),
        ]),
        _session(id: 's2', gameId: 'g1', gameName: 'Chess', durationSeconds: 900, players: [
          _player('Bob', rank: 1),
        ]),
      ];
      final stats = StatsService.computeGameStats(sessions);
      expect(stats['g1']!.sessionCount, 2);
      expect(stats['g1']!.totalSeconds, 1500);
      expect(stats['g1']!.avgSeconds, 750);
    });

    test('tracks player wins', () {
      final sessions = [
        _session(id: 's1', gameId: 'g1', gameName: 'Chess', durationSeconds: 600, players: [
          _player('Alice', rank: 1),
          _player('Bob', rank: 2),
        ]),
        _session(id: 's2', gameId: 'g1', gameName: 'Chess', durationSeconds: 600, players: [
          _player('Alice', rank: 1),
          _player('Bob', rank: 2),
        ]),
      ];
      final stats = StatsService.computeGameStats(sessions);
      expect(stats['g1']!.playerWins['Alice'], 2);
      expect(stats['g1']!.playerWins['Bob'], isNull);
    });

    test('bestPlayer picks highest wins', () {
      final sessions = [
        _session(id: 's1', gameId: 'g1', gameName: 'Chess', durationSeconds: 600, players: [
          _player('Alice', rank: 1),
          _player('Bob', rank: 2),
        ]),
        _session(id: 's2', gameId: 'g1', gameName: 'Chess', durationSeconds: 600, players: [
          _player('Bob', rank: 1),
          _player('Alice', rank: 2),
        ]),
        _session(id: 's3', gameId: 'g1', gameName: 'Chess', durationSeconds: 600, players: [
          _player('Bob', rank: 1),
          _player('Alice', rank: 2),
        ]),
      ];
      final stats = StatsService.computeGameStats(sessions);
      expect(stats['g1']!.bestPlayer, 'Bob');
    });

    test('tracks scores correctly', () {
      final sessions = [
        _session(id: 's1', gameId: 'g1', gameName: 'Chess', durationSeconds: 600, players: [
          _player('Alice', rank: 1, score: 50),
          _player('Bob', rank: 2, score: 30),
        ]),
      ];
      final stats = StatsService.computeGameStats(sessions);
      expect(stats['g1']!.highestScore, 50);
      expect(stats['g1']!.lowestScore, 30);
      expect(stats['g1']!.avgScore, 40.0);
    });

    test('tracks longest and shortest sessions', () {
      final sessions = [
        _session(id: 's1', gameId: 'g1', gameName: 'Chess', durationSeconds: 300, players: [_player('A', rank: 1)]),
        _session(id: 's2', gameId: 'g1', gameName: 'Chess', durationSeconds: 1200, players: [_player('A', rank: 1)]),
      ];
      final stats = StatsService.computeGameStats(sessions);
      expect(stats['g1']!.longestSeconds, 1200);
      expect(stats['g1']!.shortestSeconds, 300);
    });

    test('counts sessions with expansions', () {
      final sessions = [
        _session(id: 's1', gameId: 'g1', gameName: 'Chess', durationSeconds: 600,
            players: [_player('A', rank: 1)], expansionIds: ['exp1']),
        _session(id: 's2', gameId: 'g1', gameName: 'Chess', durationSeconds: 600,
            players: [_player('A', rank: 1)], expansionIds: []),
      ];
      final stats = StatsService.computeGameStats(sessions);
      expect(stats['g1']!.sessionsWithExpansions, 1);
      expect(stats['g1']!.expansionUseCounts['exp1'], 1);
    });
  });

  group('StatsService.computeGlobalStats', () {
    test('returns null for empty sessions', () {
      expect(StatsService.computeGlobalStats([]), isNull);
    });

    test('basic totals', () {
      final sessions = [
        _session(id: 's1', gameId: 'g1', gameName: 'Chess', durationSeconds: 600, players: [_player('A', rank: 1)]),
        _session(id: 's2', gameId: 'g2', gameName: 'Go', durationSeconds: 1200, players: [_player('B', rank: 1)]),
      ];
      final g = StatsService.computeGlobalStats(sessions)!;
      expect(g.totalSessions, 2);
      expect(g.uniqueGames, 2);
      expect(g.totalSeconds, 1800);
      expect(g.avgSeconds, 900);
    });

    test('longest and shortest sessions', () {
      final sessions = [
        _session(id: 's1', gameId: 'g1', gameName: 'Chess', durationSeconds: 300, players: [_player('A', rank: 1)]),
        _session(id: 's2', gameId: 'g1', gameName: 'Chess', durationSeconds: 1200, players: [_player('A', rank: 1)]),
      ];
      final g = StatsService.computeGlobalStats(sessions)!;
      expect(g.longestSession.durationSeconds, 1200);
      expect(g.shortestSession.durationSeconds, 300);
    });

    test('hall of fame sorted by wins', () {
      final sessions = [
        _session(id: 's1', gameId: 'g1', gameName: 'Chess', durationSeconds: 600, players: [
          _player('Alice', rank: 1), _player('Bob', rank: 2),
        ]),
        _session(id: 's2', gameId: 'g1', gameName: 'Chess', durationSeconds: 600, players: [
          _player('Alice', rank: 1), _player('Bob', rank: 2),
        ]),
        _session(id: 's3', gameId: 'g1', gameName: 'Chess', durationSeconds: 600, players: [
          _player('Bob', rank: 1), _player('Alice', rank: 2),
        ]),
      ];
      final g = StatsService.computeGlobalStats(sessions)!;
      expect(g.hallOfFame.first.name, 'Alice');
      expect(g.hallOfFame.first.wins, 2);
    });
  });

  group('StatsService.computePlayerList', () {
    test('sorted by wins desc then sessions desc', () {
      final sessions = [
        _session(id: 's1', gameId: 'g1', gameName: 'Chess', durationSeconds: 600, players: [
          _player('Alice', rank: 1), _player('Bob', rank: 2),
        ]),
        _session(id: 's2', gameId: 'g1', gameName: 'Chess', durationSeconds: 600, players: [
          _player('Bob', rank: 1), _player('Alice', rank: 2),
        ]),
        _session(id: 's3', gameId: 'g1', gameName: 'Chess', durationSeconds: 600, players: [
          _player('Bob', rank: 1), _player('Alice', rank: 2),
        ]),
      ];
      final list = StatsService.computePlayerList(sessions);
      expect(list.first.name, 'Bob');
      expect(list.first.wins, 2);
    });
  });

  group('StatsService.computePlayerDetail', () {
    test('counts wins and places correctly', () {
      final sessions = [
        _session(id: 's1', gameId: 'g1', gameName: 'Chess', durationSeconds: 600, players: [
          _player('Alice', rank: 1), _player('Bob', rank: 2), _player('Carol', rank: 3),
        ]),
        _session(id: 's2', gameId: 'g1', gameName: 'Chess', durationSeconds: 600, players: [
          _player('Bob', rank: 1), _player('Alice', rank: 2), _player('Carol', rank: 3),
        ]),
      ];
      final d = StatsService.computePlayerDetail('Alice', sessions);
      expect(d.wins, 1);
      expect(d.secondPlaces, 1);
      expect(d.thirdPlaces, 0);
      expect(d.totalSessions, 2);
      expect(d.winRate, 0.5);
    });

    test('sessions not containing the player are ignored', () {
      final sessions = [
        _session(id: 's1', gameId: 'g1', gameName: 'Chess', durationSeconds: 600, players: [
          _player('Bob', rank: 1),
        ]),
      ];
      final d = StatsService.computePlayerDetail('Alice', sessions);
      expect(d.totalSessions, 0);
      expect(d.wins, 0);
    });
  });

  group('StatsService.computeH2H', () {
    test('counts wins correctly', () {
      final sessions = [
        _session(id: 's1', gameId: 'g1', gameName: 'Chess', durationSeconds: 600, players: [
          _player('Alice', rank: 1), _player('Bob', rank: 2),
        ]),
        _session(id: 's2', gameId: 'g1', gameName: 'Chess', durationSeconds: 600, players: [
          _player('Bob', rank: 1), _player('Alice', rank: 2),
        ]),
      ];
      final h = StatsService.computeH2H('Alice', 'Bob', sessions);
      expect(h.aWins, 1);
      expect(h.bWins, 1);
      expect(h.draws, 0);
      expect(h.total, 2);
    });

    test('draws when both players have same rank', () {
      final sessions = [
        _session(id: 's1', gameId: 'g1', gameName: 'Chess', durationSeconds: 600, players: [
          _player('Alice', rank: 1), _player('Bob', rank: 1),
        ]),
      ];
      final h = StatsService.computeH2H('Alice', 'Bob', sessions);
      expect(h.draws, 1);
      expect(h.aWins, 0);
      expect(h.bWins, 0);
    });

    test('sessions without both players are excluded', () {
      final sessions = [
        _session(id: 's1', gameId: 'g1', gameName: 'Chess', durationSeconds: 600, players: [
          _player('Alice', rank: 1), _player('Carol', rank: 2),
        ]),
      ];
      final h = StatsService.computeH2H('Alice', 'Bob', sessions);
      expect(h.total, 0);
    });
  });
}
