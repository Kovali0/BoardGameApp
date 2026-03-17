import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/board_game.dart';
import '../../providers/game_provider.dart';
import '../../providers/session_provider.dart';
import '../session/play_landing_screen.dart';
import 'add_game_screen.dart';

class GameDetailScreen extends StatelessWidget {
  final BoardGame game;
  const GameDetailScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(game.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddGameScreen(game: game)),
            ),
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
          if (game.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                game.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.group),
                      const SizedBox(width: 8),
                      Text('${game.minPlayers}–${game.maxPlayers} players',
                          style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                  if (game.minPlaytime != null || game.maxPlaytime != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined),
                        const SizedBox(width: 8),
                        Text(
                          _playtimeLabel(game.minPlaytime, game.maxPlaytime),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ],
                  if (game.bggRating != null || game.complexity != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (game.bggRating != null) ...[
                          const Icon(Icons.star_outline, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${game.bggRating!.toStringAsFixed(1)} / 10',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                        if (game.bggRating != null && game.complexity != null)
                          const SizedBox(width: 16),
                        if (game.complexity != null) ...[
                          const Icon(Icons.psychology_outlined),
                          const SizedBox(width: 4),
                          Text(
                            'Weight ${game.complexity!.toStringAsFixed(1)} / 5',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (game.description != null &&
                      game.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(game.description!),
                  ],
                ],
              ),
            ),
          ),
          if (game.setupHints != null && game.setupHints!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Setup Hints',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(child: Text(game.setupHints!)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Play History', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Consumer<SessionProvider>(
            builder: (context, provider, _) {
              final sessions = provider.sessionsForGame(game.id);
              if (sessions.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No sessions yet for this game.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                );
              }
              return Column(
                children: sessions.map((session) {
                  final winner = session.players.isNotEmpty
                      ? session.players.first.playerName
                      : '?';
                  final date = session.startTime;
                  final dateStr =
                      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
                  return ListTile(
                    leading:
                        const Icon(Icons.emoji_events, color: Colors.amber),
                    title: Text(winner),
                    subtitle: Text(dateStr),
                    trailing: Text(session.durationFormatted),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PlayLandingScreen(preselectedGame: game)),
        ),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Play Now'),
      ),
    );
  }

  String _playtimeLabel(int? min, int? max) {
    if (min != null && max != null) {
      return min == max ? '$min min' : '$min–$max min';
    }
    if (min != null) return '$min+ min';
    if (max != null) return 'up to $max min';
    return '';
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Game?'),
        content: Text('Are you sure you want to delete "${game.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              context.read<GameProvider>().deleteGame(game.id);
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
