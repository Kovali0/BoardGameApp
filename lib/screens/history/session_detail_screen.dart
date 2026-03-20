import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_session.dart';
import '../../providers/language_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_provider.dart';

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
              child: Row(
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
            ),
          ),
          const SizedBox(height: 16),
          Text(s.sessionDetailResults, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...session.players.map((player) {
            final medals = ['🥇', '🥈', '🥉'];
            final medal = player.rank <= 3
                ? medals[player.rank - 1]
                : '${player.rank}.';
            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: Text(medal,
                    style: const TextStyle(fontSize: 24)),
                title: Text(player.playerName,
                    style:
                        const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: player.startedGame
                    ? Text(s.sessionDetailStartedGame,
                        style: const TextStyle(color: Colors.amber))
                    : null,
                trailing: player.score != null
                    ? Text('${player.score} pts',
                        style:
                            Theme.of(context).textTheme.titleMedium)
                    : null,
              ),
            );
          }),
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
