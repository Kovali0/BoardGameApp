import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/board_game.dart';
import '../../providers/game_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/session_provider.dart';

class EndSessionScreen extends StatefulWidget {
  final BoardGame game;
  final List<String> players;
  final String starterName;
  final DateTime startTime;
  final int durationSeconds;
  final bool isFromCollection;

  const EndSessionScreen({
    super.key,
    required this.game,
    required this.players,
    required this.starterName,
    required this.startTime,
    required this.durationSeconds,
    this.isFromCollection = true,
  });

  @override
  State<EndSessionScreen> createState() => _EndSessionScreenState();
}

class _EndSessionScreenState extends State<EndSessionScreen> {
  late List<Map<String, dynamic>> _playerData;
  final _notesController = TextEditingController();
  final _tiebreakerController = TextEditingController();

  // For each base rank that has a tie, stores the user-ordered list of player names.
  // First in list = wins the tiebreak (gets the lower rank number).
  final Map<int, List<String>> _tieOrder = {};

  String get _formattedDuration {
    final h = widget.durationSeconds ~/ 3600;
    final m = (widget.durationSeconds % 3600) ~/ 60;
    final s = widget.durationSeconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  void initState() {
    super.initState();
    _playerData = widget.players
        .map((name) => {
              'name': name,
              'score': null as int?,
              'startedGame': name == widget.starterName,
              'scoreController': TextEditingController(),
            })
        .toList();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _tiebreakerController.dispose();
    for (final p in _playerData) {
      (p['scoreController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _readScores() {
    for (final p in _playerData) {
      final text = (p['scoreController'] as TextEditingController).text.trim();
      p['score'] = text.isEmpty ? null : int.tryParse(text);
    }
  }

  /// Base ranks: equal scores share the same rank. Unscored players get rank 0.
  Map<String, int> _computeBaseRanks() {
    final scored = _playerData.where((p) => p['score'] != null).toList()
      ..sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    final result = <String, int>{};
    for (final p in _playerData) {
      if (p['score'] == null) result[p['name'] as String] = 0;
    }

    int rank = 1;
    for (int i = 0; i < scored.length; i++) {
      if (i > 0 && scored[i]['score'] != scored[i - 1]['score']) rank = i + 1;
      result[scored[i]['name'] as String] = rank;
    }
    return result;
  }

  /// Tie groups: only groups with 2+ players. Uses _playerData order for stability.
  Map<int, List<String>> _computeTieGroups(Map<String, int> baseRanks) {
    final groups = <int, List<String>>{};
    for (final p in _playerData) {
      final name = p['name'] as String;
      final rank = baseRanks[name];
      if (rank == null || rank == 0) continue;
      groups.putIfAbsent(rank, () => []).add(name);
    }
    return Map.fromEntries(groups.entries.where((e) => e.value.length > 1));
  }

  /// Final ranks after applying tiebreaker ordering.
  Map<String, int> _computeFinalRanks() {
    final base = _computeBaseRanks();
    final tieGroups = _computeTieGroups(base);
    final result = Map<String, int>.from(base);

    for (final entry in tieGroups.entries) {
      final baseRank = entry.key;
      final order = _tieOrder[baseRank] ?? entry.value;
      for (int i = 0; i < order.length; i++) {
        result[order[i]] = baseRank + i;
      }
    }
    return result;
  }

  void _onScoreChanged() {
    _readScores();
    final base = _computeBaseRanks();
    final tieGroups = _computeTieGroups(base);

    setState(() {
      // Sync _tieOrder: add new groups, update membership, remove resolved ones.
      for (final entry in tieGroups.entries) {
        final rank = entry.key;
        final newPlayers = entry.value.toSet();
        if (_tieOrder.containsKey(rank)) {
          // Preserve existing order but sync membership.
          final updated = _tieOrder[rank]!.where(newPlayers.contains).toList();
          for (final p in newPlayers) {
            if (!updated.contains(p)) updated.add(p);
          }
          _tieOrder[rank] = updated;
        } else {
          _tieOrder[rank] = List.from(entry.value);
        }
      }
      _tieOrder.removeWhere((rank, _) => !tieGroups.containsKey(rank));
    });
  }

  Future<void> _save() async {
    _readScores();
    final finalRanks = _computeFinalRanks();

    final tieNote = _tiebreakerController.text.trim();
    final generalNote = _notesController.text.trim();
    String? combinedNotes;
    if (tieNote.isNotEmpty && generalNote.isNotEmpty) {
      combinedNotes = '[Tiebreaker: $tieNote]\n$generalNote';
    } else if (tieNote.isNotEmpty) {
      combinedNotes = '[Tiebreaker: $tieNote]';
    } else if (generalNote.isNotEmpty) {
      combinedNotes = generalNote;
    }

    await context.read<SessionProvider>().saveSession(
          gameId: widget.game.id,
          gameName: widget.game.name,
          startTime: widget.startTime,
          endTime: DateTime.now(),
          durationSeconds: widget.durationSeconds,
          playerData: _playerData
              .map((p) => {
                    'name': p['name'],
                    'score': p['score'],
                    'rank': finalRanks[p['name'] as String] ?? 0,
                    'startedGame': p['startedGame'],
                  })
              .toList(),
          notes: combinedNotes,
          isFromCollection: widget.isFromCollection,
        );

    if (mounted) {
      await context.read<GameProvider>().markAsPlayed(widget.game.id);
    }
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }


  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final theme = Theme.of(context);
    final finalRanks = _computeFinalRanks();
    final base = _computeBaseRanks();
    final tieGroups = _computeTieGroups(base);
    final hasTies = tieGroups.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.endSessionTitle),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(icon: Icons.casino, label: widget.game.name),
                  _SummaryItem(icon: Icons.timer, label: _formattedDuration),
                  _SummaryItem(
                      icon: Icons.group,
                      label: '${widget.players.length} players'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(s.sessionDetailResults, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            s.resultsScoresHint,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 8),

          // Player score cards
          ...List.generate(_playerData.length, (i) {
            final p = _playerData[i];
            final name = p['name'] as String;
            final rank = finalRanks[name] ?? 0;
            final inTieGroup = tieGroups.values.any((g) => g.contains(name));

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Auto rank badge
                    SizedBox(
                      width: 52,
                      child: rank == 0
                          ? const Center(
                              child: Text('—',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 18)))
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
                                        : theme
                                            .colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (p['startedGame'] as bool)
                            Text(s.endSessionStarted,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.amber)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller:
                            p['scoreController'] as TextEditingController,
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
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              s.resultsTieHintDrag,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 8),
            ...tieGroups.entries.map((entry) {
              final baseRank = entry.key;
              final ordered = _tieOrder[baseRank] ?? entry.value;
              return _TieGroup(
                baseRank: baseRank,
                orderedPlayers: ordered,
                ordinal: s.ordinal,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    final list = List<String>.from(ordered);
                    final item = list.removeAt(oldIndex);
                    list.insert(newIndex, item);
                    _tieOrder[baseRank] = list;
                  });
                },
              );
            }),
            const SizedBox(height: 4),
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

          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: s.resultsNotesLabel,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 2,
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

class _TieGroup extends StatelessWidget {
  final int baseRank;
  final List<String> orderedPlayers;
  final String Function(int) ordinal;
  final void Function(int oldIndex, int newIndex) onReorder;

  const _TieGroup({
    required this.baseRank,
    required this.orderedPlayers,
    required this.ordinal,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final theme = Theme.of(context);
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
        ...List.generate(orderedPlayers.length, (i) {
          final name = orderedPlayers[i];
          final isFirst = i == 0;
          final isLast = i == orderedPlayers.length - 1;
          return Card(
            margin: const EdgeInsets.only(bottom: 4),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.orange,
                    child: Text(
                      ordinal(baseRank + i),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  // Up button
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 20),
                    onPressed: isFirst ? null : () => onReorder(i, i - 1),
                    color: Colors.orange,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  // Down button
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, size: 20),
                    onPressed: isLast ? null : () => onReorder(i, i + 1),
                    color: Colors.orange,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SummaryItem({required this.icon, required this.label});

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
