import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../models/board_game.dart';
import 'add_game_screen.dart';
import 'game_detail_screen.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Games Collection'),
        centerTitle: true,
      ),
      body: Consumer<GameProvider>(
        builder: (context, provider, _) {
          if (provider.games.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.casino_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No games yet. Add your first game!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.games.length,
            itemBuilder: (context, index) =>
                _GameCard(game: provider.games[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddGameScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Game'),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final BoardGame game;
  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(game.name[0].toUpperCase()),
        ),
        title: Text(game.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${game.minPlayers}–${game.maxPlayers} players'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GameDetailScreen(game: game)),
        ),
      ),
    );
  }
}
