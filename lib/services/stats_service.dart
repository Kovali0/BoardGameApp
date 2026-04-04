import '../models/game_session.dart';
import '../models/board_game.dart';

// ─── Data classes ─────────────────────────────────────────────────────────────

/// Aggregated statistics for a single game across multiple sessions.
class GameStatsData {
  final String id;
  final String name;
  int sessionCount = 0;
  int totalSeconds = 0;
  int totalPlayers = 0;
  DateTime? lastPlayed;
  final List<int> scores = [];
  final Map<String, int> playerWins = {};
  final Map<String, int> playerBestScore = {};
  int? longestSeconds;
  int? shortestSeconds;
  int sessionsWithExpansions = 0;
  final Map<String, int> expansionUseCounts = {};

  GameStatsData({required this.id, required this.name});

  int get avgSeconds => sessionCount > 0 ? totalSeconds ~/ sessionCount : 0;
  double get avgPlayers => sessionCount > 0 ? totalPlayers / sessionCount : 0;
  int? get highestScore =>
      scores.isEmpty ? null : scores.reduce((a, b) => a > b ? a : b);
  int? get lowestScore =>
      scores.isEmpty ? null : scores.reduce((a, b) => a < b ? a : b);
  double? get avgScore => scores.isEmpty
      ? null
      : scores.reduce((a, b) => a + b) / scores.length;

  String? get bestPlayer {
    if (playerWins.isEmpty) return null;
    final maxWins = playerWins.values.reduce((a, b) => a > b ? a : b);
    final tied = playerWins.entries
        .where((e) => e.value == maxWins)
        .map((e) => e.key)
        .toList();
    if (tied.length == 1) return tied.first;
    return tied.reduce((a, b) {
      final scoreA = playerBestScore[a] ?? -1;
      final scoreB = playerBestScore[b] ?? -1;
      if (scoreA != scoreB) return scoreA > scoreB ? a : b;
      return a.compareTo(b) <= 0 ? a : b;
    });
  }
}

/// Per-game stats for one player (used in player detail screen).
class PlayerGameData {
  final String gameId;
  final String name;
  int sessionCount = 0;
  int wins = 0;
  int secondPlaces = 0;
  int thirdPlaces = 0;
  final List<int> scores = [];

  PlayerGameData({required this.gameId, required this.name});

  double get winRate => sessionCount > 0 ? wins / sessionCount : 0;
  int? get highestScore =>
      scores.isEmpty ? null : scores.reduce((a, b) => a > b ? a : b);
  double? get avgScore => scores.isEmpty
      ? null
      : scores.reduce((a, b) => a + b) / scores.length;
}

/// Result of [StatsService.computeGlobalStats].
class GlobalStatsData {
  final int totalSessions;
  final int uniqueGames;
  final int totalSeconds;
  final int avgSeconds;
  final GameSession longestSession;
  final GameSession shortestSession;
  final List<({String name, int count, int seconds})> topGamesByCount;
  final List<({String name, int wins})> hallOfFame;
  final List<({List<String> players, int sessions, int wins})> bestTeams;

  const GlobalStatsData({
    required this.totalSessions,
    required this.uniqueGames,
    required this.totalSeconds,
    required this.avgSeconds,
    required this.longestSession,
    required this.shortestSession,
    required this.topGamesByCount,
    required this.hallOfFame,
    required this.bestTeams,
  });
}

/// Result of [StatsService.computePlayerDetail].
class PlayerDetailStats {
  final int totalSessions;
  final int uniqueGames;
  final int wins;
  final int secondPlaces;
  final int thirdPlaces;
  final int totalSeconds;
  final double winRate;
  final String? mostPlayedName;
  final List<PlayerGameData> gameBreakdown;
  final String? bestPartner;
  final double bestPartnerWinRate;
  final int bestPartnerSessions;
  final String? worstPartner;
  final double worstPartnerWinRate;
  final int worstPartnerSessions;

  const PlayerDetailStats({
    required this.totalSessions,
    required this.uniqueGames,
    required this.wins,
    required this.secondPlaces,
    required this.thirdPlaces,
    required this.totalSeconds,
    required this.winRate,
    required this.mostPlayedName,
    required this.gameBreakdown,
    required this.bestPartner,
    required this.bestPartnerWinRate,
    required this.bestPartnerSessions,
    required this.worstPartner,
    required this.worstPartnerWinRate,
    required this.worstPartnerSessions,
  });
}

