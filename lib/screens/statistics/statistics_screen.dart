import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/board_game.dart';
import '../../models/game_session.dart';
import '../../providers/game_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/session_provider.dart';

// ─── Filter helpers ────────────────────────────────────────────────────────────

List<int> _years(List<GameSession> s) =>
    s.map((x) => x.startTime.year).toSet().toList()..sort((a, b) => b.compareTo(a));

List<int> _months(List<GameSession> s, int year) =>
    s.where((x) => x.startTime.year == year)
     .map((x) => x.startTime.month).toSet().toList()
     ..sort((a, b) => b.compareTo(a));

List<GameSession> _applyFilter(List<GameSession> all, int? year, int? month) {
  if (year == null) return all;
  final byYear = all.where((s) => s.startTime.year == year);
  if (month == null) return byYear.toList();
  return byYear.where((s) => s.startTime.month == month).toList();
}

const _kMonths = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int? _selectedYear;
  int? _selectedMonth;

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

  void _showFilterSheet(BuildContext context, List<GameSession> allSessions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FilterSheet(
        allSessions: allSessions,
        initialYear: _selectedYear,
        initialMonth: _selectedMonth,
        onApply: (year, month) => setState(() {
          _selectedYear = year;
          _selectedMonth = month;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final sessions = context.watch<SessionProvider>().sessions;
    final allGames = context.watch<GameProvider>().games;
    final filteredSessions = _applyFilter(sessions, _selectedYear, _selectedMonth);
    final filterActive = _selectedYear != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.statsTitle),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterSheet(context, sessions),
              ),
              if (filterActive)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: s.statsGlobal),
            Tab(text: s.statsGamesTab),
            Tab(text: s.statsPlayersTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          filteredSessions.isEmpty && allGames.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        s.statsNoSessions,
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.statsPlayGames,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : _StatisticsContent(sessions: filteredSessions, allGames: allGames),
          _GamesStatsContent(sessions: filteredSessions, allGames: allGames),
          _PlayersStatsContent(sessions: filteredSessions),
        ],
      ),
    );
  }
}

// ─── Global Tab ───────────────────────────────────────────────────────────────

class _StatisticsContent extends StatelessWidget {
  final List<GameSession> sessions;
  final List<BoardGame> allGames;

  const _StatisticsContent({required this.sessions, required this.allGames});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final playedCount = allGames.where((g) => g.hasBeenPlayed).length;
    final unplayedCount = allGames.length - playedCount;

