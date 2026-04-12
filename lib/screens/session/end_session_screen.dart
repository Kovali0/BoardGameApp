import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/board_game.dart';
import '../../providers/game_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/ranking_service.dart';
import 'game_results_screen.dart';

const _kTeamColors = [
  Color(0xFF1E88E5),
  Color(0xFFE53935),
  Color(0xFF43A047),
  Color(0xFF8E24AA),
  Color(0xFFFF7043),
  Color(0xFF00ACC1),
];

class EndSessionScreen extends StatefulWidget {
  final BoardGame game;
  final List<String> players;
  final String starterName;
  final DateTime startTime;
  final int durationSeconds;
  final bool isFromCollection;
  final List<String> expansionIds;
  final Map<String, String> teamAssignments;

  const EndSessionScreen({
    super.key,
    required this.game,
    required this.players,
    required this.starterName,
    required this.startTime,
    required this.durationSeconds,
    this.isFromCollection = true,
    this.expansionIds = const [],
    this.teamAssignments = const {},
  });

  @override
  State<EndSessionScreen> createState() => _EndSessionScreenState();
}

class _EndSessionScreenState extends State<EndSessionScreen> {
  late List<Map<String, dynamic>> _playerData;
  final _notesController = TextEditingController();
  final _tiebreakerController = TextEditingController();
  final _locationController = TextEditingController();

  // For each base rank that has a tie, stores the user-ordered list of player names.
  final Map<int, List<String>> _tieOrder = {};

