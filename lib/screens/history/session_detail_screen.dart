import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_session.dart';
import '../../providers/session_provider.dart';

class SessionDetailScreen extends StatelessWidget {
  final GameSession session;
  const SessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final date = session.startTime;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

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
          Text('Results', style: Theme.of(context).textTheme.titleMedium),
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
                    ? const Text('started the game',
                        style: TextStyle(color: Colors.amber))
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
            Text('Notes', style: Theme.of(context).textTheme.titleMedium),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Session?'),
        content:
            const Text('This session record will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              context.read<SessionProvider>().deleteSession(session.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
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
