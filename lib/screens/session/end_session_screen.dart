import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/board_game.dart';
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
              'rank': 0,
              'startedGame': name == widget.starterName,
              'scoreController': TextEditingController(),
            })
        .toList();
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final p in _playerData) {
      (p['scoreController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _autoRank() {
    for (final p in _playerData) {
      final text =
          (p['scoreController'] as TextEditingController).text.trim();
      p['score'] = text.isEmpty ? null : int.tryParse(text);
    }
    final sorted = List<Map<String, dynamic>>.from(_playerData)
      ..sort((a, b) {
        final sa = a['score'] as int?;
        final sb = b['score'] as int?;
        if (sa == null && sb == null) return 0;
        if (sa == null) return 1;
        if (sb == null) return -1;
        return sb.compareTo(sa);
      });
    setState(() {
      for (int i = 0; i < sorted.length; i++) {
        sorted[i]['rank'] = i + 1;
      }
    });
  }

  Future<void> _save() async {
    for (final p in _playerData) {
      final text =
          (p['scoreController'] as TextEditingController).text.trim();
      p['score'] = text.isEmpty ? null : int.tryParse(text);
      if ((p['rank'] as int) == 0) p['rank'] = 1;
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
                    'rank': p['rank'],
                    'startedGame': p['startedGame'],
                  })
              .toList(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          isFromCollection: widget.isFromCollection,
        );

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  String _ordinal(int n) {
    if (n == 1) return '1st';
    if (n == 2) return '2nd';
    if (n == 3) return '3rd';
    return '${n}th';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Over!'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(
                      icon: Icons.casino, label: widget.game.name),
                  _SummaryItem(
                      icon: Icons.timer, label: _formattedDuration),
                  _SummaryItem(
                      icon: Icons.group,
                      label: '${widget.players.length} players'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Results',
                  style: Theme.of(context).textTheme.titleMedium),
              TextButton(
                onPressed: _autoRank,
                child: const Text('Auto Rank by Score'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(_playerData.length, (i) {
            final p = _playerData[i];
            final currentRank = p['rank'] as int;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    DropdownButton<int>(
                      value: currentRank == 0 ? null : currentRank,
                      hint: const Text('#'),
                      items: List.generate(
                        widget.players.length,
                        (r) => DropdownMenuItem(
                          value: r + 1,
                          child: Text(_ordinal(r + 1)),
                        ),
                      ),
                      onChanged: (rank) =>
                          setState(() => p['rank'] = rank ?? 0),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['name'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          if (p['startedGame'] as bool)
                            const Text('started',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.amber)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller:
                            p['scoreController'] as TextEditingController,
                        decoration: const InputDecoration(
                          hintText: 'Score',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
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
                minimumSize: const Size.fromHeight(52)),
          ),
        ],
      ),
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
