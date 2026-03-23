import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/game_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/board_game.dart';
import 'random_starter_screen.dart';

const _kTeamColors = [
  Color(0xFF1E88E5),
  Color(0xFFE53935),
  Color(0xFF43A047),
  Color(0xFF8E24AA),
  Color(0xFFFF7043),
  Color(0xFF00ACC1),
];

class NewSessionScreen extends StatefulWidget {
  final BoardGame? preselectedGame;
  final List<String>? prefilledPlayers;
  final String? prefilledGuestGameName;
  final List<String>? prefilledExpansionIds;
  final Map<String, String>? prefilledTeamAssignments;

  const NewSessionScreen({
    super.key,
    this.preselectedGame,
    this.prefilledPlayers,
    this.prefilledGuestGameName,
    this.prefilledExpansionIds,
    this.prefilledTeamAssignments,
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
  String? _expansionOriginName;

  // Teams
  bool _teamsEnabled = false;
  int _teamCount = 2;
  final List<TextEditingController> _teamNameControllers = [];
  final List<int> _playerTeamIndices = []; // per-player team index (0-based)

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

    // Init 6 team name controllers (only first _teamCount are shown)
    for (int i = 0; i < 6; i++) {
      _teamNameControllers.add(TextEditingController());
    }

    // Init player team indices (default: round-robin)
    for (int i = 0; i < _playerControllers.length; i++) {
      _playerTeamIndices.add(i % 2);
    }

    // Restore teams from rematch
    if (widget.prefilledTeamAssignments != null &&
        widget.prefilledTeamAssignments!.isNotEmpty) {
      _teamsEnabled = true;
      final assignments = widget.prefilledTeamAssignments!;
      // Collect team names in order of first appearance
      final teamOrder = <String>[];
      for (final name in widget.prefilledPlayers ?? []) {
        final t = assignments[name];
        if (t != null && !teamOrder.contains(t)) teamOrder.add(t);
      }
      _teamCount = teamOrder.length.clamp(2, 6);
      for (int i = 0; i < teamOrder.length; i++) {
        _teamNameControllers[i].text = teamOrder[i];
      }
      // Set player team indices
      _playerTeamIndices.clear();
      for (int i = 0; i < _playerControllers.length; i++) {
        final name = _playerControllers[i].text.trim();
        final t = assignments[name];
        final idx = t != null ? teamOrder.indexOf(t) : (i % _teamCount);
        _playerTeamIndices.add(idx.clamp(0, _teamCount - 1));
      }
    }
  }

  @override
  void dispose() {
    _guestGameNameController.dispose();
    for (final c in _playerControllers) c.dispose();
    for (final c in _teamNameControllers) c.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final maxP = _isGuestGame ? 20 : (_selectedGame?.maxPlayers ?? 20);
    if (_playerControllers.length < maxP) {
      setState(() {
        _playerControllers.add(TextEditingController());
        _playerTeamIndices.add((_playerControllers.length - 1) % _teamCount);
      });
    }
  }

  void _removePlayer(int index) {
    if (_playerControllers.length > 2) {
      setState(() {
        _playerControllers[index].dispose();
        _playerControllers.removeAt(index);
        _playerTeamIndices.removeAt(index);
      });
    }
  }

  void _quickAddPlayer(String name) {
    for (final c in _playerControllers) {
      if (c.text.trim().isEmpty) {
        setState(() => c.text = name);
        return;
      }
    }
    final maxP = _isGuestGame ? 20 : (_selectedGame?.maxPlayers ?? 20);
    if (_playerControllers.length < maxP) {
      setState(() {
        _playerControllers.add(TextEditingController(text: name));
        _playerTeamIndices.add((_playerControllers.length - 1) % _teamCount);
      });
    }
  }

  void _autoAssignTeams() {
    for (int i = 0; i < _playerTeamIndices.length; i++) {
      _playerTeamIndices[i] = i % _teamCount;
    }
  }

  String _resolvedTeamName(int teamIdx) {
    final text = _teamNameControllers[teamIdx].text.trim();
    return text.isEmpty
        ? context.read<LanguageProvider>().strings.teamNameHint(teamIdx + 1)
        : text;
  }

  Map<String, String> _buildTeamAssignments(List<String> players) {
    final result = <String, String>{};
    for (int i = 0; i < _playerControllers.length; i++) {
      final name = _playerControllers[i].text.trim();
      if (name.isEmpty) continue;
      final teamIdx =
          i < _playerTeamIndices.length ? _playerTeamIndices[i] : 0;
      result[name] = _resolvedTeamName(teamIdx.clamp(0, _teamCount - 1));
    }
    return result;
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

    final teamAssignments =
        _teamsEnabled ? _buildTeamAssignments(players) : <String, String>{};

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
            teamAssignments: teamAssignments,
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
            teamAssignments: teamAssignments,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final defaultPlayers = context.watch<SettingsProvider>().defaultPlayers;
    final usedNames = _playerControllers.map((c) => c.text.trim()).toSet();
    final availableQuick =
        defaultPlayers.where((p) => !usedNames.contains(p)).toList();
    final playerCount = _playerControllers
        .where((c) => c.text.trim().isNotEmpty)
        .length;
    final maxTeams = playerCount.clamp(2, 6);

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
                  isExpanded: true,
                  items: provider.games
                      .map((game) => DropdownMenuItem(
                            value: game,
                            child: Text(
                              game.name,
                              overflow: TextOverflow.ellipsis,
                            ),
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
            (i) {
              final teamIdx = i < _playerTeamIndices.length
                  ? _playerTeamIndices[i].clamp(0, _teamCount - 1)
                  : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _teamsEnabled
                          ? _kTeamColors[teamIdx]
                          : null,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: _teamsEnabled ? Colors.white : null,
                          fontSize: 12,
                        ),
                      ),
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
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (_teamsEnabled) ...[
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 110,
                        child: DropdownButtonFormField<int>(
                          value: teamIdx,
                          isDense: true,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                          ),
                          items: List.generate(_teamCount, (ti) {
                            return DropdownMenuItem(
                              value: ti,
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _kTeamColors[ti],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _resolvedTeamName(ti),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                while (_playerTeamIndices.length <= i) {
                                  _playerTeamIndices.add(0);
                                }
                                _playerTeamIndices[i] = v;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                    if (_playerControllers.length > 2)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _removePlayer(i),
                      ),
                  ],
                ),
              );
            },
          ),

          // ── Teams section ──
          const SizedBox(height: 8),
          SwitchListTile(
            title: Text(s.teamGame),
            subtitle: Text(s.teamGameSub,
                style: const TextStyle(fontSize: 12)),
            value: _teamsEnabled,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() {
              _teamsEnabled = v;
              if (v) _autoAssignTeams();
            }),
          ),
          if (_teamsEnabled) ...[
            const SizedBox(height: 4),
            // Team count stepper
            Row(
              children: [
                Text(s.teamCount,
                    style: const TextStyle(fontSize: 14)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _teamCount > 2
                      ? () => setState(() {
                            _teamCount--;
                            // Reassign any player on removed team
                            for (int i = 0; i < _playerTeamIndices.length; i++) {
                              if (_playerTeamIndices[i] >= _teamCount) {
                                _playerTeamIndices[i] = 0;
                              }
                            }
                          })
                      : null,
                ),
                Text('$_teamCount',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _teamCount < maxTeams
                      ? () => setState(() => _teamCount++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Team name inputs
            for (int ti = 0; ti < _teamCount; ti++) ...[
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _kTeamColors[ti],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _teamNameControllers[ti],
                      decoration: InputDecoration(
                        hintText: s.teamNameHint(ti + 1),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ],

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
