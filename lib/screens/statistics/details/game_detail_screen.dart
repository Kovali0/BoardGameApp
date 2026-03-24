import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/board_game.dart';
import '../../../providers/language_provider.dart';
import '../../../services/stats_service.dart';
import '../shared/stat_widgets.dart';

class GameDetailScreen extends StatelessWidget {
  final GameStatsData stats;
  final List<BoardGame> allGames;

  const GameDetailScreen({
    super.key,
    required this.stats,
    required this.allGames,
  });

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
          StatsSectionHeader(s.statsOverview),
          Row(
            children: [
              Expanded(child: StatsStatCard(label: s.statsSessions, value: '${stats.sessionCount}')),
              const SizedBox(width: 8),
              Expanded(child: StatsStatCard(label: s.statsTotalTime, value: statsFormatSeconds(stats.totalSeconds))),
              const SizedBox(width: 8),
              Expanded(child: StatsStatCard(label: s.statsAvgDuration, value: statsFormatSeconds(stats.avgSeconds))),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                StatsRecordRow(label: s.statsAvgPlayers, value: stats.avgPlayers.toStringAsFixed(1)),
                if (lastPlayed != null) ...[
                  const Divider(height: 1),
                  StatsRecordRow(label: s.statsLastPlayed, value: dateFormat.format(lastPlayed)),
                ],
                if (bestPlayer != null) ...[
                  const Divider(height: 1),
                  StatsRecordRow(label: s.statsBestPlayer, value: bestPlayer),
                ],
                if (stats.longestSeconds != null) ...[
                  const Divider(height: 1),
                  StatsRecordRow(label: s.statsLongest, value: statsFormatSeconds(stats.longestSeconds!)),
                ],
                if (stats.shortestSeconds != null && stats.sessionCount > 1) ...[
                  const Divider(height: 1),
                  StatsRecordRow(label: s.statsShortest, value: statsFormatSeconds(stats.shortestSeconds!)),
                ],
                if (stats.sessionsWithExpansions > 0) ...[
                  const Divider(height: 1),
                  StatsRecordRow(
                    label: s.statsSessionsWithExpansions,
                    value:
                        '${stats.sessionsWithExpansions} / ${stats.sessionCount} '
                        '(${(stats.sessionsWithExpansions / stats.sessionCount * 100).round()}%)',
                  ),
                ],
                if (stats.expansionUseCounts.isNotEmpty) ...[
                  const Divider(height: 1),
                  StatsRecordRow(
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
            StatsSectionHeader(s.statsRecords),
            Card(
              child: Column(
                children: [
                  StatsRecordRow(label: s.statsHighestScore, value: '${stats.highestScore} pts'),
                  const Divider(height: 1),
                  StatsRecordRow(label: s.statsAvgScore, value: '${stats.avgScore!.toStringAsFixed(1)} pts'),
                  const Divider(height: 1),
                  StatsRecordRow(label: s.statsLowestScore, value: '${stats.lowestScore} pts'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