/// Result of [StatsService.computeH2H].
class H2HStats {
  final int aWins;
  final int bWins;
  final int draws;
  final List<({String name, int aWins, int bWins, int draws})> byGame;

  const H2HStats({
    required this.aWins,
    required this.bWins,
    required this.draws,
    required this.byGame,
  });

  int get total => aWins + bWins + draws;
}

// ─── Service ──────────────────────────────────────────────────────────────────

/// Pure computation functions for statistics screens. No Flutter dependencies.
class StatsService {
  StatsService._();

  /// Aggregates per-game stats from [sessions].
  /// Returns a map of gameId → [GameStatsData], sorted by session count desc.
  /// If [allGames] is provided, expansion games will also get their own stat entries.
  static Map<String, GameStatsData> computeGameStats(
      List<GameSession> sessions, [List<BoardGame> allGames = const []]) {
    final statsMap = <String, GameStatsData>{};
    final expansionNameMap = <String, String>{};
    
    // Build a map of expansion IDs to names for quick lookup
    for (final game in allGames) {
      if (game.isExpansion) {
        expansionNameMap[game.id] = game.name;
      }
    }

    for (final sess in sessions) {
      final data = statsMap.putIfAbsent(
          sess.gameId, () => GameStatsData(id: sess.gameId, name: sess.gameName));
      data.sessionCount++;
      data.totalSeconds += sess.durationSeconds;
      data.totalPlayers += sess.players.length;
      if (data.lastPlayed == null || sess.startTime.isAfter(data.lastPlayed!)) {
        data.lastPlayed = sess.startTime;
      }
      if (data.longestSeconds == null ||
          sess.durationSeconds > data.longestSeconds!) {
        data.longestSeconds = sess.durationSeconds;
      }
      if (data.shortestSeconds == null ||
          sess.durationSeconds < data.shortestSeconds!) {
        data.shortestSeconds = sess.durationSeconds;
      }
      for (final p in sess.players) {
        if (p.score != null) {
          data.scores.add(p.score!);
          final prev = data.playerBestScore[p.playerName];
          if (prev == null || p.score! > prev) {
            data.playerBestScore[p.playerName] = p.score!;
          }
        }
        if (p.rank == 1) {
          data.playerWins[p.playerName] =
              (data.playerWins[p.playerName] ?? 0) + 1;
        }
      }
      if (sess.expansionIds.isNotEmpty) data.sessionsWithExpansions++;
      for (final expId in sess.expansionIds) {
        data.expansionUseCounts[expId] =
            (data.expansionUseCounts[expId] ?? 0) + 1;

        // Also create/update stats for the expansion itself
        final expName = expansionNameMap[expId] ?? expId;
        final expData = statsMap.putIfAbsent(expId,
            () => GameStatsData(id: expId, name: expName));
        expData.sessionCount++;
        expData.totalSeconds += sess.durationSeconds;
        expData.totalPlayers += sess.players.length;
        if (expData.lastPlayed == null ||
            sess.startTime.isAfter(expData.lastPlayed!)) {
          expData.lastPlayed = sess.startTime;
        }
        if (expData.longestSeconds == null ||
            sess.durationSeconds > expData.longestSeconds!) {
          expData.longestSeconds = sess.durationSeconds;
        }
        if (expData.shortestSeconds == null ||
            sess.durationSeconds < expData.shortestSeconds!) {
          expData.shortestSeconds = sess.durationSeconds;
        }
        for (final p in sess.players) {
          if (p.score != null) {
            expData.scores.add(p.score!);
            final prev = expData.playerBestScore[p.playerName];
            if (prev == null || p.score! > prev) {
              expData.playerBestScore[p.playerName] = p.score!;
            }
          }
          if (p.rank == 1) {
            expData.playerWins[p.playerName] =
                (expData.playerWins[p.playerName] ?? 0) + 1;
          }
        }
      }
    }
    return statsMap;
  }

