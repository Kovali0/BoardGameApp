import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game_session.dart';
import '../../../providers/language_provider.dart';
import '../../../services/stats_service.dart';
import '../shared/stat_widgets.dart';

class PlayerDetailScreen extends StatelessWidget {
  final String playerName;
  final List<GameSession> sessions;

  const PlayerDetailScreen({
    super.key,
    required this.playerName,
    required this.sessions,
  });

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
          StatsSectionHeader(s.statsOverview),
          Row(
            children: [
              Expanded(child: StatsStatCard(label: s.statsSessions, value: '$totalSessions')),
              const SizedBox(width: 8),
              Expanded(child: StatsStatCard(label: s.statsWins, value: '$wins')),
              const SizedBox(width: 8),
              Expanded(child: StatsStatCard(label: s.statsWinRate, value: '${(winRate * 100).round()}%')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: StatsStatCard(label: s.statsSecondPlaces, value: '$secondPlaces')),
              const SizedBox(width: 8),
              Expanded(child: StatsStatCard(label: s.statsThirdPlaces, value: '$thirdPlaces')),
              const SizedBox(width: 8),
              Expanded(child: StatsStatCard(label: s.statsGames, value: '$uniqueGames')),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                StatsRecordRow(label: s.statsTotalTime, value: statsFormatSeconds(pd.totalSeconds)),
                if (pd.mostPlayedName != null) ...[
                  const Divider(height: 1),
                  StatsRecordRow(label: s.statsMostPlayed, value: pd.mostPlayedName!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Section 2: Team Partners ──
          if (pd.bestPartner != null || pd.worstPartner != null) ...[
            StatsSectionHeader(s.statsBestTeams),
            Card(
              child: Column(
                children: [
                  if (pd.bestPartner != null) ...[
                    StatsRecordRow(
                      label: s.statsBestPartner,
                      value:
                          '${pd.bestPartner}  •  ${(pd.bestPartnerWinRate * 100).round()}% (${pd.bestPartnerSessions} ${s.statsPartnerSessions.toLowerCase()})',
                    ),
                  ],
                  if (pd.bestPartner != null &&
                      pd.worstPartner != null &&
                      pd.bestPartner != pd.worstPartner) ...[
                    const Divider(height: 1),
                    StatsRecordRow(
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
            StatsSectionHeader(s.statsGameBreakdown),
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
                Expanded(child: StatsStatCard(label: s.statsGames, value: '${data.sessionCount}')),
                const SizedBox(width: 8),
                Expanded(child: StatsStatCard(label: s.statsWins, value: '${data.wins}')),
                const SizedBox(width: 8),
                Expanded(child: StatsStatCard(label: s.statsSecondPlaces, value: '${data.secondPlaces}')),
                const SizedBox(width: 8),
                Expanded(child: StatsStatCard(label: s.statsThirdPlaces, value: '${data.thirdPlaces}')),
                const SizedBox(width: 8),
                Expanded(
                  child: StatsStatCard(
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
              StatsRecordRow(label: s.statsBestScore, value: '$highScore pts'),
            if (highScore != null && avgScore != null) const Divider(height: 1),
            if (avgScore != null)
              StatsRecordRow(label: s.statsAvgScore, value: '${avgScore.toStringAsFixed(1)} pts'),
          ],
        ],
      ),
    );
  }
}