    // Session-based widgets — only built when sessions exist (avoids .reduce crash)
    List<Widget> sessionWidgets = [];
    if (sessions.isNotEmpty) {
      final totalSessions = sessions.length;
      final uniqueGames = sessions.map((sess) => sess.gameId).toSet().length;
      final totalSeconds = sessions.fold(0, (sum, sess) => sum + sess.durationSeconds);

      final gameMap = <String, ({String name, int count, int seconds})>{};
      for (final sess in sessions) {
        final prev = gameMap[sess.gameId];
        if (prev == null) {
          gameMap[sess.gameId] = (name: sess.gameName, count: 1, seconds: sess.durationSeconds);
        } else {
          gameMap[sess.gameId] = (
            name: prev.name,
            count: prev.count + 1,
            seconds: prev.seconds + sess.durationSeconds,
          );
        }
      }
      final topGames = gameMap.values.toList()
        ..sort((a, b) => b.count.compareTo(a.count));

      final longest = sessions.reduce((a, b) => a.durationSeconds > b.durationSeconds ? a : b);
      final shortest = sessions.reduce((a, b) => a.durationSeconds < b.durationSeconds ? a : b);
      final avgSeconds = totalSeconds ~/ totalSessions;

      final winMap = <String, int>{};
      for (final sess in sessions) {
        for (final p in sess.players) {
          if (p.rank == 1) {
            winMap[p.playerName] = (winMap[p.playerName] ?? 0) + 1;
          }
        }
      }
      final hallOfFame = winMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      sessionWidgets = [
        _SectionHeader(s.statsOverview),
        Row(
          children: [
            Expanded(child: _StatCard(label: s.statsSessions, value: '$totalSessions')),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(label: s.statsTimePlayed, value: _formatSeconds(totalSeconds))),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(label: s.statsGames, value: '$uniqueGames')),
          ],
        ),
        const SizedBox(height: 20),
        _SectionHeader(s.statsTopGames),
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
        _SectionHeader(s.statsRecords),
        Card(
          child: Column(
            children: [
              _RecordRow(
                label: s.statsLongest,
                value: '${longest.gameName}  •  ${longest.durationFormatted}',
              ),
              const Divider(height: 1),
              _RecordRow(
                label: s.statsShortest,
                value: '${shortest.gameName}  •  ${shortest.durationFormatted}',
              ),
              const Divider(height: 1),
              _RecordRow(
                label: s.statsAvgDuration,
                value: _formatSeconds(avgSeconds),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (hallOfFame.isNotEmpty) ...[
          _SectionHeader(s.statsHallOfFame),
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
      ];
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (allGames.isNotEmpty) ...[
          _SectionHeader(s.statsCollection),
          _CollectionChart(played: playedCount, unplayed: unplayedCount),
          const SizedBox(height: 20),
        ],
        if (sessions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                s.statsPlayGames,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
        if (sessions.isNotEmpty) ...sessionWidgets,
      ],
    );
  }
}

// ─── Collection Chart ─────────────────────────────────────────────────────────

class _CollectionChart extends StatelessWidget {
  final int played;
  final int unplayed;

  const _CollectionChart({required this.played, required this.unplayed});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final total = played + unplayed;
    final pct = total > 0 ? (played / total * 100).round() : 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(90, 90),
                    painter: _DonutPainter(played: played, total: total),
                  ),
                  Text(
                    '$pct%',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegendItem(color: Colors.green, label: s.statsPlayed, count: played),
                  const SizedBox(height: 12),
                  _LegendItem(color: Colors.amber.shade700, label: s.statsUnplayed, count: unplayed),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final int played;
  final int total;

  _DonutPainter({required this.played, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const strokeWidth = 16.0;
    const startAngle = -pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Unplayed background ring
    paint.color = Colors.amber.shade700;
    canvas.drawArc(rect, startAngle, 2 * pi, false, paint);

    // Played foreground arc
    if (played > 0 && total > 0) {
      paint.color = Colors.green;
      canvas.drawArc(rect, startAngle, 2 * pi * played / total, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.played != played || old.total != total;
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int count;

  const _LegendItem({required this.color, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
        const Spacer(),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
  int sessionsWithExpansions = 0;
  final Map<String, int> expansionUseCounts = {};

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
    final s = context.watch<LanguageProvider>().strings;
    final statsMap = <String, _GameStatsData>{};
    for (final sess in sessions) {
      final data = statsMap.putIfAbsent(sess.gameId, () => _GameStatsData(name: sess.gameName));
      data.sessionCount++;
      data.totalSeconds += sess.durationSeconds;
      data.totalPlayers += sess.players.length;
      if (data.lastPlayed == null || sess.startTime.isAfter(data.lastPlayed!)) {
        data.lastPlayed = sess.startTime;
      }
      if (data.longestSeconds == null || sess.durationSeconds > data.longestSeconds!) {
        data.longestSeconds = sess.durationSeconds;
      }
      if (data.shortestSeconds == null || sess.durationSeconds < data.shortestSeconds!) {
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
          data.playerWins[p.playerName] = (data.playerWins[p.playerName] ?? 0) + 1;
        }
      }
      if (sess.expansionIds.isNotEmpty) data.sessionsWithExpansions++;
      for (final expId in sess.expansionIds) {
        data.expansionUseCounts[expId] =
            (data.expansionUseCounts[expId] ?? 0) + 1;
      }
    }

    final playedGames = statsMap.values.toList()
      ..sort((a, b) => b.sessionCount.compareTo(a.sessionCount));

    final playedIds = statsMap.keys.toSet();
    final neverPlayed = allGames.where((g) => !playedIds.contains(g.id)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (playedGames.isEmpty && neverPlayed.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sports_esports, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(s.statsNoGames, style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(s.statsAddGames, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('d MMM yyyy');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (playedGames.isNotEmpty) ...[
          _SectionHeader(s.statsPlayedGames),
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
                  builder: (_) => _GameDetailScreen(stats: stats, allGames: allGames),
                )),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
        ],
        if (neverPlayed.isNotEmpty) ...[
          _SectionHeader(s.statsNeverPlayed),
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
                        Text(
                          s.statsNotPlayedYet,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
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
  final List<BoardGame> allGames;

  const _GameDetailScreen({required this.stats, required this.allGames});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final dateFormat = DateFormat('d MMM yyyy');
    final bestPlayer = stats.bestPlayer;
    final lastPlayed = stats.lastPlayed;

    return Scaffold(
      appBar: AppBar(title: Text(stats.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Overview ──
          _SectionHeader(s.statsOverview),
          Row(
            children: [
              Expanded(child: _StatCard(label: s.statsSessions, value: '${stats.sessionCount}')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: s.statsTotalTime, value: _formatSeconds(stats.totalSeconds))),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: s.statsAvgDuration, value: _formatSeconds(stats.avgSeconds))),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _RecordRow(label: s.statsAvgPlayers, value: stats.avgPlayers.toStringAsFixed(1)),
                if (lastPlayed != null) ...[
                  const Divider(height: 1),
                  _RecordRow(label: s.statsLastPlayed, value: dateFormat.format(lastPlayed)),
                ],
                if (bestPlayer != null) ...[
                  const Divider(height: 1),
                  _RecordRow(label: s.statsBestPlayer, value: bestPlayer),
                ],
                if (stats.longestSeconds != null) ...[
                  const Divider(height: 1),
                  _RecordRow(label: s.statsLongest, value: _formatSeconds(stats.longestSeconds!)),
                ],
                if (stats.shortestSeconds != null && stats.sessionCount > 1) ...[
                  const Divider(height: 1),
                  _RecordRow(label: s.statsShortest, value: _formatSeconds(stats.shortestSeconds!)),
                ],
                if (stats.sessionsWithExpansions > 0) ...[
                  const Divider(height: 1),
                  _RecordRow(
                    label: s.statsSessionsWithExpansions,
                    value:
                        '${stats.sessionsWithExpansions} / ${stats.sessionCount} '
                        '(${(stats.sessionsWithExpansions / stats.sessionCount * 100).round()}%)',
                  ),
                ],
                if (stats.expansionUseCounts.isNotEmpty) ...[
                  const Divider(height: 1),
                  _RecordRow(
                    label: s.statsMostUsedExpansion,
                    value: () {
                      final maxCount = stats.expansionUseCounts.values
                          .reduce((a, b) => a > b ? a : b);
                      final topId = stats.expansionUseCounts.entries
                          .firstWhere((e) => e.value == maxCount)
                          .key;
                      return allGames
                              .where((g) => g.id == topId)
                              .firstOrNull
                              ?.name ??
                          '—';
                    }(),
                  ),
                ],
              ],
            ),
          ),

          // ── Scores ──
          if (stats.scores.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionHeader(s.statsRecords),
            Card(
              child: Column(
                children: [
                  _RecordRow(label: s.statsHighestScore, value: '${stats.highestScore} pts'),
                  const Divider(height: 1),
                  _RecordRow(label: s.statsAvgScore, value: '${stats.avgScore!.toStringAsFixed(1)} pts'),
                  const Divider(height: 1),
                  _RecordRow(label: s.statsLowestScore, value: '${stats.lowestScore} pts'),
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

class _PlayersStatsContent extends StatefulWidget {
  final List<GameSession> sessions;
  const _PlayersStatsContent({required this.sessions});

  @override
  State<_PlayersStatsContent> createState() => _PlayersStatsContentState();
}

class _PlayersStatsContentState extends State<_PlayersStatsContent> {
  String? _playerA;
  String? _playerB;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final playerMap = <String, ({int sessions, int wins})>{};
    for (final sess in widget.sessions) {
      for (final p in sess.players) {
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(s.statsNoPlayers, style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(s.statsPlayForPlayerStats, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final playerNames = players.map((e) => e.key).toList();
    // Reset selections if player no longer in list
    if (_playerA != null && !playerNames.contains(_playerA)) _playerA = null;
    if (_playerB != null && !playerNames.contains(_playerB)) _playerB = null;

    final canCompare = _playerA != null && _playerB != null && _playerA != _playerB;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Head-to-head picker ──
        if (players.length >= 2) ...[
          _SectionHeader(s.statsHeadToHead),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _playerA,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            hintText: s.statsSelectPlayer,
                          ),
                          hint: Text(s.statsSelectPlayer, style: const TextStyle(fontSize: 13)),
                          isExpanded: true,
                          items: playerNames
                              .where((n) => n != _playerB)
                              .map((n) => DropdownMenuItem(value: n, child: Text(n, overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (v) => setState(() => _playerA = v),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'VS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _playerB,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            hintText: s.statsSelectPlayer,
                          ),
                          hint: Text(s.statsSelectPlayer, style: const TextStyle(fontSize: 13)),
                          isExpanded: true,
                          items: playerNames
                              .where((n) => n != _playerA)
                              .map((n) => DropdownMenuItem(value: n, child: Text(n, overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (v) => setState(() => _playerB = v),
                        ),
                      ),
                    ],
                  ),
                  if (canCompare) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => _HeadToHeadScreen(
                            playerA: _playerA!,
                            playerB: _playerB!,
                            sessions: widget.sessions,
                          ),
                        )),
                        icon: const Icon(Icons.compare_arrows, size: 18),
                        label: Text(s.statsViewRivalry),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Player list ──
        for (int i = 0; i < players.length; i++) ...[
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text(players[i].key, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${players[i].value.sessions} session${players[i].value.sessions == 1 ? '' : 's'} · '
                '${players[i].value.wins} win${players[i].value.wins == 1 ? '' : 's'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => _PlayerDetailScreen(
                  playerName: players[i].key,
                  sessions: widget.sessions,
                ),
              )),
            ),
          ),
          if (i < players.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// ─── Head-to-head Screen ──────────────────────────────────────────────────────

class _HeadToHeadScreen extends StatelessWidget {
  final String playerA, playerB;
  final List<GameSession> sessions;

  const _HeadToHeadScreen({
    required this.playerA,
    required this.playerB,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final colorScheme = Theme.of(context).colorScheme;

    // ── Compute H2H data ──
    int aWins = 0, bWins = 0, draws = 0;
    final gameMap = <String, ({String name, int aWins, int bWins, int draws})>{};

    for (final sess in sessions) {
      final pa = sess.players.where((p) => p.playerName == playerA).firstOrNull;
      final pb = sess.players.where((p) => p.playerName == playerB).firstOrNull;
      if (pa == null || pb == null) continue;

      final prev = gameMap[sess.gameId] ??
          (name: sess.gameName, aWins: 0, bWins: 0, draws: 0);

      if (pa.rank < pb.rank) {
        aWins++;
        gameMap[sess.gameId] = (name: prev.name, aWins: prev.aWins + 1, bWins: prev.bWins, draws: prev.draws);
      } else if (pb.rank < pa.rank) {
        bWins++;
        gameMap[sess.gameId] = (name: prev.name, aWins: prev.aWins, bWins: prev.bWins + 1, draws: prev.draws);
      } else {
        draws++;
        gameMap[sess.gameId] = (name: prev.name, aWins: prev.aWins, bWins: prev.bWins, draws: prev.draws + 1);
      }
    }

    final totalTogether = aWins + bWins + draws;

    if (totalTogether == 0) {
      return Scaffold(
        appBar: AppBar(title: Text('$playerA vs $playerB')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sports_kabaddi, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  s.statsNeverPlayedTogether,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final games = gameMap.values.toList()
      ..sort((a, b) =>
          (b.aWins + b.bWins + b.draws).compareTo(a.aWins + a.bWins + a.draws));

    final aLeading = aWins > bWins;
    final bLeading = bWins > aWins;

    return Scaffold(
      appBar: AppBar(title: Text('$playerA vs $playerB')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Names header ──
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      playerA,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: aLeading ? colorScheme.primary : null,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: colorScheme.outline,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      playerB,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: bLeading ? colorScheme.primary : null,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Win counts ──
          Row(
            children: [
              Expanded(child: _StatCard(label: playerA, value: '$aWins')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: s.statsDraws, value: '$draws')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: playerB, value: '$bWins')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: s.statsTogetherSessions, value: '$totalTogether')),
            ],
          ),
          const SizedBox(height: 12),

          // ── Visual bar ──
          _H2HBar(aWins: aWins, bWins: bWins, draws: draws, colorScheme: colorScheme),
          const SizedBox(height: 8),

          // ── Bar legend ──
          Row(
            children: [
              _H2HLegend(color: colorScheme.primary, label: playerA),
              if (draws > 0) ...[
                const SizedBox(width: 12),
                _H2HLegend(color: Colors.grey.shade400, label: s.statsDraws),
              ],
              const Spacer(),
              _H2HLegend(color: colorScheme.secondary, label: playerB),
            ],
          ),
          const SizedBox(height: 24),

          // ── Per-game breakdown ──
          _SectionHeader(s.statsGameBreakdown),
          for (final game in games) ...[
            _H2HGameCard(game: game, playerA: playerA, playerB: playerB),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _H2HBar extends StatelessWidget {
  final int aWins, bWins, draws;
  final ColorScheme colorScheme;

  const _H2HBar({
    required this.aWins,
    required this.bWins,
    required this.draws,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final total = aWins + bWins + draws;
    if (total == 0) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 22,
        child: Row(
          children: [
            if (aWins > 0)
              Expanded(
                flex: (aWins * 1000 ~/ total),
                child: Container(color: colorScheme.primary),
              ),
            if (draws > 0)
              Expanded(
                flex: (draws * 1000 ~/ total),
                child: Container(color: Colors.grey.shade400),
              ),
            if (bWins > 0)
              Expanded(
                flex: (bWins * 1000 ~/ total),
                child: Container(color: colorScheme.secondary),
              ),
          ],
        ),
      ),
    );
  }
}

class _H2HLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _H2HLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _H2HGameCard extends StatelessWidget {
  final ({String name, int aWins, int bWins, int draws}) game;
  final String playerA, playerB;

  const _H2HGameCard({required this.game, required this.playerA, required this.playerB});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final total = game.aWins + game.bWins + game.draws;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(game.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _StatCard(label: playerA, value: '${game.aWins}')),
                const SizedBox(width: 6),
                Expanded(child: _StatCard(label: s.statsDraws, value: '${game.draws}')),
                const SizedBox(width: 6),
                Expanded(child: _StatCard(label: playerB, value: '${game.bWins}')),
                const SizedBox(width: 6),
                Expanded(child: _StatCard(label: s.statsTogetherSessions, value: '$total')),
              ],
            ),
          ],
        ),
      ),
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
    final s = context.watch<LanguageProvider>().strings;
    int wins = 0, secondPlaces = 0, thirdPlaces = 0, totalSeconds = 0;
    final gameMap = <String, _PlayerGameData>{};

    for (final sess in sessions) {
      final match = sess.players.where((p) => p.playerName == playerName);
      if (match.isEmpty) continue;
      final p = match.first;

      totalSeconds += sess.durationSeconds;
      if (p.rank == 1) {
        wins++;
      } else if (p.rank == 2) {
        secondPlaces++;
      } else if (p.rank == 3) {
        thirdPlaces++;
      }

      final gd = gameMap.putIfAbsent(sess.gameId, () => _PlayerGameData(name: sess.gameName));
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
          _SectionHeader(s.statsOverview),
          Row(
            children: [
              Expanded(child: _StatCard(label: s.statsSessions, value: '$totalSessions')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: s.statsWins, value: '$wins')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: s.statsWinRate, value: '${(winRate * 100).round()}%')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _StatCard(label: s.statsSecondPlaces, value: '$secondPlaces')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: s.statsThirdPlaces, value: '$thirdPlaces')),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(label: s.statsGames, value: '$uniqueGames')),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _RecordRow(label: s.statsTotalTime, value: _formatSeconds(totalSeconds)),
                if (mostPlayed != null) ...[
                  const Divider(height: 1),
                  _RecordRow(label: s.statsMostPlayed, value: mostPlayed),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Section 2: Game Breakdown ──
          if (games.isNotEmpty) ...[
            _SectionHeader(s.statsGameBreakdown),
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
    final s = context.watch<LanguageProvider>().strings;
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
                Expanded(child: _StatCard(label: s.statsGames, value: '${data.sessionCount}')),
                const SizedBox(width: 8),
                Expanded(child: _StatCard(label: s.statsWins, value: '${data.wins}')),
                const SizedBox(width: 8),
                Expanded(child: _StatCard(label: s.statsSecondPlaces, value: '${data.secondPlaces}')),
                const SizedBox(width: 8),
                Expanded(child: _StatCard(label: s.statsThirdPlaces, value: '${data.thirdPlaces}')),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: s.statsWinRate,
                    value: '${(data.winRate * 100).round()}%',
                  ),
                ),
              ],
            ),
          ),
          if (highScore != null || avgScore != null) ...[
            const Divider(height: 1),
            if (highScore != null)
              _RecordRow(label: s.statsBestScore, value: '$highScore pts'),
            if (highScore != null && avgScore != null) const Divider(height: 1),
            if (avgScore != null)
              _RecordRow(label: s.statsAvgScore, value: '${avgScore.toStringAsFixed(1)} pts'),
          ],
        ],
      ),
    );
  }
}

// ─── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final List<GameSession> allSessions;
  final int? initialYear;
  final int? initialMonth;
  final void Function(int? year, int? month) onApply;

  const _FilterSheet({
    required this.allSessions,
    required this.initialYear,
    required this.initialMonth,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  int? _year;
  int? _month;

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
    _month = widget.initialMonth;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final years = _years(widget.allSessions);
    final months = _year == null ? <int>[] : _months(widget.allSessions, _year!);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.statsFilterTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(s.filterYear, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilterChip(
                label: Text(s.filterAll),
                selected: _year == null,
                onSelected: (_) => setState(() { _year = null; _month = null; }),
              ),
              for (final y in years)
                FilterChip(
                  label: Text('$y'),
                  selected: _year == y,
                  onSelected: (_) => setState(() { _year = y; _month = null; }),
                ),
            ],
          ),
          if (_year != null) ...[
            const SizedBox(height: 12),
            Text(s.filterMonth, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilterChip(
                  label: Text(s.filterAll),
                  selected: _month == null,
                  onSelected: (_) => setState(() => _month = null),
                ),
                for (final m in months)
                  FilterChip(
                    label: Text(_kMonths[m]),
                    selected: _month == m,
                    onSelected: (_) => setState(() => _month = m),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onApply(_year, _month);
                Navigator.pop(context);
              },
              child: Text(s.apply),
            ),
          ),
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