  // Team mode
  final Map<String, TextEditingController> _teamScoreControllers = {};
  Map<String, int?> _teamScores = {};

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
              'teamController': TextEditingController(text: widget.teamAssignments[name] ?? ''),
            })
        .toList();

    // Init team score controllers if teams are pre-assigned
    if (widget.teamAssignments.isNotEmpty) {
      final teams = widget.teamAssignments.values.toSet();
      for (final team in teams) {
        _teamScoreControllers[team] = TextEditingController();
        _teamScores[team] = null;
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _tiebreakerController.dispose();
    _locationController.dispose();
    for (final p in _playerData) {
      (p['scoreController'] as TextEditingController).dispose();
      (p['teamController'] as TextEditingController).dispose();
    }
    for (final c in _teamScoreControllers.values) c.dispose();
    super.dispose();
  }

  // ── Team helpers ──

  Map<String, List<String>> get _teamGroups {
    final groups = <String, List<String>>{};
    for (final p in _playerData) {
      final team = (p['teamController'] as TextEditingController).text.trim();
      if (team.isNotEmpty) {
        groups.putIfAbsent(team, () => []).add(p['name'] as String);
      }
    }
    return groups;
  }

  bool get _isTeamMode => widget.teamAssignments.isNotEmpty || _teamGroups.isNotEmpty;

  List<String> get _sortedTeamNames => _teamGroups.keys.toList()..sort();

  Color _teamColor(String teamName) {
    final idx = _sortedTeamNames.indexOf(teamName);
    return _kTeamColors[(idx < 0 ? 0 : idx) % _kTeamColors.length];
  }

  void _onTeamScoreChanged() {
    for (final entry in _teamScoreControllers.entries) {
      final text = entry.value.text.trim();
      _teamScores[entry.key] = text.isEmpty ? null : int.tryParse(text);
    }
    setState(() {});
  }

  Map<String, int> _computeTeamRanks() {
    final teams = _teamGroups.keys.toList();
    final scored = teams.where((t) => _teamScores[t] != null).toList()
      ..sort((a, b) => _teamScores[b]!.compareTo(_teamScores[a]!));

    final result = <String, int>{};
    for (final t in teams) {
      if (_teamScores[t] == null) result[t] = 0;
    }
    int rank = 1;
    for (int i = 0; i < scored.length; i++) {
      if (i > 0 && _teamScores[scored[i]] != _teamScores[scored[i - 1]]) {
        rank = i + 1;
      }
      result[scored[i]] = rank;
    }
    return result;
  }

  // ── Individual helpers ──

  void _readScores() {
    for (final p in _playerData) {
      final text = (p['scoreController'] as TextEditingController).text.trim();
      p['score'] = text.isEmpty ? null : int.tryParse(text);
    }
  }

  Map<String, int?> get _playerScores => {
        for (final p in _playerData)
          p['name'] as String: p['score'] as int?,
      };

  void _onScoreChanged() {
    _readScores();
    final base = RankingService.computeBaseRanks(_playerScores);
    setState(() {
      _tieOrder
        ..clear()
        ..addAll(RankingService.syncTieOrder(base, _tieOrder));
    });
  }

  Future<void> _save() async {
    final tieNote = _tiebreakerController.text.trim();
    final generalNote = _notesController.text.trim();

    List<Map<String, dynamic>> saveData;
    List<Map<String, dynamic>> resultsData;
    Map<String, String> finalTeamAssignments = widget.teamAssignments;

    if (_isTeamMode) {
      // Build team assignments from user input if not pre-assigned
      if (widget.teamAssignments.isEmpty) {
        finalTeamAssignments = {};
        for (final p in _playerData) {
          final team = (p['teamController'] as TextEditingController).text.trim();
          if (team.isNotEmpty) {
            finalTeamAssignments[p['name'] as String] = team;
          }
        }
      }

      // Ensure team score controllers are initialized
      if (_teamScoreControllers.isEmpty) {
        final teams = finalTeamAssignments.values.toSet();
        for (final team in teams) {
          _teamScoreControllers[team] = TextEditingController();
          _teamScores[team] = null;
        }
      }

      // Team mode
      final teamRanks = _computeTeamRanks();
      saveData = _playerData.map((p) {
        final name = p['name'] as String;
        final team = finalTeamAssignments[name] ?? '';
        return {
          'name': name,
          'score': _teamScores[team],
          'rank': teamRanks[team] ?? 0,
          'startedGame': p['startedGame'],
          'teamName': team.isNotEmpty ? team : null,
        };
      }).toList();
      resultsData = saveData
          .map((p) => {'name': p['name'], 'rank': p['rank'], 'score': p['score']})
          .toList();
    } else {
      // Individual mode
      _readScores();
      final base = RankingService.computeBaseRanks(_playerScores);
      final finalRanks = RankingService.computeFinalRanks(base, _tieOrder);
      saveData = _playerData
          .map((p) => {
                'name': p['name'],
                'score': p['score'],
                'rank': finalRanks[p['name'] as String] ?? 0,
                'startedGame': p['startedGame'],
              })
          .toList();
      resultsData = _playerData
          .map((p) => {
                'name': p['name'],
                'rank': finalRanks[p['name'] as String] ?? 0,
                'score': p['score'],
              })
          .toList();
    }

    final location = _locationController.text.trim();
    await context.read<SessionProvider>().saveSession(
          gameId: widget.game.id,
          gameName: widget.game.name,
          startTime: widget.startTime,
          endTime: DateTime.now(),
          durationSeconds: widget.durationSeconds,
          playerData: saveData,
          notes: generalNote.isEmpty ? null : generalNote,
          isFromCollection: widget.isFromCollection,
          expansionIds: widget.expansionIds,
          location: location.isEmpty ? null : location,
          tiebreaker: tieNote.isEmpty ? null : tieNote,
        );

    if (mounted) {
      await context.read<GameProvider>().markAsPlayed(widget.game.id);
    }
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GameResultsScreen(
            game: widget.isFromCollection ? widget.game : null,
            gameName: widget.game.name,
            durationSeconds: widget.durationSeconds,
            playerResults: resultsData,
            teamAssignments: finalTeamAssignments,
          ),
        ),
      );
    }
  }


  Widget _buildTeamCard(
    String teamName,
    List<String> members,
    Map<String, int> teamRanks,
    ThemeData theme,
    dynamic s,
  ) {
    final rank = teamRanks[teamName] ?? 0;
    final color = _teamColor(teamName);
    final controller = _teamScoreControllers[teamName];
    if (controller == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
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
                          color: rank == 1 ? Colors.amber : theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.ordinal(rank),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: rank == 1
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(teamName,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    members.join(', '),
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 90,
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: s.resultsScore,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                textAlign: TextAlign.center,
                onChanged: (_) => _onTeamScoreChanged(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final theme = Theme.of(context);
    final isTeamMode = _isTeamMode;
    final base = isTeamMode
        ? <String, int>{}
        : RankingService.computeBaseRanks(_playerScores);
    final tieGroups = isTeamMode
        ? <int, List<String>>{}
        : RankingService.computeTieGroups(base);
    final finalRanks = isTeamMode
        ? <String, int>{}
        : RankingService.computeFinalRanks(base, _tieOrder);
    final hasTies = tieGroups.isNotEmpty;
    final teamRanks = isTeamMode ? _computeTeamRanks() : <String, int>{};

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
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SummaryItem(icon: Icons.casino, label: widget.game.name),
                      _SummaryItem(icon: Icons.timer, label: _formattedDuration),
                      _SummaryItem(
                          icon: Icons.group,
                          label: '${widget.players.length} players'),
                    ],
                  ),
                  if (widget.expansionIds.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Consumer<GameProvider>(
                      builder: (context, provider, _) {
                        final expansions = widget.expansionIds
                            .map((id) => provider.games
                                .where((g) => g.id == id)
                                .firstOrNull)
                            .whereType<BoardGame>()
                            .toList();
                        if (expansions.isEmpty) return const SizedBox.shrink();
                        return Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          alignment: WrapAlignment.center,
                          children: expansions
                              .map((e) => Chip(
                                    label: Text(e.name,
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.white)),
                                    backgroundColor: Colors.deepPurple.shade400,
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    avatar: const Icon(Icons.extension,
                                        size: 14, color: Colors.white70),
                                  ))
                              .toList(),
                        );
                      },
                    ),
                  ],
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

          // Score cards — team mode or individual mode
          if (isTeamMode) ...[
            for (final entry in _teamGroups.entries) ...[
              _buildTeamCard(entry.key, entry.value, teamRanks, theme, s),
              const SizedBox(height: 8),
            ],
          ] else ...[
            ...List.generate(_playerData.length, (i) {
              final p = _playerData[i];
              final name = p['name'] as String;
              final rank = finalRanks[name] ?? 0;
              final inTieGroup =
                  tieGroups.values.any((g) => g.contains(name));

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
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
                                          : theme.colorScheme.onPrimaryContainer,
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
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
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              signed: true),
                          textAlign: TextAlign.center,
                          onChanged: (_) => _onScoreChanged(),
                        ),
                      ),
                      if (widget.teamAssignments.isEmpty) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: p['teamController'] as TextEditingController,
                            decoration: InputDecoration(
                              hintText: s.teamAssign,
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.words,
                            textAlign: TextAlign.center,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],

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
