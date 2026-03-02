import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/board_game.dart';
import '../../models/game_session.dart';
import '../../providers/game_provider.dart';
import '../../providers/session_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<SessionProvider>().sessions;
    final allGames = context.watch<GameProvider>().games;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Useless statistics'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Games'),
            Tab(text: 'Players'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          sessions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No sessions yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Play some games to see your stats!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : _StatisticsContent(sessions: sessions),
          _GamesStatsContent(sessions: sessions, allGames: allGames),
          _PlayersStatsContent(sessions: sessions),
        ],
      ),
    );
  }
}

// ─── Global Tab ───────────────────────────────────────────────────────────────

class _StatisticsContent extends StatelessWidget {
  final List<GameSession> sessions;

  const _StatisticsContent({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final totalSessions = sessions.length;
    final uniqueGames = sessions.map((s) => s.gameId).toSet().length;
    final totalSeconds = sessions.fold(0, (sum, s) => sum + s.durationSeconds);

    // Top games
    final gameMap = <String, ({String name, int count, int seconds})>{};
    for (final s in sessions) {
      final prev = gameMap[s.gameId];
      if (prev == null) {
        gameMap[s.gameId] = (name: s.gameName, count: 1, seconds: s.durationSeconds);
      } else {
        gameMap[s.gameId] = (
          name: prev.name,
          count: prev.count + 1,
          seconds: prev.seconds + s.durationSeconds,
        );
      }
    }
    final topGames = gameMap.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    // Records
    final longest = sessions.reduce((a, b) => a.durationSeconds > b.durationSeconds ? a : b);
    final shortest = sessions.reduce((a, b) => a.durationSeconds < b.durationSeconds ? a : b);
    final avgSeconds = totalSeconds ~/ totalSessions;

    // Player wins
    final winMap = <String, int>{};
    for (final s in sessions) {
      for (final p in s.players) {
        if (p.rank == 1) {
          winMap[p.playerName] = (winMap[p.playerName] ?? 0) + 1;
        }
      }
    }
    final hallOfFame = winMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overview
        const _SectionHeader('Overview'),
        Row(
          children: [
            Expanded(child: _StatCard(label: 'Sessions', value: '$totalSessions')),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(label: 'Time played', value: _formatSeconds(totalSeconds))),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(label: 'Games', value: '$uniqueGames')),
          ],
        ),
        const SizedBox(height: 20),

