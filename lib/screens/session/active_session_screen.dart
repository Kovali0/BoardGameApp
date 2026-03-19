import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/board_game.dart';
import 'end_session_screen.dart';

class ActiveSessionScreen extends StatefulWidget {
  final BoardGame game;
  final List<String> players;
  final String starterName;
  final bool isFromCollection;

  const ActiveSessionScreen({
    super.key,
    required this.game,
    required this.players,
    required this.starterName,
    this.isFromCollection = true,
  });

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  late final DateTime _startTime;
  late Timer _timer;
  bool _isPaused = false;
  DateTime? _pausedAt;
  int _totalPausedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    // Timer only drives UI redraws — elapsed time is always derived from wall clock.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isPaused) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  int get _elapsedSeconds {
    final base = (_isPaused ? _pausedAt! : DateTime.now())
        .difference(_startTime)
        .inSeconds;
    return base - _totalPausedSeconds;
  }

  String get _formatted {
    final secs = _elapsedSeconds;
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _togglePause() {
    setState(() {
      if (_isPaused) {
        _totalPausedSeconds +=
            DateTime.now().difference(_pausedAt!).inSeconds;
        _pausedAt = null;
        _isPaused = false;
      } else {
        _pausedAt = DateTime.now();
        _isPaused = true;
      }
    });
  }

  void _showAbandonDialog() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abandon Game?'),
        content: const Text('The current session will be lost.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Continue')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Abandon')),
        ],
      ),
    ).then((confirm) {
      if (confirm == true && mounted) Navigator.pop(context);
    });
  }

  void _endGame() {
    _timer.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => EndSessionScreen(
          game: widget.game,
          players: widget.players,
          starterName: widget.starterName,
          startTime: _startTime,
          durationSeconds: _elapsedSeconds,
          isFromCollection: widget.isFromCollection,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showAbandonDialog();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.game.name),
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showAbandonDialog,
          ),
        ),
        body: SafeArea(
          child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  _formatted,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text('${widget.starterName} starts',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: widget.players
                    .map((p) => Chip(
                          avatar: const Icon(Icons.person, size: 16),
                          label: Text(p),
                        ))
                    .toList(),
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _togglePause,
                      icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                      label: Text(_isPaused ? 'Resume' : 'Pause'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _endGame,
                      icon: const Icon(Icons.flag),
                      label: const Text('End Game'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
