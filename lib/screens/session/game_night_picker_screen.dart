import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/strings.dart';
import '../../models/board_game.dart';
import '../../providers/game_provider.dart';
import '../../providers/language_provider.dart';
import 'play_landing_screen.dart';

// Complexity buckets (BGG scale 1–5)
enum _Complexity { any, light, medium, heavy }

// Year era
enum _YearEra { any, classic, modern, recent }

// Time presets in minutes; null = no limit
const _kTimePresets = [30, 60, 90, 120, 180, null];

class GameNightPickerScreen extends StatefulWidget {
  const GameNightPickerScreen({super.key});

  @override
  State<GameNightPickerScreen> createState() => _GameNightPickerScreenState();
}

class _GameNightPickerScreenState extends State<GameNightPickerScreen> {
  int _players = 4;
  int? _maxMinutes = 90; // null = no limit
  _Complexity _complexity = _Complexity.any;
  bool _notPlayedYet = false;
  bool _familyFriendly = false;
  _YearEra _yearEra = _YearEra.any;
  Set<String> _selectedCategories = {};
  Set<String> _selectedMechanics = {};
  String? _randomPickId; // highlighted after random pick

  List<BoardGame> _filter(List<BoardGame> all) {
    return all.where((g) {
      // Skip expansions — they depend on a base game
      if (g.isExpansion) return false;
      // Players
      if (g.minPlayers > _players || g.maxPlayers < _players) return false;
      // Time: if we have a limit and the game has a playtime, check it fits
      if (_maxMinutes != null && g.maxPlaytime != null) {
        if (g.maxPlaytime! > _maxMinutes!) return false;
      }
      // Complexity
      if (_complexity != _Complexity.any && g.complexity != null) {
        final c = g.complexity!;
        switch (_complexity) {
          case _Complexity.light:
            if (c > 2.0) return false;
          case _Complexity.medium:
            if (c <= 2.0 || c > 3.5) return false;
          case _Complexity.heavy:
            if (c <= 3.5) return false;
          case _Complexity.any:
            break;
        }
      }
      // Not played yet
      if (_notPlayedYet && g.hasBeenPlayed) return false;
      // Family friendly
      if (_familyFriendly && g.minAge != null && g.minAge! > 10) return false;
      // Year era
      if (_yearEra != _YearEra.any && g.yearPublished != null) {
        final y = g.yearPublished!;
        switch (_yearEra) {
          case _YearEra.classic:
            if (y > 2000) return false;
          case _YearEra.modern:
            if (y <= 2000 || y > 2015) return false;
          case _YearEra.recent:
            if (y <= 2015) return false;
          case _YearEra.any:
            break;
        }
      }
      // Categories (any-of match)
      if (_selectedCategories.isNotEmpty &&
          !g.categories.any((c) => _selectedCategories.contains(c))) {
        return false;
      }
      // Mechanics (any-of match)
      if (_selectedMechanics.isNotEmpty &&
          !g.mechanics.any((m) => _selectedMechanics.contains(m))) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        // Sort by BGG rating desc, unrated last
        final ra = a.bggRating ?? 0;
        final rb = b.bggRating ?? 0;
        return rb.compareTo(ra);
      });
  }

  void _pickRandom(List<BoardGame> matches) {
    if (matches.isEmpty) return;
    final pick = matches[Random().nextInt(matches.length)];
    setState(() => _randomPickId = pick.id);
  }

