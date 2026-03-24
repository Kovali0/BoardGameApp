import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/board_game.dart';
import '../../models/game_session.dart';
import '../../providers/game_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/stats_service.dart';

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

    // Session-based widgets — only built when sessions exist
    List<Widget> sessionWidgets = [];
    if (sessions.isNotEmpty) {
      final g = StatsService.computeGlobalStats(sessions)!;

      sessionWidgets = [
        _SectionHeader(s.statsOverview),
        Row(
          children: [
            Expanded(child: _StatCard(label: s.statsSessions, value: '${g.totalSessions}')),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(label: s.statsTimePlayed, value: _formatSeconds(g.totalSeconds))),
            const SizedBox(width: 8),
            Expanded(child: _StatCard(label: s.statsGames, value: '${g.uniqueGames}')),
          ],
        ),
        const SizedBox(height: 20),
        _SectionHeader(s.statsTopGames),
        Card(
          child: Column(
            children: [
              for (int i = 0; i < g.topGamesByCount.length; i++)
                _GameRankRow(
                  medal: _medal(i),
                  name: g.topGamesByCount[i].name,
                  count: g.topGamesByCount[i].count,
                  seconds: g.topGamesByCount[i].seconds,
                  showDivider: i < g.topGamesByCount.length - 1,
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
                value: '${g.longestSession.gameName}  •  ${g.longestSession.durationFormatted}',
              ),
              const Divider(height: 1),
              _RecordRow(
                label: s.statsShortest,
                value: '${g.shortestSession.gameName}  •  ${g.shortestSession.durationFormatted}',
              ),
              const Divider(height: 1),
              _RecordRow(
                label: s.statsAvgDuration,
                value: _formatSeconds(g.avgSeconds),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (g.hallOfFame.isNotEmpty) ...[
          _SectionHeader(s.statsHallOfFame),
          Card(
            child: Column(
              children: [
                for (int i = 0; i < g.hallOfFame.length; i++)
                  _PlayerRow(
                    medal: _medal(i),
                    name: g.hallOfFame[i].name,
                    wins: g.hallOfFame[i].wins,
                    showDivider: i < g.hallOfFame.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (g.bestTeams.isNotEmpty) ...[
          _SectionHeader(s.statsBestTeams),
          Card(
            child: Column(
              children: [
                for (int i = 0; i < g.bestTeams.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Text(_medal(i), style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                g.bestTeams[i].players.join(' & '),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${g.bestTeams[i].sessions} ${s.statsSessions.toLowerCase()} · ${g.bestTeams[i].wins} ${s.statsWins.toLowerCase()}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < g.bestTeams.length - 1) const Divider(height: 1),
                ],
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

class _GamesStatsContent extends StatelessWidget {
  final List<GameSession> sessions;
  final List<BoardGame> allGames;

  const _GamesStatsContent({required this.sessions, required this.allGames});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final statsMap = StatsService.computeGameStats(sessions);
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
  final GameStatsData stats;
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
    final playerList = StatsService.computePlayerList(widget.sessions);

    if (playerList.isEmpty) {
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

    final playerNames = playerList.map((e) => e.name).toList();
    // Reset selections if player no longer in list
    if (_playerA != null && !playerNames.contains(_playerA)) _playerA = null;
    if (_playerB != null && !playerNames.contains(_playerB)) _playerB = null;

    final canCompare = _playerA != null && _playerB != null && _playerA != _playerB;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Head-to-head picker ──
        if (playerList.length >= 2) ...[
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
        for (int i = 0; i < playerList.length; i++) ...[
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text(playerList[i].name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${playerList[i].sessions} session${playerList[i].sessions == 1 ? '' : 's'} · '
                '${playerList[i].wins} win${playerList[i].wins == 1 ? '' : 's'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => _PlayerDetailScreen(
                  playerName: playerList[i].name,
                  sessions: widget.sessions,
                ),
              )),
            ),
          ),
          if (i < playerList.length - 1) const SizedBox(height: 8),
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

    final h2h = StatsService.computeH2H(playerA, playerB, sessions);
    final aWins = h2h.aWins;
    final bWins = h2h.bWins;
    final draws = h2h.draws;
    final totalTogether = h2h.total;

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

    final games = h2h.byGame;

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

class _PlayerDetailScreen extends StatelessWidget {
  final String playerName;
  final List<GameSession> sessions;

  const _PlayerDetailScreen({required this.playerName, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final pd = StatsService.computePlayerDetail(playerName, sessions);
    final totalSessions = pd.totalSessions;
    final wins = pd.wins;
    final secondPlaces = pd.secondPlaces;
    final thirdPlaces = pd.thirdPlaces;
    final uniqueGames = pd.uniqueGames;
    final winRate = pd.winRate;
    final games = pd.gameBreakdown;

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
                _RecordRow(label: s.statsTotalTime, value: _formatSeconds(pd.totalSeconds)),
                if (pd.mostPlayedName != null) ...[
                  const Divider(height: 1),
                  _RecordRow(label: s.statsMostPlayed, value: pd.mostPlayedName!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Section 2: Team Partners ──
          if (pd.bestPartner != null || pd.worstPartner != null) ...[
            _SectionHeader(s.statsBestTeams),
            Card(
              child: Column(
                children: [
                  if (pd.bestPartner != null) ...[
                    _RecordRow(
                      label: s.statsBestPartner,
                      value:
                          '${pd.bestPartner}  •  ${(pd.bestPartnerWinRate * 100).round()}% (${pd.bestPartnerSessions} ${s.statsPartnerSessions.toLowerCase()})',
                    ),
                  ],
                  if (pd.bestPartner != null && pd.worstPartner != null && pd.bestPartner != pd.worstPartner) ...[
                    const Divider(height: 1),
                    _RecordRow(
                      label: s.statsWorstPartner,
                      value:
                          '${pd.worstPartner}  •  ${(pd.worstPartnerWinRate * 100).round()}% (${pd.worstPartnerSessions} ${s.statsPartnerSessions.toLowerCase()})',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Section 3: Game Breakdown ──
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
  final PlayerGameData data;

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
