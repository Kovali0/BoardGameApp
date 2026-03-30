import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/board_game.dart';
import '../../models/game_session.dart';
import '../../providers/game_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_provider.dart';
import '../session/new_session_screen.dart';

const _kTeamColors = [
  Color(0xFF1E88E5),
  Color(0xFFE53935),
  Color(0xFF43A047),
  Color(0xFF8E24AA),
  Color(0xFFFF7043),
  Color(0xFF00ACC1),
];

class SessionDetailScreen extends StatelessWidget {
  final GameSession session;
  const SessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final dateStr = context.watch<SettingsProvider>().formatDate(session.startTime);

    return Scaffold(
      appBar: AppBar(
        title: Text(session.gameName),
        actions: [
          IconButton(
            icon: const Icon(Icons.replay),
            tooltip: context.read<LanguageProvider>().strings.rematch,
            onPressed: () => _rematch(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _InfoItem(icon: Icons.calendar_today, label: dateStr),
                      _InfoItem(
                          icon: Icons.timer, label: session.durationFormatted),
                      _InfoItem(
                          icon: Icons.group,
                          label: '${session.players.length}p'),
                    ],
                  ),
                  if (session.location != null && session.location!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.place_outlined,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          session.location!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(s.sessionDetailResults, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...() {
            // Compute sorted team names for consistent color mapping
            final teamNames = session.players
                .map((p) => p.teamName)
                .whereType<String>()
                .toSet()
                .toList()
              ..sort();

            return session.players.map((player) {
              final medals = ['🥇', '🥈', '🥉'];
              final medal = player.rank <= 3
                  ? medals[player.rank - 1]
                  : '${player.rank}.';
              final teamIdx = player.teamName != null
                  ? teamNames.indexOf(player.teamName!)
                  : -1;
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  leading: Text(medal, style: const TextStyle(fontSize: 24)),
                  title: Row(
                    children: [
                      if (teamIdx >= 0) ...[
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _kTeamColors[teamIdx % _kTeamColors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(player.playerName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (player.teamName != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          player.teamName!,
                          style: TextStyle(
                              fontSize: 11,
                              color: teamIdx >= 0
                                  ? _kTeamColors[teamIdx % _kTeamColors.length]
                                  : Colors.grey),
                        ),
                      ],
                    ],
                  ),
                  subtitle: player.startedGame
                      ? Text(s.sessionDetailStartedGame,
                          style: const TextStyle(color: Colors.amber))
                      : null,
                  trailing: player.score != null
                      ? Text('${player.score} pts',
                          style: Theme.of(context).textTheme.titleMedium)
                      : null,
                ),
              );
            }).toList();
          }(),
          if (session.expansionIds.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(s.sessionExpansionsSection,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Consumer<GameProvider>(
              builder: (context, provider, _) {
                final expansions = session.expansionIds
                    .map((id) =>
                        provider.games.where((g) => g.id == id).firstOrNull)
                    .whereType<BoardGame>()
                    .toList();
                return Card(
                  child: Column(
                    children: [
                      for (int i = 0; i < expansions.length; i++) ...[
                        ListTile(
                          leading: CircleAvatar(
                            backgroundImage: (expansions[i].thumbnailUrl ??
                                        expansions[i].imageUrl) !=
                                    null
                                ? NetworkImage(expansions[i].thumbnailUrl ??
                                    expansions[i].imageUrl!)
                                : null,
                            child: (expansions[i].thumbnailUrl ??
                                        expansions[i].imageUrl) ==
                                    null
                                ? const Icon(Icons.extension)
                                : null,
                          ),
                          title: Text(expansions[i].name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500)),
                        ),
                        if (i < expansions.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
          if (session.notes != null && session.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(s.sessionDetailNotes, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(session.notes!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _rematch(BuildContext context) {
    final game = context.read<GameProvider>().games
        .where((g) => g.id == session.gameId)
        .firstOrNull;
    final playerNames = session.players.map((p) => p.playerName).toList();
    final teamAssignments = <String, String>{};
    for (final p in session.players) {
      if (p.teamName != null) teamAssignments[p.playerName] = p.teamName!;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewSessionScreen(
          preselectedGame: game,
          prefilledPlayers: playerNames,
          prefilledGuestGameName: game == null ? session.gameName : null,
          prefilledExpansionIds: session.expansionIds.isNotEmpty
              ? session.expansionIds
              : null,
          prefilledTeamAssignments:
              teamAssignments.isNotEmpty ? teamAssignments : null,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final s = context.read<LanguageProvider>().strings;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteSessionTitle),
        content: Text(s.deleteSessionContent),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel)),
          FilledButton(
            onPressed: () {
              context.read<SessionProvider>().deleteSession(session.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(s.delete),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoItem({required this.icon, required this.label});

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
