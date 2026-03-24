import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game_session.dart';
import '../../../providers/language_provider.dart';
import '../../../services/stats_service.dart';
import '../shared/stat_widgets.dart';

class HeadToHeadScreen extends StatelessWidget {
  final String playerA;
  final String playerB;
  final List<GameSession> sessions;

  const HeadToHeadScreen({
    super.key,
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
              Expanded(child: StatsStatCard(label: playerA, value: '$aWins')),
              const SizedBox(width: 8),
              Expanded(child: StatsStatCard(label: s.statsDraws, value: '$draws')),
              const SizedBox(width: 8),
              Expanded(child: StatsStatCard(label: playerB, value: '$bWins')),
              const SizedBox(width: 8),
              Expanded(child: StatsStatCard(label: s.statsTogetherSessions, value: '$totalTogether')),
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
          StatsSectionHeader(s.statsGameBreakdown),
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
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _H2HGameCard extends StatelessWidget {
  final ({String name, int aWins, int bWins, int draws}) game;
  final String playerA, playerB;

  const _H2HGameCard(
      {required this.game, required this.playerA, required this.playerB});

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
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: StatsStatCard(label: playerA, value: '${game.aWins}')),
                const SizedBox(width: 6),
                Expanded(child: StatsStatCard(label: s.statsDraws, value: '${game.draws}')),
                const SizedBox(width: 6),
                Expanded(child: StatsStatCard(label: playerB, value: '${game.bWins}')),
                const SizedBox(width: 6),
                Expanded(child: StatsStatCard(label: s.statsTogetherSessions, value: '$total')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
