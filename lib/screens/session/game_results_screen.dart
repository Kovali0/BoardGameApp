import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/board_game.dart';
import '../../providers/language_provider.dart';
import 'new_session_screen.dart';

class GameResultsScreen extends StatelessWidget {
  final BoardGame? game;
  final String gameName;
  final int durationSeconds;
  final List<Map<String, dynamic>> playerResults; // {name, rank, score}

  const GameResultsScreen({
    super.key,
    required this.game,
    required this.gameName,
    required this.durationSeconds,
    required this.playerResults,
  });

  String get _formattedDuration {
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  void _rematch(BuildContext context) {
    final playerNames = playerResults.map((p) => p['name'] as String).toList();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => NewSessionScreen(
          preselectedGame: game,
          prefilledPlayers: playerNames,
          prefilledGuestGameName: game == null ? gameName : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final theme = Theme.of(context);

    // Sort by rank ascending, then by name for ties
    final sorted = List<Map<String, dynamic>>.from(playerResults)
      ..sort((a, b) {
        final ra = (a['rank'] as int?) ?? 0;
        final rb = (b['rank'] as int?) ?? 0;
        if (ra == 0 && rb == 0) return 0;
        if (ra == 0) return 1;
        if (rb == 0) return -1;
        return ra.compareTo(rb);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(s.gameResultsTitle),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryItem(icon: Icons.casino, label: gameName),
                        _SummaryItem(icon: Icons.timer, label: _formattedDuration),
                        _SummaryItem(
                          icon: Icons.group,
                          label: '${playerResults.length}p',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(s.sessionDetailResults,
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ...sorted.map((p) {
                  final rank = (p['rank'] as int?) ?? 0;
                  final score = p['score'] as int?;
                  final name = p['name'] as String;

                  final medals = ['🥇', '🥈', '🥉'];
                  final medal = rank >= 1 && rank <= 3
                      ? medals[rank - 1]
                      : rank > 0
                          ? '${rank}.'
                          : '—';

                  final isWinner = rank == 1;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    color: isWinner
                        ? theme.colorScheme.primaryContainer.withOpacity(0.4)
                        : null,
                    child: ListTile(
                      leading: Text(medal,
                          style: const TextStyle(fontSize: 26)),
                      title: Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isWinner
                              ? theme.colorScheme.primary
                              : null,
                        ),
                      ),
                      trailing: score != null
                          ? Text(
                              '$score pts',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: isWinner
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ],
            ),
          ),
          // Action buttons
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    icon: const Icon(Icons.home_outlined),
                    label: Text(s.gameResultsClose),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _rematch(context),
                    icon: const Icon(Icons.replay),
                    label: Text(s.rematch),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SummaryItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
