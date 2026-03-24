import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/board_game.dart';
import '../../../models/game_session.dart';
import '../../../providers/language_provider.dart';
import '../../../services/stats_service.dart';
import '../shared/stat_widgets.dart';

class GlobalStatsTab extends StatelessWidget {
  final List<GameSession> sessions;
  final List<BoardGame> allGames;

  const GlobalStatsTab({super.key, required this.sessions, required this.allGames});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final playedCount = allGames.where((g) => g.hasBeenPlayed).length;
    final unplayedCount = allGames.length - playedCount;

    List<Widget> sessionWidgets = [];
    if (sessions.isNotEmpty) {
      final g = StatsService.computeGlobalStats(sessions)!;

      sessionWidgets = [
        StatsSectionHeader(s.statsOverview),
        Row(
          children: [
            Expanded(child: StatsStatCard(label: s.statsSessions, value: '${g.totalSessions}')),
            const SizedBox(width: 8),
            Expanded(child: StatsStatCard(label: s.statsTimePlayed, value: statsFormatSeconds(g.totalSeconds))),
            const SizedBox(width: 8),
            Expanded(child: StatsStatCard(label: s.statsGames, value: '${g.uniqueGames}')),
          ],
        ),
        const SizedBox(height: 20),
        StatsSectionHeader(s.statsTopGames),
        Card(
          child: Column(
            children: [
              for (int i = 0; i < g.topGamesByCount.length; i++)
                StatsGameRankRow(
                  medal: statsMedal(i),
                  name: g.topGamesByCount[i].name,
                  count: g.topGamesByCount[i].count,
                  seconds: g.topGamesByCount[i].seconds,
                  showDivider: i < g.topGamesByCount.length - 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        StatsSectionHeader(s.statsRecords),
        Card(
          child: Column(
            children: [
              StatsRecordRow(
                label: s.statsLongest,
                value: '${g.longestSession.gameName}  •  ${g.longestSession.durationFormatted}',
              ),
              const Divider(height: 1),
              StatsRecordRow(
                label: s.statsShortest,
                value: '${g.shortestSession.gameName}  •  ${g.shortestSession.durationFormatted}',
              ),
              const Divider(height: 1),
              StatsRecordRow(
                label: s.statsAvgDuration,
                value: statsFormatSeconds(g.avgSeconds),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (g.hallOfFame.isNotEmpty) ...[
          StatsSectionHeader(s.statsHallOfFame),
          Card(
            child: Column(
              children: [
                for (int i = 0; i < g.hallOfFame.length; i++)
                  StatsPlayerRow(
                    medal: statsMedal(i),
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
          StatsSectionHeader(s.statsBestTeams),
          Card(
            child: Column(
              children: [
                for (int i = 0; i < g.bestTeams.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Text(statsMedal(i), style: const TextStyle(fontSize: 18)),
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
          StatsSectionHeader(s.statsCollection),
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

    paint.color = Colors.amber.shade700;
    canvas.drawArc(rect, startAngle, 2 * pi, false, paint);

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
        Text('$count',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
