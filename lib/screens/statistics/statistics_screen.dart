import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_session.dart';
import '../../providers/session_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessions = context.watch<SessionProvider>().sessions;

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: sessions.isEmpty
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
    );
  }
}

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