  /// Computes aggregated global statistics from [sessions].
  /// Returns null when [sessions] is empty.
  static GlobalStatsData? computeGlobalStats(List<GameSession> sessions) {
    if (sessions.isEmpty) return null;

    final totalSeconds =
        sessions.fold(0, (sum, s) => sum + s.durationSeconds);

    final gameMap = <String, ({String name, int count, int seconds})>{};
    for (final sess in sessions) {
      final prev = gameMap[sess.gameId];
      gameMap[sess.gameId] = prev == null
          ? (name: sess.gameName, count: 1, seconds: sess.durationSeconds)
          : (
              name: prev.name,
              count: prev.count + 1,
              seconds: prev.seconds + sess.durationSeconds,
            );
    }
    final topGames = gameMap.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final winMap = <String, int>{};
    for (final sess in sessions) {
      for (final p in sess.players) {
        if (p.rank == 1) {
          winMap[p.playerName] = (winMap[p.playerName] ?? 0) + 1;
        }
      }
    }
    final hallOfFame = winMap.entries
        .map((e) => (name: e.key, wins: e.value))
        .toList()
      ..sort((a, b) => b.wins.compareTo(a.wins));

    final teamStats =
        <String, ({List<String> players, int sessions, int wins})>{};
    for (final sess in sessions) {
      final teamPlayers = <String, List<String>>{};
      for (final p in sess.players) {
        if (p.teamName != null && p.teamName!.isNotEmpty) {
          teamPlayers.putIfAbsent(p.teamName!, () => []).add(p.playerName);
        }
      }
      for (final entry in teamPlayers.entries) {
        final sorted = [...entry.value]..sort();
        final key = sorted.join(',');
        final isWin = sess.players
            .where((p) => p.teamName == entry.key)
            .any((p) => p.rank == 1);
        final prev = teamStats[key];
        teamStats[key] = (
          players: sorted,
          sessions: (prev?.sessions ?? 0) + 1,
          wins: (prev?.wins ?? 0) + (isWin ? 1 : 0),
        );
      }
    }
    final bestTeams = (teamStats.values.toList()
          ..sort((a, b) {
            final cmp = b.wins.compareTo(a.wins);
            return cmp != 0 ? cmp : b.sessions.compareTo(a.sessions);
          }))
        .take(3)
        .toList();

    return GlobalStatsData(
      totalSessions: sessions.length,
      uniqueGames: gameMap.length,
      totalSeconds: totalSeconds,
      avgSeconds: totalSeconds ~/ sessions.length,
      longestSession:
          sessions.reduce((a, b) => a.durationSeconds > b.durationSeconds ? a : b),
      shortestSession:
          sessions.reduce((a, b) => a.durationSeconds < b.durationSeconds ? a : b),
      topGamesByCount: topGames,
      hallOfFame: hallOfFame,
      bestTeams: bestTeams,
    );
  }

  /// Returns a sorted player list (by wins desc, then sessions desc).
  static List<({String name, int sessions, int wins})> computePlayerList(
      List<GameSession> sessions) {
    final playerMap = <String, ({int sessions, int wins})>{};
    for (final sess in sessions) {
      for (final p in sess.players) {
        final prev = playerMap[p.playerName];
        playerMap[p.playerName] = (
          sessions: (prev?.sessions ?? 0) + 1,
          wins: (prev?.wins ?? 0) + (p.rank == 1 ? 1 : 0),
        );
      }
    }
    return playerMap.entries
        .map((e) => (name: e.key, sessions: e.value.sessions, wins: e.value.wins))
        .toList()
      ..sort((a, b) {
        final cmp = b.wins.compareTo(a.wins);
        return cmp != 0 ? cmp : b.sessions.compareTo(a.sessions);
      });
  }

