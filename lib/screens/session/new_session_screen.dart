import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/game_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/board_game.dart';
import 'random_starter_screen.dart';


class NewSessionScreen extends StatefulWidget {
  final BoardGame? preselectedGame;
  final List<String>? prefilledPlayers;
  final String? prefilledGuestGameName;
  final List<String>? prefilledExpansionIds;

  const NewSessionScreen({
    super.key,
    this.preselectedGame,
    this.prefilledPlayers,
    this.prefilledGuestGameName,
    this.prefilledExpansionIds,
  });

  @override
  State<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends State<NewSessionScreen> {
  bool _isGuestGame = false;
  BoardGame? _selectedGame;
  late final TextEditingController _guestGameNameController;
  final List<TextEditingController> _playerControllers = [];
  final Set<String> _selectedExpansionIds = {};
  String? _expansionOriginName; // set when auto-swapped from an expansion

  @override
  void initState() {
    super.initState();

    if (widget.prefilledGuestGameName != null) {
      _isGuestGame = true;
      _guestGameNameController =
          TextEditingController(text: widget.prefilledGuestGameName);
    } else {
      _guestGameNameController = TextEditingController();
    }

    // Auto-swap: if preselected game is an expansion, use base game instead
    _selectedGame = widget.preselectedGame;
    if (widget.preselectedGame?.isExpansion == true &&
        widget.preselectedGame?.baseGameId != null) {
      final games = context.read<GameProvider>().games;
      final baseGame = games
          .where((g) => g.id == widget.preselectedGame!.baseGameId)
          .firstOrNull;
      if (baseGame != null) {
        _selectedGame = baseGame;
        _expansionOriginName = widget.preselectedGame!.name;
        _selectedExpansionIds.add(widget.preselectedGame!.id);
      }
    }

    // Rematch: pre-fill expansion selections
    if (widget.prefilledExpansionIds != null) {
      _selectedExpansionIds.addAll(widget.prefilledExpansionIds!);
    }

    if (widget.prefilledPlayers != null && widget.prefilledPlayers!.isNotEmpty) {
      for (final name in widget.prefilledPlayers!) {
        _playerControllers.add(TextEditingController(text: name));
      }
      while (_playerControllers.length < 2) {
        _playerControllers.add(TextEditingController());
      }
    } else {
      _playerControllers.add(TextEditingController());
      _playerControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _guestGameNameController.dispose();
    for (final c in _playerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addPlayer() {
    final maxP = _isGuestGame ? 20 : (_selectedGame?.maxPlayers ?? 20);
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
    final s = context.read<LanguageProvider>().strings;
    final players = _playerControllers
        .map((c) => c.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (players.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.newSessionMinPlayersError)),
      );
      return;
    }

    if (_isGuestGame) {
      final name = _guestGameNameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.newSessionEmptyGameError)),
        );
        return;
      }
      final tempGame = BoardGame(
        id: const Uuid().v4(),
        name: name,
        minPlayers: 1,
        maxPlayers: 20,
        createdAt: DateTime.now(),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RandomStarterScreen(
            game: tempGame,
            players: players,
            isFromCollection: false,
          ),
        ),
      );
    } else {
      if (_selectedGame == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.newSessionNoGameError)),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RandomStarterScreen(
            game: _selectedGame!,
            players: players,
            isFromCollection: true,
            expansionIds: _selectedExpansionIds.toList(),
          ),
        ),
      );
    }
  }

  void _quickAddPlayer(String name) {
    // Fill the first empty slot, or add a new one
    for (final c in _playerControllers) {
      if (c.text.trim().isEmpty) {
        setState(() => c.text = name);
        return;
      }
    }
    final maxP = _isGuestGame ? 20 : (_selectedGame?.maxPlayers ?? 20);
    if (_playerControllers.length < maxP) {
      setState(() => _playerControllers.add(TextEditingController(text: name)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final defaultPlayers = context.watch<SettingsProvider>().defaultPlayers;
    // Players not yet in any field
    final usedNames = _playerControllers.map((c) => c.text.trim()).toSet();
    final availableQuick = defaultPlayers.where((p) => !usedNames.contains(p)).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(s.newSessionTitle),
        centerTitle: true,
        automaticallyImplyLeading: widget.preselectedGame != null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                label: Text(s.newSessionMyCollection),
                icon: const Icon(Icons.casino_outlined),
              ),
              ButtonSegment(
                value: true,
                label: Text(s.newSessionOtherGame),
                icon: const Icon(Icons.extension_outlined),
              ),
            ],
            selected: {_isGuestGame},
            onSelectionChanged: (Set<bool> selection) {
              setState(() {
                _isGuestGame = selection.first;
                _selectedGame = widget.preselectedGame;
                _guestGameNameController.clear();
              });
            },
          ),
          const SizedBox(height: 20),
          Text(s.newSessionGame, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_isGuestGame)
            TextFormField(
              controller: _guestGameNameController,
              decoration: InputDecoration(
                hintText: s.newSessionGuestGameHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.extension_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            )
          else
            Consumer<GameProvider>(
              builder: (context, provider, _) {
                final s = context.watch<LanguageProvider>().strings;
                if (provider.games.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        s.newSessionNoGames,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return DropdownButtonFormField<BoardGame>(
                  value: _selectedGame,
                  hint: Text(s.newSessionGameHint),
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
                  onChanged: (game) => setState(() {
                    _selectedGame = game;
                    _selectedExpansionIds.clear();
                    _expansionOriginName = null;
                  }),
                );
              },
            ),
          // Expansion origin banner
          if (_expansionOriginName != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.deepPurple.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.extension, size: 16, color: Colors.deepPurple.shade400),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.watch<LanguageProvider>().strings.expansionOf(_expansionOriginName!),
                      style: TextStyle(fontSize: 13, color: Colors.deepPurple.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Expansion picker for selected base game
          if (!_isGuestGame && _selectedGame != null)
            Consumer<GameProvider>(
              builder: (context, provider, _) {
                final expansions = provider.games
                    .where((g) =>
                        g.isExpansion && g.baseGameId == _selectedGame!.id)
                    .toList();
                if (expansions.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(s.expansionsTitle,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: expansions
                          .map((exp) => FilterChip(
                                avatar: const Icon(Icons.extension, size: 14),
                                label: Text(exp.name),
                                selected:
                                    _selectedExpansionIds.contains(exp.id),
                                onSelected: (v) => setState(() {
                                  if (v) {
                                    _selectedExpansionIds.add(exp.id);
                                  } else {
                                    _selectedExpansionIds.remove(exp.id);
                                  }
                                }),
                              ))
                          .toList(),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.newSessionPlayers, style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(
                onPressed: _addPlayer,
                icon: const Icon(Icons.person_add),
                label: Text(s.newSessionAddPlayer),
              ),
            ],
          ),
          if (availableQuick.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Text(s.settingsQuickAdd,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ...availableQuick.map((name) => ActionChip(
                      label: Text(name),
                      avatar: const Icon(Icons.person_add_alt_1, size: 14),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _quickAddPlayer(name),
                    )),
              ],
            ),
          ],
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
                        hintText: s.newSessionPlayerHint(i + 1),
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
            label: Text(s.newSessionPickStarter),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}
