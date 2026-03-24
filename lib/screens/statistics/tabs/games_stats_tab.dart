import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/board_game.dart';
import '../../../models/game_session.dart';
import '../../../providers/language_provider.dart';
import '../../../services/stats_service.dart';
import '../details/game_detail_screen.dart';
import '../shared/stat_widgets.dart';

class GamesStatsTab extends StatelessWidget {
  final List<GameSession> sessions;
  final List<BoardGame> allGames;

  const GamesStatsTab({super.key, required this.sessions, required this.allGames});

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
            Text(s.statsNoGames,
                style: const TextStyle(fontSize: 18, color: Colors.grey)),
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
          StatsSectionHeader(s.statsPlayedGames),
          for (final stats in playedGames) ...[
            Card(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(stats.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  '${stats.sessionCount} session${stats.sessionCount == 1 ? '' : 's'}'
                  '${stats.lastPlayed != null ? ' · ${dateFormat.format(stats.lastPlayed!)}' : ''}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      GameDetailScreen(stats: stats, allGames: allGames),
                )),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
        ],
        if (neverPlayed.isNotEmpty) ...[
          StatsSectionHeader(s.statsNeverPlayed),
          Card(
            child: Column(
              children: [
                for (int i = 0; i < neverPlayed.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13),
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
