import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../models/game_session.dart';
import 'session_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions history'),
        centerTitle: true,
      ),
      body: Consumer<SessionProvider>(
        builder: (context, provider, _) {
          if (provider.sessions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No sessions yet. Play a game!',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.sessions.length,
            itemBuilder: (context, index) =>
                _SessionCard(session: provider.sessions[index]),
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final GameSession session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final winner = session.players.isNotEmpty
        ? session.players.first.playerName
        : '?';
    final date = session.startTime;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.emoji_events),
        ),
        title: Text(session.gameName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Winner: $winner  •  $dateStr'),
        trailing: Text(session.durationFormatted,
            style: Theme.of(context).textTheme.bodySmall),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SessionDetailScreen(session: session)),
        ),
      ),
    );
  }
}
