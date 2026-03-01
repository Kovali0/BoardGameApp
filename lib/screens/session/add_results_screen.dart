import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/board_game.dart';
import '../../providers/game_provider.dart';
import '../../providers/session_provider.dart';

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

  DateTime _date = DateTime.now();
  final _hoursController = TextEditingController(text: '0');
  final _minutesController = TextEditingController(text: '30');

  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _scoreControllers = [];
  List<int> _ranks = [];

  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedGame = widget.preselectedGame;
    _addPlayerRow();
    _addPlayerRow();
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _notesController.dispose();
    for (final c in _nameControllers) {
      c.dispose();
    }
    for (final c in _scoreControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addPlayerRow() {
    setState(() {
      _nameControllers.add(TextEditingController());
      _scoreControllers.add(TextEditingController());
      _ranks.add(0);
    });
  }

  void _removePlayerRow(int index) {
    if (_nameControllers.length <= 2) return;
    setState(() {
      _nameControllers[index].dispose();
      _scoreControllers[index].dispose();
      _nameControllers.removeAt(index);
      _scoreControllers.removeAt(index);
      _ranks.removeAt(index);
    });
  }

  void _autoRank() {
    final indexed = List.generate(_nameControllers.length, (i) {
      final text = _scoreControllers[i].text.trim();
      return (index: i, score: text.isEmpty ? null : int.tryParse(text));
    });
    final sorted = List.of(indexed)
      ..sort((a, b) {
        if (a.score == null && b.score == null) return 0;
        if (a.score == null) return 1;
        if (b.score == null) return -1;
        return b.score!.compareTo(a.score!);
      });
    setState(() {
      final newRanks = List.filled(_nameControllers.length, 0);
      for (int i = 0; i < sorted.length; i++) {
        newRanks[sorted[i].index] = i + 1;
      }
      _ranks = newRanks;
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

  String get _formattedDate =>
      '${_date.day.toString().padLeft(2, '0')}.${_date.month.toString().padLeft(2, '0')}.${_date.year}';

  String _ordinal(int n) {
    if (n == 1) return '1st';
    if (n == 2) return '2nd';
    if (n == 3) return '3rd';
    return '${n}th';
  }

  Future<void> _save() async {
    // Resolve game
    BoardGame? game;
    if (_isGuestGame) {
      final name = _guestNameController.text.trim();
      if (name.isEmpty) {
        _snack('Enter a game name');
        return;
      }
      game = BoardGame(
        id: const Uuid().v4(),
        name: name,
        minPlayers: 1,
        maxPlayers: 20,
        createdAt: DateTime.now(),
      );
    } else {
      if (_selectedGame == null) {
        _snack('Please select a game');
        return;
      }
      game = _selectedGame!;
    }

    // Resolve duration
    final hours = int.tryParse(_hoursController.text.trim()) ?? 0;
    final minutes = int.tryParse(_minutesController.text.trim()) ?? 0;
    final totalSeconds = hours * 3600 + minutes * 60;
    if (totalSeconds <= 0) {
      _snack('Duration must be at least 1 minute');
      return;
    }

    // Resolve players
    final players = <Map<String, dynamic>>[];
    for (int i = 0; i < _nameControllers.length; i++) {
      final name = _nameControllers[i].text.trim();
      if (name.isEmpty) continue;
      final scoreText = _scoreControllers[i].text.trim();
      players.add({
        'name': name,
        'score': scoreText.isEmpty ? null : int.tryParse(scoreText),
        'rank': _ranks[i] == 0 ? 1 : _ranks[i],
        'startedGame': false,
      });
    }
    if (players.length < 2) {
      _snack('Add at least 2 players');
      return;
    }

    final startTime = DateTime(_date.year, _date.month, _date.day, 12, 0);
    final endTime = startTime.add(Duration(seconds: totalSeconds));

    await context.read<SessionProvider>().saveSession(
          gameId: game.id,
          gameName: game.name,
          startTime: startTime,
          endTime: endTime,
          durationSeconds: totalSeconds,
          playerData: players,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          isFromCollection: !_isGuestGame,
        );

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Results')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Game toggle
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('My Collection'),
                icon: Icon(Icons.casino_outlined),
              ),
              ButtonSegment(
                value: true,
                label: Text('Other Game'),
                icon: Icon(Icons.extension_outlined),
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
              decoration: const InputDecoration(
                hintText: 'Game name...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.extension_outlined),
              ),
              textCapitalization: TextCapitalization.words,
            )
          else
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
                      .map((g) => DropdownMenuItem(value: g, child: Text(g.name)))
                      .toList(),
                  onChanged: (g) => setState(() => _selectedGame = g),
                );
              },
            ),
          const SizedBox(height: 20),

          // Date
          Text('Date', style: Theme.of(context).textTheme.titleMedium),
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
                  Text(_formattedDate),
                  const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Duration
          Text('Duration', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  controller: _hoursController,
                  label: 'h',
                  max: 99,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumberField(
                  controller: _minutesController,
                  label: 'min',
                  max: 59,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Players
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Players', style: Theme.of(context).textTheme.titleMedium),
              Row(
                children: [
                  TextButton(
                    onPressed: _autoRank,
                    child: const Text('Auto Rank'),
                  ),
                  TextButton.icon(
                    onPressed: _addPlayerRow,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(_nameControllers.length, (i) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    DropdownButton<int>(
                      value: _ranks[i] == 0 ? null : _ranks[i],
                      hint: const Text('#'),
                      items: List.generate(
                        _nameControllers.length,
                        (r) => DropdownMenuItem(
                          value: r + 1,
                          child: Text(_ordinal(r + 1)),
                        ),
                      ),
                      onChanged: (rank) =>
                          setState(() => _ranks[i] = rank ?? 0),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _nameControllers[i],
                        decoration: InputDecoration(
                          hintText: 'Player ${i + 1}',
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
                        decoration: const InputDecoration(
                          hintText: 'Score',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
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
          const SizedBox(height: 8),

          // Notes
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save Session'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
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