        // Top games
        const _SectionHeader('Top Games'),
        Card(
          child: Column(
            children: [
              for (int i = 0; i < topGames.length; i++)
                _GameRankRow(
                  medal: _medal(i),
                  name: topGames[i].name,
                  count: topGames[i].count,
                  seconds: topGames[i].seconds,
                  showDivider: i < topGames.length - 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Records
        const _SectionHeader('Records'),
        Card(
          child: Column(
            children: [
              _RecordRow(
                label: 'Longest session',
                value: '${longest.gameName}  •  ${longest.durationFormatted}',
              ),
              const Divider(height: 1),
              _RecordRow(
                label: 'Shortest session',
                value: '${shortest.gameName}  •  ${shortest.durationFormatted}',
              ),
              const Divider(height: 1),
              _RecordRow(
                label: 'Average duration',
                value: _formatSeconds(avgSeconds),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Hall of fame
        if (hallOfFame.isNotEmpty) ...[
          const _SectionHeader('Player Hall of Fame'),
          Card(
            child: Column(
              children: [
                for (int i = 0; i < hallOfFame.length; i++)
                  _PlayerRow(
                    medal: _medal(i),
                    name: hallOfFame[i].key,
                    wins: hallOfFame[i].value,
                    showDivider: i < hallOfFame.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}

// ─── Games Tab ────────────────────────────────────────────────────────────────

class _GameStatsData {
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

  _GameStatsData({required this.name});

  int get avgSeconds => sessionCount > 0 ? totalSeconds ~/ sessionCount : 0;
  double get avgPlayers => sessionCount > 0 ? totalPlayers / sessionCount : 0;
  int? get highestScore => scores.isEmpty ? null : scores.reduce((a, b) => a > b ? a : b);
  int? get lowestScore => scores.isEmpty ? null : scores.reduce((a, b) => a < b ? a : b);
  double? get avgScore => scores.isEmpty ? null : scores.reduce((a, b) => a + b) / scores.length;

  String? get bestPlayer {
    if (playerWins.isEmpty) return null;
    final maxWins = playerWins.values.reduce((a, b) => a > b ? a : b);
    final tied = playerWins.entries.where((e) => e.value == maxWins).map((e) => e.key).toList();
    if (tied.length == 1) return tied.first;
    // Tiebreak: highest score in this game, then alphabetical
    return tied.reduce((a, b) {
      final scoreA = playerBestScore[a] ?? -1;
      final scoreB = playerBestScore[b] ?? -1;
      if (scoreA != scoreB) return scoreA > scoreB ? a : b;
      return a.compareTo(b) <= 0 ? a : b;
    });
  }
}

class _GamesStatsContent extends StatelessWidget {
  final List<GameSession> sessions;
  final List<BoardGame> allGames;

  const _GamesStatsContent({required this.sessions, required this.allGames});

  @override
  Widget build(BuildContext context) {
    final statsMap = <String, _GameStatsData>{};
    for (final s in sessions) {
      final data = statsMap.putIfAbsent(s.gameId, () => _GameStatsData(name: s.gameName));
      data.sessionCount++;
      data.totalSeconds += s.durationSeconds;
      data.totalPlayers += s.players.length;
      if (data.lastPlayed == null || s.startTime.isAfter(data.lastPlayed!)) {
        data.lastPlayed = s.startTime;
      }
      if (data.longestSeconds == null || s.durationSeconds > data.longestSeconds!) {
        data.longestSeconds = s.durationSeconds;
      }
      if (data.shortestSeconds == null || s.durationSeconds < data.shortestSeconds!) {
        data.shortestSeconds = s.durationSeconds;
      }
      for (final p in s.players) {
        if (p.score != null) {
          data.scores.add(p.score!);
          final prev = data.playerBestScore[p.playerName];
          if (prev == null || p.score! > prev) {
            data.playerBestScore[p.playerName] = p.score!;
          }
        }
        if (p.rank == 1) {
          data.playerWins[p.playerName] = (data.playerWins[p.playerName] ?? 0) + 1;
        }
      }
    }

    final playedGames = statsMap.values.toList()
      ..sort((a, b) => b.sessionCount.compareTo(a.sessionCount));

    final playedIds = statsMap.keys.toSet();
    final neverPlayed = allGames.where((g) => !playedIds.contains(g.id)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (playedGames.isEmpty && neverPlayed.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_esports, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No games yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Add games to your collection!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('d MMM yyyy');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (playedGames.isNotEmpty) ...[
          const _SectionHeader('Played Games'),
          for (final stats in playedGames) ...[
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(stats.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${stats.sessionCount} session${stats.sessionCount == 1 ? '' : 's'}'
                  '${stats.lastPlayed != null ? ' · ${dateFormat.format(stats.lastPlayed!)}' : ''}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => _GameDetailScreen(stats: stats),
                )),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
        ],
        if (neverPlayed.isNotEmpty) ...[
          const _SectionHeader('Never Played'),
          Card(
            child: Column(
              children: [
                for (int i = 0; i < neverPlayed.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            neverPlayed[i].name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Text(
                          'Not played yet',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (i < neverPlayed.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _GameDetailScreen extends StatelessWidget {
  final _GameStatsData stats;

  const _GameDetailScreen({required this.stats});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');
    final bestPlayer = stats.bestPlayer;
    final lastPlayed = stats.lastPlayed;

    return Scaffold(
      appBar: AppBar(title: Text(stats.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Overview ──
          const _SectionHeader('Overview'),
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Sessions', value: '${stats.sessionCount}')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: 'Total time', value: _formatSeconds(stats.totalSeconds))),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: 'Avg time', value: _formatSeconds(stats.avgSeconds))),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _RecordRow(label: 'Avg players', value: stats.avgPlayers.toStringAsFixed(1)),
                if (lastPlayed != null) ...[
                  const Divider(height: 1),
                  _RecordRow(label: 'Last played', value: dateFormat.format(lastPlayed)),
                ],
                if (bestPlayer != null) ...[
                  const Divider(height: 1),
                  _RecordRow(label: 'Best player', value: bestPlayer),
                ],
                if (stats.longestSeconds != null) ...[
                  const Divider(height: 1),
                  _RecordRow(label: 'Longest session', value: _formatSeconds(stats.longestSeconds!)),
                ],
                if (stats.shortestSeconds != null && stats.sessionCount > 1) ...[
                  const Divider(height: 1),
                  _RecordRow(label: 'Shortest session', value: _formatSeconds(stats.shortestSeconds!)),
                ],
              ],
            ),
          ),

          // ── Scores ──
          if (stats.scores.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _SectionHeader('Scores'),
            Card(
              child: Column(
                children: [
                  _RecordRow(label: 'Highest score', value: '${stats.highestScore} pts'),
                  const Divider(height: 1),
                  _RecordRow(label: 'Avg score', value: '${stats.avgScore!.toStringAsFixed(1)} pts'),
                  const Divider(height: 1),
                  _RecordRow(label: 'Lowest score', value: '${stats.lowestScore} pts'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Players Tab ──────────────────────────────────────────────────────────────

class _PlayersStatsContent extends StatelessWidget {
  final List<GameSession> sessions;

  const _PlayersStatsContent({required this.sessions});

  @override
  Widget build(BuildContext context) {
    // Build lightweight summary just for the list
    final playerMap = <String, ({int sessions, int wins})>{};
    for (final s in sessions) {
      for (final p in s.players) {
        final prev = playerMap[p.playerName];
        playerMap[p.playerName] = (
          sessions: (prev?.sessions ?? 0) + 1,
          wins: (prev?.wins ?? 0) + (p.rank == 1 ? 1 : 0),
        );
      }
    }

    final players = playerMap.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.wins.compareTo(a.value.wins);
        return cmp != 0 ? cmp : b.value.sessions.compareTo(a.value.sessions);
      });

    if (players.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No players yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Play some games to see player stats!', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: players.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final name = players[i].key;
        final stats = players[i].value;
        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${stats.sessions} session${stats.sessions == 1 ? '' : 's'} · '
              '${stats.wins} win${stats.wins == 1 ? '' : 's'}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => _PlayerDetailScreen(
                playerName: name,
                sessions: sessions,
              ),
            )),
          ),
        );
      },
    );
  }
}

// ─── Player Detail Screen ─────────────────────────────────────────────────────

class _PlayerGameData {
  final String name;
  int sessionCount = 0;
  int wins = 0;
  int secondPlaces = 0;
  int thirdPlaces = 0;
  final List<int> scores = [];

  _PlayerGameData({required this.name});

  double get winRate => sessionCount > 0 ? wins / sessionCount : 0;
  int? get highestScore => scores.isEmpty ? null : scores.reduce((a, b) => a > b ? a : b);
  double? get avgScore =>
      scores.isEmpty ? null : scores.reduce((a, b) => a + b) / scores.length;
}

class _PlayerDetailScreen extends StatelessWidget {
  final String playerName;
  final List<GameSession> sessions;

  const _PlayerDetailScreen({required this.playerName, required this.sessions});

  @override
  Widget build(BuildContext context) {
    int wins = 0, secondPlaces = 0, thirdPlaces = 0, totalSeconds = 0;
    final gameMap = <String, _PlayerGameData>{};

    for (final s in sessions) {
      final match = s.players.where((p) => p.playerName == playerName);
      if (match.isEmpty) continue;
      final p = match.first;

      totalSeconds += s.durationSeconds;
      if (p.rank == 1) {
        wins++;
      } else if (p.rank == 2) {
        secondPlaces++;
      } else if (p.rank == 3) {
        thirdPlaces++;
      }

      final gd = gameMap.putIfAbsent(s.gameId, () => _PlayerGameData(name: s.gameName));
      gd.sessionCount++;
      if (p.rank == 1) {
        gd.wins++;
      } else if (p.rank == 2) {
        gd.secondPlaces++;
      } else if (p.rank == 3) {
        gd.thirdPlaces++;
      }
      if (p.score != null) { gd.scores.add(p.score!); }
    }

    final totalSessions = gameMap.values.fold(0, (sum, g) => sum + g.sessionCount);
    final uniqueGames = gameMap.length;
    final winRate = totalSessions > 0 ? wins / totalSessions : 0.0;

    String? mostPlayed;
    if (gameMap.isNotEmpty) {
      mostPlayed = gameMap.values
          .reduce((a, b) => a.sessionCount >= b.sessionCount ? a : b)
          .name;
    }

    final games = gameMap.values.toList()
      ..sort((a, b) => b.sessionCount.compareTo(a.sessionCount));

    return Scaffold(
      appBar: AppBar(title: Text(playerName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Section 1: Overview ──
          const _SectionHeader('Overview'),
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Sessions', value: '$totalSessions')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: 'Wins', value: '$wins')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: 'Win rate', value: '${(winRate * 100).round()}%')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _StatCard(label: '2nd places', value: '$secondPlaces')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: '3rd places', value: '$thirdPlaces')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: 'Games', value: '$uniqueGames')),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _RecordRow(label: 'Total time', value: _formatSeconds(totalSeconds)),
                if (mostPlayed != null) ...[
                  const Divider(height: 1),
                  _RecordRow(label: 'Most played', value: mostPlayed),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Section 2: Game Breakdown ──
          if (games.isNotEmpty) ...[
            const _SectionHeader('Game Breakdown'),
            for (final game in games) ...[
              _PlayerGameCard(data: game),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

class _PlayerGameCard extends StatelessWidget {
  final _PlayerGameData data;

  const _PlayerGameCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final highScore = data.highestScore;
    final avgScore = data.avgScore;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              data.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(child: _StatCard(label: 'Games', value: '${data.sessionCount}')),
                const SizedBox(width: 8),
                Expanded(child: _StatCard(label: 'Wins', value: '${data.wins}')),
                const SizedBox(width: 8),
                Expanded(child: _StatCard(label: '2nd', value: '${data.secondPlaces}')),
                const SizedBox(width: 8),
                Expanded(child: _StatCard(label: '3rd', value: '${data.thirdPlaces}')),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'Win rate',
                    value: '${(data.winRate * 100).round()}%',
                  ),
                ),
              ],
            ),
          ),
          if (highScore != null || avgScore != null) ...[
            const Divider(height: 1),
            if (highScore != null)
              _RecordRow(label: 'Best score', value: '$highScore pts'),
            if (highScore != null && avgScore != null) const Divider(height: 1),
            if (avgScore != null)
              _RecordRow(label: 'Avg score', value: '${avgScore.toStringAsFixed(1)} pts'),
          ],
        ],
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

String _medal(int index) {
  if (index == 0) return '🥇';
  if (index == 1) return '🥈';
  if (index == 2) return '🥉';
  return '${index + 1}.';
}

String _formatSeconds(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m';
  return '${seconds}s';
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _GameRankRow extends StatelessWidget {
  final String medal;
  final String name;
  final int count;
  final int seconds;
  final bool showDivider;

  const _GameRankRow({
    required this.medal,
    required this.name,
    required this.count,
    required this.seconds,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(medal, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$count session${count == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(width: 8),
              Text(
                _formatSeconds(seconds),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final String medal;
  final String name;
  final int wins;
  final bool showDivider;

  const _PlayerRow({
    required this.medal,
    required this.name,
    required this.wins,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(medal, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$wins win${wins == 1 ? '' : 's'}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}

class _RecordRow extends StatelessWidget {
  final String label;
  final String value;

  const _RecordRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
