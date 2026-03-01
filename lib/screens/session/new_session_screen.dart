import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../models/board_game.dart';
import 'random_starter_screen.dart';

class NewSessionScreen extends StatefulWidget {
  final BoardGame? preselectedGame;
  const NewSessionScreen({super.key, this.preselectedGame});

  @override
  State<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends State<NewSessionScreen> {
  BoardGame? _selectedGame;
  final List<TextEditingController> _playerControllers = [];

  @override
  void initState() {
    super.initState();
    _selectedGame = widget.preselectedGame;
    _playerControllers.add(TextEditingController());
    _playerControllers.add(TextEditingController());
  }

  @override
  void dispose() {
    for (final c in _playerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addPlayer() {
    final maxP = _selectedGame?.maxPlayers ?? 20;
    if (_playerControllers.length < maxP) {
      setState(() => _playerControllers.add(TextEditingController()));
    }
  }

  void _removePlayer(int index) {
    if (_playerControllers.length > 2) {
      setState(() {
        _playerControllers[index].dispose();
        _playerControllers.removeAt(index);
      });
    }
  }

  void _startSession() {
    if (_selectedGame == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a game first')),
      );
      return;
    }
    final players = _playerControllers
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (players.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least 2 players')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RandomStarterScreen(
          game: _selectedGame!,
          players: players,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Game'),
        centerTitle: true,
        automaticallyImplyLeading: widget.preselectedGame != null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Select Game', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Consumer<GameProvider>(
            builder: (context, provider, _) {
              if (provider.games.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No games in catalog. Add a game first!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }
              return DropdownButtonFormField<BoardGame>(
                value: _selectedGame,
                hint: const Text('Choose a game...'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.casino),
                ),
                items: provider.games
                    .map((game) => DropdownMenuItem(
                          value: game,
                          child: Text(game.name),
                        ))
                    .toList(),
                onChanged: (game) => setState(() => _selectedGame = game),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Players', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: _addPlayer,
                icon: const Icon(Icons.person_add),
                label: const Text('Add Player'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(
            _playerControllers.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    child: Text('${i + 1}'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _playerControllers[i],
                      decoration: InputDecoration(
                        hintText: 'Player ${i + 1} name',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),
                  if (_playerControllers.length > 2)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => _removePlayer(i),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _startSession,
            icon: const Icon(Icons.shuffle),
            label: const Text('Pick Who Starts!'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}
