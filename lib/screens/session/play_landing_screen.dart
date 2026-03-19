import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../models/board_game.dart';
import 'new_session_screen.dart';
import 'add_results_screen.dart';

class PlayLandingScreen extends StatelessWidget {
  final BoardGame? preselectedGame;
  const PlayLandingScreen({super.key, this.preselectedGame});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.playLandingTitle),
        centerTitle: true,
        automaticallyImplyLeading: preselectedGame != null,
      ),
      body: SafeArea(
        child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _OptionCard(
              icon: Icons.timer_outlined,
              title: s.playLandingStartNew,
              subtitle: s.playLandingStartNewSub,
              filled: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      NewSessionScreen(preselectedGame: preselectedGame),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _OptionCard(
              icon: Icons.edit_note_outlined,
              title: s.playLandingAddResults,
              subtitle: s.playLandingAddResultsSub,
              filled: false,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AddResultsScreen(preselectedGame: preselectedGame),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool filled;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor =
        filled ? colorScheme.primaryContainer : colorScheme.surface;
    final iconColor = filled ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Card(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: filled
            ? BorderSide.none
            : BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          child: Row(
            children: [
              Icon(icon, size: 40, color: iconColor),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