  void _pickAndGo(BuildContext context, List<BoardGame> matches) {
    if (matches.isEmpty) return;
    final pick = matches[Random().nextInt(matches.length)];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayLandingScreen(preselectedGame: pick),
      ),
    );
  }

  String _timeLabel(int? minutes, AppStrings s) {
    if (minutes == null) return s.pickerNoLimit;
    if (minutes < 60) return '${minutes}m';
    if (minutes % 60 == 0) return '${minutes ~/ 60}h';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final allGames = context.watch<GameProvider>().games;
    final matches = _filter(allGames);
    final theme = Theme.of(context);

    // Collect unique categories and mechanics from all non-expansion games
    final allCategories = allGames
        .where((g) => !g.isExpansion)
        .expand((g) => g.categories)
        .toSet()
        .toList()
      ..sort();
    final allMechanics = allGames
        .where((g) => !g.isExpansion)
        .expand((g) => g.mechanics)
        .toSet()
        .toList()
      ..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.pickerTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Players ──────────────────────────────────────────────────────
          Text(s.pickerPlayers, style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepButton(
                icon: Icons.remove,
                onPressed: _players > 1
                    ? () => setState(() {
                          _players--;
                          _randomPickId = null;
                        })
                    : null,
              ),
              const SizedBox(width: 24),
              Text(
                '$_players',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 24),
              _StepButton(
                icon: Icons.add,
                onPressed: _players < 20
                    ? () => setState(() {
                          _players++;
                          _randomPickId = null;
                        })
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Time ─────────────────────────────────────────────────────────
          Text(s.pickerTime, style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _kTimePresets.map((minutes) {
              final label = _timeLabel(minutes, s);
              final selected = _maxMinutes == minutes;
              return ChoiceChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => setState(() {
                  _maxMinutes = minutes;
                  _randomPickId = null;
                }),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // ── Complexity ───────────────────────────────────────────────────
          Text(s.pickerComplexity, style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _ComplexityChip(
                label: s.pickerComplexityAny,
                value: _Complexity.any,
                current: _complexity,
                onTap: () => setState(() {
                  _complexity = _Complexity.any;
                  _randomPickId = null;
                }),
              ),
              _ComplexityChip(
                label: s.pickerComplexityLight,
                value: _Complexity.light,
                current: _complexity,
                onTap: () => setState(() {
                  _complexity = _Complexity.light;
                  _randomPickId = null;
                }),
                subtitle: '≤ 2.0',
              ),
              _ComplexityChip(
                label: s.pickerComplexityMedium,
                value: _Complexity.medium,
                current: _complexity,
                onTap: () => setState(() {
                  _complexity = _Complexity.medium;
                  _randomPickId = null;
                }),
                subtitle: '2.0 – 3.5',
              ),
              _ComplexityChip(
                label: s.pickerComplexityHeavy,
                value: _Complexity.heavy,
                current: _complexity,
                onTap: () => setState(() {
                  _complexity = _Complexity.heavy;
                  _randomPickId = null;
                }),
                subtitle: '> 3.5',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Not played yet toggle ────────────────────────────────────────
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.pickerNotPlayedYet,
                style: theme.textTheme.titleMedium),
            value: _notPlayedYet,
            onChanged: (v) => setState(() {
              _notPlayedYet = v;
              _randomPickId = null;
            }),
          ),

          // ── Family friendly toggle ───────────────────────────────────────
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.pickerFamilyFriendly,
                style: theme.textTheme.titleMedium),
            value: _familyFriendly,
            onChanged: (v) => setState(() {
              _familyFriendly = v;
              _randomPickId = null;
            }),
          ),

          const SizedBox(height: 8),

          // ── Year era ─────────────────────────────────────────────────────
          Text(s.pickerYearEra, style: theme.textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: Text(s.filterAll),
                selected: _yearEra == _YearEra.any,
                onSelected: (_) => setState(() {
                  _yearEra = _YearEra.any;
                  _randomPickId = null;
                }),
              ),
              ChoiceChip(
                label: Text(s.pickerYearClassic),
                selected: _yearEra == _YearEra.classic,
                onSelected: (_) => setState(() {
                  _yearEra = _YearEra.classic;
                  _randomPickId = null;
                }),
              ),
              ChoiceChip(
                label: Text(s.pickerYearModern),
                selected: _yearEra == _YearEra.modern,
                onSelected: (_) => setState(() {
                  _yearEra = _YearEra.modern;
                  _randomPickId = null;
                }),
              ),
              ChoiceChip(
                label: Text(s.pickerYearRecent),
                selected: _yearEra == _YearEra.recent,
                onSelected: (_) => setState(() {
                  _yearEra = _YearEra.recent;
                  _randomPickId = null;
                }),
              ),
            ],
          ),

          // ── Categories ───────────────────────────────────────────────────
          if (allCategories.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(s.pickerCategories, style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: allCategories.map((cat) {
                final selected = _selectedCategories.contains(cat);
                return FilterChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    if (selected) {
                      _selectedCategories.remove(cat);
                    } else {
                      _selectedCategories.add(cat);
                    }
                    _randomPickId = null;
                  }),
                );
              }).toList(),
            ),
          ],

          // ── Mechanics ────────────────────────────────────────────────────
          if (allMechanics.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(s.pickerMechanics, style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: allMechanics.map((mech) {
                final selected = _selectedMechanics.contains(mech);
                return FilterChip(
                  label: Text(mech),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    if (selected) {
                      _selectedMechanics.remove(mech);
                    } else {
                      _selectedMechanics.add(mech);
                    }
                    _randomPickId = null;
                  }),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 8),

          // ── Results header ───────────────────────────────────────────────
          const Divider(),
          const SizedBox(height: 12),

          if (matches.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _pickAndGo(context, matches),
                icon: const Icon(Icons.casino),
                label: Text(s.pickerPickGame),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          const SizedBox(height: 12),

          if (matches.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.search_off,
                      size: 56, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text(s.pickerNoResults,
                      style: TextStyle(color: theme.colorScheme.outline)),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.pickerResults(matches.length),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ),
                if (matches.length > 1)
                  FilledButton.tonalIcon(
                    onPressed: () => _pickRandom(matches),
                    icon: const Icon(Icons.casino_outlined, size: 18),
                    label: Text(s.pickerRandomPick),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...matches.map((game) => _GameResultCard(
                  game: game,
                  isHighlighted: game.id == _randomPickId,
                  playLabel: s.pickerPlay,
                )),
          ],
        ],
      ),
    );
  }
}