  /// Computes detailed stats for a single player.
  static PlayerDetailStats computePlayerDetail(
      String playerName, List<GameSession> sessions) {
    int wins = 0, secondPlaces = 0, thirdPlaces = 0, totalSeconds = 0;
    final gameMap = <String, PlayerGameData>{};

    for (final sess in sessions) {
      final match =
          sess.players.where((p) => p.playerName == playerName).firstOrNull;
      if (match == null) continue;
      final p = match;

      totalSeconds += sess.durationSeconds;
      if (p.rank == 1) wins++;
      else if (p.rank == 2) secondPlaces++;
      else if (p.rank == 3) thirdPlaces++;

      final gd = gameMap.putIfAbsent(
          sess.gameId, () => PlayerGameData(gameId: sess.gameId, name: sess.gameName));
      gd.sessionCount++;
      if (p.rank == 1) gd.wins++;
      else if (p.rank == 2) gd.secondPlaces++;
      else if (p.rank == 3) gd.thirdPlaces++;
      if (p.score != null) gd.scores.add(p.score!);
    }

    final totalSessions =
        gameMap.values.fold(0, (sum, g) => sum + g.sessionCount);
    final winRate = totalSessions > 0 ? wins / totalSessions : 0.0;

    final mostPlayedName = gameMap.isEmpty
        ? null
        : gameMap.values
            .reduce((a, b) => a.sessionCount >= b.sessionCount ? a : b)
            .name;

    final gameBreakdown = gameMap.values.toList()
      ..sort((a, b) => b.sessionCount.compareTo(a.sessionCount));

    // Partner stats (team games only)
    final partnerStats = <String, ({int sessions, int wins})>{};
    for (final sess in sessions) {
      final myResult =
          sess.players.where((p) => p.playerName == playerName).firstOrNull;
      if (myResult == null ||
          myResult.teamName == null ||
          myResult.teamName!.isEmpty) continue;
      final myTeam = myResult.teamName!;
      final isWin = myResult.rank == 1;
      for (final p in sess.players) {
        if (p.playerName == playerName) continue;
        if (p.teamName != myTeam) continue;
        final prev = partnerStats[p.playerName];
        partnerStats[p.playerName] = (
          sessions: (prev?.sessions ?? 0) + 1,
          wins: (prev?.wins ?? 0) + (isWin ? 1 : 0),
        );
      }
    }

    String? bestPartner;
    double bestRate = -1;
    int bestSessions = 0;
    String? worstPartner;
    double worstRate = 2.0;
    int worstSessions = 0;
    for (final entry in partnerStats.entries) {
      if (entry.value.sessions < 2) continue;
      final rate = entry.value.wins / entry.value.sessions;
      if (rate > bestRate) {
        bestRate = rate;
        bestPartner = entry.key;
        bestSessions = entry.value.sessions;
      }
      if (rate < worstRate) {
        worstRate = rate;
        worstPartner = entry.key;
        worstSessions = entry.value.sessions;
      }
    }

    return PlayerDetailStats(
      totalSessions: totalSessions,
      uniqueGames: gameMap.length,
      wins: wins,
      secondPlaces: secondPlaces,
      thirdPlaces: thirdPlaces,
      totalSeconds: totalSeconds,
      winRate: winRate,
      mostPlayedName: mostPlayedName,
      gameBreakdown: gameBreakdown,
      bestPartner: bestPartner,
      bestPartnerWinRate: bestRate < 0 ? 0 : bestRate,
      bestPartnerSessions: bestSessions,
      worstPartner: worstPartner,
      worstPartnerWinRate: worstRate > 1 ? 0 : worstRate,
      worstPartnerSessions: worstSessions,
    );
  }

  /// Computes head-to-head stats between two players.
  static H2HStats computeH2H(
      String playerA, String playerB, List<GameSession> sessions) {
    int aWins = 0, bWins = 0, draws = 0;
    final gameMap =
        <String, ({String name, int aWins, int bWins, int draws})>{};

    for (final sess in sessions) {
      final pa =
          sess.players.where((p) => p.playerName == playerA).firstOrNull;
      final pb =
          sess.players.where((p) => p.playerName == playerB).firstOrNull;
      if (pa == null || pb == null) continue;

      final prev = gameMap[sess.gameId] ??
          (name: sess.gameName, aWins: 0, bWins: 0, draws: 0);

      if (pa.rank < pb.rank) {
        aWins++;
        gameMap[sess.gameId] = (
          name: prev.name,
          aWins: prev.aWins + 1,
          bWins: prev.bWins,
          draws: prev.draws
        );
      } else if (pb.rank < pa.rank) {
        bWins++;
        gameMap[sess.gameId] = (
          name: prev.name,
          aWins: prev.aWins,
          bWins: prev.bWins + 1,
          draws: prev.draws
        );
      } else {
        draws++;
        gameMap[sess.gameId] = (
          name: prev.name,
          aWins: prev.aWins,
          bWins: prev.bWins,
          draws: prev.draws + 1
        );
      }
    }

    final byGame = gameMap.values.toList()
      ..sort((a, b) =>
          (b.aWins + b.bWins + b.draws).compareTo(a.aWins + a.bWins + a.draws));

    return H2HStats(
        aWins: aWins, bWins: bWins, draws: draws, byGame: byGame);
  }
}
