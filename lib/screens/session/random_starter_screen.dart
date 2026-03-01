import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/board_game.dart';
import 'active_session_screen.dart';

class RandomStarterScreen extends StatefulWidget {
  final BoardGame game;
  final List<String> players;
  const RandomStarterScreen(
      {super.key, required this.game, required this.players});

  @override
  State<RandomStarterScreen> createState() => _RandomStarterScreenState();
}

class _RandomStarterScreenState extends State<RandomStarterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  int _currentHighlight = 0;
  String? _winner;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _spin() async {
    if (_isSpinning) return;
    setState(() {
      _isSpinning = true;
      _winner = null;
    });

    final random = Random();
    final totalSteps = 20 + random.nextInt(12);
    for (int i = 0; i < totalSteps; i++) {
      await Future.delayed(Duration(milliseconds: 70 + (i * 7)));
      if (!mounted) return;
      setState(() => _currentHighlight = i % widget.players.length);
    }

    final winnerIndex = random.nextInt(widget.players.length);
    if (!mounted) return;
    setState(() {
      _currentHighlight = winnerIndex;
      _winner = widget.players[winnerIndex];
      _isSpinning = false;
    });
    _controller.forward().then((_) => _controller.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.game.name)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              'Who starts the game?',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.players.asMap().entries.map((entry) {
                  final isHighlighted = entry.key == _currentHighlight;
                  final isWinner = _winner != null && entry.value == _winner;

                  Widget tile = AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 24),
                    decoration: BoxDecoration(
                      color: isWinner
                          ? Theme.of(context).colorScheme.primaryContainer
                          : isHighlighted
                              ? Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: isWinner
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isWinner) ...[
                          const Icon(Icons.emoji_events, color: Colors.amber),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          entry.value,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: isHighlighted || isWinner
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                        ),
                        if (isWinner) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.emoji_events, color: Colors.amber),
                        ],
                      ],
                    ),
                  );

                  if (isWinner) {
                    tile = ScaleTransition(scale: _scaleAnim, child: tile);
                  }
                  return tile;
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            if (_winner != null) ...[
              Text(
                '${_winner!} goes first!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActiveSessionScreen(
                      game: widget.game,
                      players: widget.players,
                      starterName: _winner!,
                    ),
                  ),
                ),
                icon: const Icon(Icons.timer),
                label: const Text('Start Game!'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ] else
              FilledButton.icon(
                onPressed: _isSpinning ? null : _spin,
                icon: const Icon(Icons.shuffle),
                label: Text(_isSpinning ? 'Spinning...' : 'Spin!'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