// ─── Step button ──────────────────────────────────────────────────────────────

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _StepButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      icon: Icon(icon),
      onPressed: onPressed,
      iconSize: 28,
    );
  }
}

// ─── Complexity chip ─────────────────────────────────────────────────────────

class _ComplexityChip extends StatelessWidget {
  final String label;
  final String? subtitle;
  final _Complexity value;
  final _Complexity current;
  final VoidCallback onTap;

  const _ComplexityChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    final theme = Theme.of(context);
    return ChoiceChip(
      label: subtitle != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label),
                Text(subtitle!,
                    style: TextStyle(
                        fontSize: 10,
                        color: selected
                            ? theme.colorScheme.onSecondaryContainer
                            : theme.colorScheme.outline)),
              ],
            )
          : Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

// ─── Game result card ─────────────────────────────────────────────────────────

class _GameResultCard extends StatelessWidget {
  final BoardGame game;
  final bool isHighlighted;
  final String playLabel;

  const _GameResultCard({
    required this.game,
    required this.isHighlighted,
    required this.playLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = game.thumbnailUrl ?? game.imageUrl;

    String? playtimeText;
    if (game.minPlaytime != null && game.maxPlaytime != null) {
      if (game.minPlaytime == game.maxPlaytime) {
        playtimeText = '${game.minPlaytime}m';
      } else {
        playtimeText = '${game.minPlaytime}–${game.maxPlaytime}m';
      }
    } else if (game.maxPlaytime != null) {
      playtimeText = '≤ ${game.maxPlaytime}m';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted
            ? Border.all(color: theme.colorScheme.primary, width: 2)
            : null,
        color: isHighlighted
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surface,
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withAlpha(60),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Thumbnail
            CircleAvatar(
              radius: 26,
              backgroundImage:
                  imageUrl != null ? NetworkImage(imageUrl) : null,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: imageUrl == null
                  ? Text(game.name[0].toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      _InfoBadge(
                        icon: Icons.people_outline,
                        label:
                            '${game.minPlayers}–${game.maxPlayers}',
                      ),
                      if (playtimeText != null)
                        _InfoBadge(
                          icon: Icons.timer_outlined,
                          label: playtimeText,
                        ),
                      if (game.bggRating != null)
                        _InfoBadge(
                          icon: Icons.star_outline,
                          label: game.bggRating!.toStringAsFixed(1),
                          color: Colors.amber.shade700,
                        ),
                      if (game.complexity != null)
                        _InfoBadge(
                          icon: Icons.psychology_outlined,
                          label: game.complexity!.toStringAsFixed(1),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Play button
            FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayLandingScreen(preselectedGame: game),
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(64, 40),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(playLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _InfoBadge({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 2),
        Text(label, style: TextStyle(fontSize: 12, color: c)),
      ],
    );
  }
}
