import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/board_game.dart';
import '../../providers/game_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/ranking_service.dart';
import 'game_results_screen.dart';

class AddResultsScreen extends StatefulWidget {
  final BoardGame? preselectedGame;
  const AddResultsScreen({super.key, this.preselectedGame});

  @override
  State<AddResultsScreen> createState() => _AddResultsScreenState();
}

class _AddResultsScreenState extends State<AddResultsScreen> {
  bool _isGuestGame = false;
  BoardGame? _selectedGame;
  final _guestNameController = TextEditingController();
  final Set<String> _selectedExpansionIds = {};
  String? _expansionOriginName;

  DateTime _date = DateTime.now();
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController(text: '30');

  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _scoreControllers = [];

  // key = base rank, value = ordered list of player indices (as strings) in that tie group
  final Map<int, List<String>> _tieOrder = {};
  final _tiebreakerController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
    _addPlayerRow();
    _addPlayerRow();
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _tiebreakerController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    for (final c in _nameControllers) c.dispose();
    for (final c in _scoreControllers) c.dispose();
    super.dispose();
  }

  void _quickAddPlayer(String name) {
    for (final c in _nameControllers) {
      if (c.text.trim().isEmpty) {
        setState(() => c.text = name);
        return;
      }
    }
    _addPlayerRow();
    // Set name on the new last controller after setState completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_nameControllers.isNotEmpty) {
        setState(() => _nameControllers.last.text = name);
      }
    });
  }

  void _addPlayerRow() {
    setState(() {
      _nameControllers.add(TextEditingController());
      _scoreControllers.add(TextEditingController());
      _tieOrder
        ..clear()
        ..addAll(RankingService.syncTieOrder(_computeBaseRanks(), {}));
    });
  }

  void _removePlayerRow(int index) {
    if (_nameControllers.length <= 2) return;
    setState(() {
      _nameControllers[index].dispose();
      _scoreControllers[index].dispose();
      _nameControllers.removeAt(index);
      _scoreControllers.removeAt(index);
      _tieOrder
        ..clear()
        ..addAll(RankingService.syncTieOrder(_computeBaseRanks(), {}));
    });
  }

  /// Scores as a string-keyed map (index → score) for RankingService.
  Map<String, int?> get _scoresMap => {
        for (int i = 0; i < _nameControllers.length; i++)
          '$i': int.tryParse(_scoreControllers[i].text.trim()),
      };

  /// Base ranks as a list indexed by player position.
  Map<String, int> _computeBaseRanks() =>
      RankingService.computeBaseRanks(_scoresMap);

  /// Tie groups: baseRank → [player indices as strings] for groups with 2+ players.
  Map<int, List<String>> _computeTieGroups(Map<String, int> baseRanks) =>
      RankingService.computeTieGroups(baseRanks);

  /// Final ranks as a list indexed by player position.
  Map<String, int> _computeFinalRanks() =>
      RankingService.computeFinalRanks(_computeBaseRanks(), _tieOrder);

  void _onScoreChanged() {
    final base = _computeBaseRanks();
    setState(() {
      _tieOrder
        ..clear()
        ..addAll(RankingService.syncTieOrder(base, _tieOrder));
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }



  Future<void> _save() async {
    final s = context.read<LanguageProvider>().strings;
    // Resolve game
    BoardGame? game;
    if (_isGuestGame) {
      final name = _guestNameController.text.trim();
      if (name.isEmpty) { _snack(s.addResultsEmptyGameError); return; }
      game = BoardGame(
        id: const Uuid().v4(),
        name: name,
        minPlayers: 1,
        maxPlayers: 20,
        createdAt: DateTime.now(),
      );
    } else {
      if (_selectedGame == null) { _snack(s.addResultsNoGameError); return; }
      game = _selectedGame!;
    }

    // Resolve duration
    final hours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
    final totalSeconds = hours * 3600 + minutes * 60;
    if (totalSeconds <= 0) { _snack(s.addResultsDurationError); return; }

    // Resolve players with final ranks
    final finalRanks = _computeFinalRanks();
    final players = <Map<String, dynamic>>[];
    for (int i = 0; i < _nameControllers.length; i++) {
      final name = _nameControllers[i].text.trim();
      if (name.isEmpty) continue;
      final scoreText = _scoreControllers[i].text.trim();
      final rank = finalRanks['$i'] ?? 0;
      players.add({
        'name': name,
        'score': scoreText.isEmpty ? null : int.tryParse(scoreText),
        'rank': rank == 0 ? 1 : rank,
        'startedGame': false,
      });
    }
    if (players.length < 2) { _snack(s.addResultsMinPlayersError); return; }

    final tieNote = _tiebreakerController.text.trim();
    final generalNote = _notesController.text.trim();

    final startTime = DateTime(_date.year, _date.month, _date.day, 12, 0);
    final endTime = startTime.add(Duration(seconds: totalSeconds));

    final location = _locationController.text.trim();
    await context.read<SessionProvider>().saveSession(
          gameId: game.id,
          gameName: game.name,
          startTime: startTime,
          endTime: endTime,
          durationSeconds: totalSeconds,
          playerData: players,
          notes: generalNote.isEmpty ? null : generalNote,
          isFromCollection: !_isGuestGame,
          expansionIds: _selectedExpansionIds.toList(),
          location: location.isEmpty ? null : location,
          tiebreaker: tieNote.isEmpty ? null : tieNote,
        );

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GameResultsScreen(
            game: _isGuestGame ? null : game,
            gameName: game!.name,
            durationSeconds: totalSeconds,
            playerResults: players,
          ),
        ),
      );
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final settingsProvider = context.watch<SettingsProvider>();
    final formattedDate = settingsProvider.formatDate(_date);
    final defaultPlayers = settingsProvider.defaultPlayers;
    final usedNames = _nameControllers.map((c) => c.text.trim()).toSet();
    final availableQuick = defaultPlayers.where((p) => !usedNames.contains(p)).toList();
    final theme = Theme.of(context);
    final base = _computeBaseRanks();
    final tieGroups = _computeTieGroups(base);
    final finalRanks = _computeFinalRanks();
    final hasTies = tieGroups.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(s.addResultsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Game toggle
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                label: Text(s.resultsMyCollection),
                icon: const Icon(Icons.casino_outlined),
              ),
              ButtonSegment(
                value: true,
                label: Text(s.resultsOtherGame),
                icon: const Icon(Icons.extension_outlined),
              ),
            ],
            selected: {_isGuestGame},
            onSelectionChanged: (Set<bool> selection) {
              setState(() {
                _isGuestGame = selection.first;
                _selectedGame = widget.preselectedGame;
                _guestNameController.clear();
              });
            },
          ),
          const SizedBox(height: 12),

          // Game selection
          if (_isGuestGame)
            TextFormField(
              controller: _guestNameController,
              decoration: InputDecoration(
                hintText: s.resultsGameHint,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.extension_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            )
          else
            Consumer<GameProvider>(
              builder: (context, provider, _) {
                if (provider.games.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        s.resultsNoGames,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return DropdownButtonFormField<BoardGame>(
                  value: _selectedGame,
                  hint: Text(s.resultsGameDropdownHint),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.casino),
                  ),
                  isExpanded: true,
                  items: provider.games
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g.name, overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (g) => setState(() {
                    _selectedGame = g;
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
                      s.expansionOf(_expansionOriginName!),
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
                    const SizedBox(height: 12),
                    Text(s.expansionsTitle,
                        style: theme.textTheme.titleMedium),
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
          const SizedBox(height: 20),

          // Date
          Text(s.resultsDate, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today_outlined),
                isDense: false,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formattedDate),
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Duration
          Text(s.resultsDuration, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NumberField(controller: _hoursController, label: s.resultsHours, max: 99),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(controller: _minutesController, label: s.resultsMinutes, max: 59),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Players header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.newSessionPlayers, style: theme.textTheme.titleMedium),
              TextButton.icon(
                onPressed: _addPlayerRow,
                icon: const Icon(Icons.person_add),
                label: Text(s.resultsAddPlayer),
              ),
            ],
          ),
          Text(
            s.resultsScoresHint,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
          if (availableQuick.isNotEmpty) ...[
            const SizedBox(height: 6),
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

          // Player rows
          ...List.generate(_nameControllers.length, (i) {
            final rank = finalRanks['$i'] ?? 0;
            final inTieGroup = tieGroups.values.any((g) => g.contains('$i'));
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Rank badge
                    SizedBox(
                      width: 52,
                      child: rank == 0
                          ? const Center(
                              child: Text('—',
                                  style: TextStyle(color: Colors.grey, fontSize: 18)))
                          : Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: inTieGroup
                                      ? Colors.orange
                                      : rank == 1
                                          ? Colors.amber
                                          : theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  s.ordinal(rank),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: inTieGroup || rank == 1
                                        ? Colors.white
                                        : theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _nameControllers[i],
                        decoration: InputDecoration(
                          hintText: s.resultsPlayerHint(i + 1),
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _scoreControllers[i],
                        decoration: InputDecoration(
                          hintText: s.resultsScore,
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(signed: true),
                        textAlign: TextAlign.center,
                        onChanged: (_) => _onScoreChanged(),
                      ),
                    ),
                    if (_nameControllers.length > 2)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => _removePlayerRow(i),
                      ),
                  ],
                ),
              ),
            );
          }),

          // Tie resolution section
          if (hasTies) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.balance, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Text(
                  s.resultsTieTitle,
                  style: theme.textTheme.titleSmall?.copyWith(color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              s.resultsTieHintTap,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 8),
            ...tieGroups.entries.map((entry) {
              final baseRank = entry.key;
              final ordered = _tieOrder[baseRank] ?? entry.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      s.resultsTiedAt(baseRank),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...List.generate(ordered.length, (i) {
                    final playerIdx = int.parse(ordered[i]);
                    final name = _nameControllers[playerIdx].text.trim();
                    final displayName =
                        name.isEmpty ? s.resultsPlayerHint(playerIdx + 1) : name;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 4),
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.orange,
                              child: Text(
                                s.ordinal(baseRank + i),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(displayName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_upward, size: 20),
                              onPressed: i == 0
                                  ? null
                                  : () => setState(() {
                                        final list = List<String>.from(ordered);
                                        final item = list.removeAt(i);
                                        list.insert(i - 1, item);
                                        _tieOrder[baseRank] = list;
                                      }),
                              color: Colors.orange,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 36, minHeight: 36),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_downward, size: 20),
                              onPressed: i == ordered.length - 1
                                  ? null
                                  : () => setState(() {
                                        final list = List<String>.from(ordered);
                                        final item = list.removeAt(i);
                                        list.insert(i + 1, item);
                                        _tieOrder[baseRank] = list;
                                      }),
                              color: Colors.orange,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 36, minHeight: 36),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              );
            }),
            TextField(
              controller: _tiebreakerController,
              decoration: InputDecoration(
                labelText: s.resultsTiebreakerLabel,
                hintText: s.resultsTiebreakerHint,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_note, color: Colors.orange),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
          ],

          // Notes
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: s.resultsNotesLabel,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: s.sessionLocationLabel,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.place_outlined),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: Text(s.resultsSaveButton),
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int max;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        suffixText: label,
        isDense: false,
      ),
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _RangeFormatter(max),
      ],
    );
  }
}

class _RangeFormatter extends TextInputFormatter {
  final int max;
  const _RangeFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final n = int.tryParse(newValue.text);
    if (n == null || n > max) return oldValue;
    return newValue;
  }
}
