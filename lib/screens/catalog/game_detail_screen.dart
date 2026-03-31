import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/board_game.dart';
import '../../providers/game_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/settings_provider.dart';
// ignore_for_file: use_build_context_synchronously
import '../../providers/session_provider.dart';
import '../../services/bgg_service.dart';
import '../session/play_landing_screen.dart';
import 'add_game_screen.dart';

class GameDetailScreen extends StatefulWidget {
  final BoardGame game;
  const GameDetailScreen({super.key, required this.game});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  List<BggExpansionItem> _bggExpansions = [];
  bool _expansionsLoading = false;
  bool _expansionsLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.game.bggId != null && !widget.game.isExpansion) {
      _loadExpansions();
    }
  }

  Future<void> _loadExpansions() async {
    setState(() => _expansionsLoading = true);
    try {
      final result = await BggService().fetchExpansions(widget.game.bggId!);
      if (mounted) {
        setState(() {
          _bggExpansions = result;
          _expansionsLoaded = true;
          _expansionsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _expansionsLoaded = true;
          _expansionsLoading = false;
        });
      }
    }
  }

  Future<void> _linkToBgg(BuildContext context, BoardGame game) async {
    final result = await showModalBottomSheet<BggSearchResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _BggSearchSheet(gameName: game.name),
    );
    if (result == null || !mounted) return;
    await context.read<GameProvider>().updateGame(game.copyWith(bggId: result.id));
    _loadExpansions();
  }

  Future<void> _addExpansion(BoardGame game, BggExpansionItem item) async {
    await context.read<GameProvider>().addExpansion(
          item: item,
          baseGameId: game.id,
        );
    if (mounted) {
      final s = context.read<LanguageProvider>().strings;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${s.expansionAdded}: ${item.name}'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allGames = context.watch<GameProvider>().games;
    final game = allGames.firstWhere(
          (g) => g.id == widget.game.id,
          orElse: () => widget.game,
        );
    final s = context.watch<LanguageProvider>().strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(game.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddGameScreen(game: game)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, game),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Base game card for expansions
          if (game.isExpansion) ...[
            _BaseGameSection(game: game),
            const SizedBox(height: 16),
          ],

          if (game.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                game.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.group),
                      const SizedBox(width: 8),
                      Text(s.catalogGamePlayers(game.minPlayers, game.maxPlayers),
                          style: Theme.of(context).textTheme.bodyLarge),
                      if (game.isSealed) ...[
                        const SizedBox(width: 10),
                        Chip(
                          label: const Text('SEALED',
                              style: TextStyle(fontSize: 11, color: Colors.white)),
                          backgroundColor: Colors.teal.shade600,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          avatar: const Icon(Icons.inventory_2_outlined,
                              size: 14, color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                  if (game.minPlaytime != null || game.maxPlaytime != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined),
                        const SizedBox(width: 8),
                        Text(
                          _playtimeLabel(game.minPlaytime, game.maxPlaytime),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ],
                  if (game.bggRating != null || game.complexity != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(s.gameDetailBgg,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: Theme.of(context).colorScheme.outline)),
                        const SizedBox(width: 8),
                        if (game.bggRating != null) ...[
                          const Icon(Icons.star_outline, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text('${game.bggRating!.toStringAsFixed(1)} / 10',
                              style: Theme.of(context).textTheme.bodyLarge),
                        ],
                        if (game.bggRating != null && game.complexity != null)
                          const SizedBox(width: 16),
                        if (game.complexity != null) ...[
                          const Icon(Icons.psychology_outlined, size: 18),
                          const SizedBox(width: 4),
                          Text('${game.complexity!.toStringAsFixed(1)} / 5',
                              style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ],
                    ),
                  ],
                  ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(s.gameDetailMine,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
                        const SizedBox(width: 8),
                        Icon(Icons.star,
                            color: game.myRating != null
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                            size: 18),
                        const SizedBox(width: 4),
                        Text(
                          game.myRating != null
                              ? '${game.myRating!.toStringAsFixed(1)} / 10'
                              : '— / 10',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: game.myRating != null
                                  ? null
                                  : Theme.of(context).colorScheme.outline),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.psychology,
                            color: game.myWeight != null
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                            size: 18),
                        const SizedBox(width: 4),
                        Text(
                          game.myWeight != null
                              ? '${game.myWeight!.toStringAsFixed(1)} / 5'
                              : '— / 5',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: game.myWeight != null
                                  ? null
                                  : Theme.of(context).colorScheme.outline),
                        ),
                      ],
                    ),
                  ],
                  if (game.categories.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(s.pickerCategories,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: game.categories
                          .map((c) => Chip(
                                label: Text(c,
                                    style: const TextStyle(fontSize: 11)),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  ],
                  if (game.mechanics.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(s.pickerMechanics,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: game.mechanics
                          .map((m) => Chip(
                                label: Text(m,
                                    style: const TextStyle(fontSize: 11)),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  ],
                  if (game.description != null &&
                      game.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(game.description!),
                  ],
                  // ── Purchase info ──
                  if (game.acquiredAt != null ||
                      game.boughtPrice != null ||
                      game.currentPrice != null) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Consumer<SessionProvider>(
                      builder: (context, sessions, _) => _PriceRows(
                        game: game,
                        allGames: allGames,
                        s: s,
                        sessionCount: sessions.sessionsForGame(game.id).length,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (game.setupHints != null && game.setupHints!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(s.gameDetailSetupHints,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.amber),
                    const SizedBox(width: 12),
                    Expanded(child: Text(game.setupHints!)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(s.gameDetailPlayHistory, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Consumer<SessionProvider>(
            builder: (context, provider, _) {
              final sessions = provider.sessionsForGame(game.id);
              if (sessions.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(s.gameDetailNoSessions,
                        style: const TextStyle(color: Colors.grey)),
                  ),
                );
              }
              return Column(
                children: sessions.map((session) {
                  final winner = session.players.isNotEmpty
                      ? session.players.first.playerName
                      : '?';
                  final date = session.startTime;
                  final dateStr = context.watch<SettingsProvider>().formatDate(date);
                  return ListTile(
                    leading:
                        const Icon(Icons.emoji_events, color: Colors.amber),
                    title: Text(winner),
                    subtitle: Text(dateStr),
                    trailing: Text(session.durationFormatted),
                  );
                }).toList(),
              );
            },
          ),

          // Expansions section — only for base games
          if (!game.isExpansion) ...[
            const SizedBox(height: 16),
            _ExpansionsSection(
              game: game,
              bggExpansions: _bggExpansions,
              expansionsLoading: _expansionsLoading,
              expansionsLoaded: _expansionsLoaded,
              onAddExpansion: (item) => _addExpansion(game, item),
              onLinkToBgg: () => _linkToBgg(context, game),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PlayLandingScreen(preselectedGame: game)),
        ),
        icon: const Icon(Icons.play_arrow),
        label: Text(s.gameDetailPlayNow),
      ),
    );
  }

  String _playtimeLabel(int? min, int? max) {
    if (min != null && max != null) {
      return min == max ? '$min min' : '$min–$max min';
    }
    if (min != null) return '$min+ min';
    if (max != null) return 'up to $max min';
    return '';
  }

  void _confirmDelete(BuildContext context, BoardGame game) {
    final s = context.read<LanguageProvider>().strings;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteGameTitle),
        content: Text(s.deleteGameContent(game.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel)),
          FilledButton(
            onPressed: () {
              context.read<GameProvider>().deleteGame(game.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text(s.delete),
          ),
        ],
      ),
    );
  }
}

// ─── Base game section (shown at top for expansions) ─────────────────────────

class _BaseGameSection extends StatelessWidget {
  final BoardGame game;
  const _BaseGameSection({required this.game});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final gameProvider = context.watch<GameProvider>();

    BoardGame? baseGame;
    if (game.baseGameId != null) {
      try {
        baseGame = gameProvider.games.firstWhere((g) => g.id == game.baseGameId);
      } catch (_) {
        baseGame = null;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.expansionBaseGame,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            if (baseGame != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundImage: (baseGame.thumbnailUrl ?? baseGame.imageUrl) != null
                      ? NetworkImage(baseGame.thumbnailUrl ?? baseGame.imageUrl!)
                      : null,
                  child: (baseGame.thumbnailUrl ?? baseGame.imageUrl) == null
                      ? Text(baseGame.name[0].toUpperCase())
                      : null,
                ),
                title: Text(baseGame.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => GameDetailScreen(game: baseGame!)),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  game.baseGameId != null ? '—' : '—',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Expansions section (shown at bottom for base games) ─────────────────────

class _ExpansionsSection extends StatelessWidget {
  final BoardGame game;
  final List<BggExpansionItem> bggExpansions;
  final bool expansionsLoading;
  final bool expansionsLoaded;
  final void Function(BggExpansionItem item) onAddExpansion;
  final VoidCallback onLinkToBgg;

  const _ExpansionsSection({
    required this.game,
    required this.bggExpansions,
    required this.expansionsLoading,
    required this.expansionsLoaded,
    required this.onAddExpansion,
    required this.onLinkToBgg,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final gameProvider = context.watch<GameProvider>();

    // Owned expansions from collection
    final ownedExpansions = gameProvider.games
        .where((g) => g.baseGameId == game.id)
        .toList();

    // Build a set of owned bggIds for fast lookup
    final ownedBggIds = ownedExpansions
        .where((g) => g.bggId != null)
        .map((g) => g.bggId!)
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(s.expansionsTitle,
                style: Theme.of(context).textTheme.titleMedium),
            if (expansionsLoading) ...[
              const SizedBox(width: 10),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // No BGG link — show hint + link button
        if (game.bggId == null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ownedExpansions.isEmpty)
                    Text(s.expansionNoBgg,
                        style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onLinkToBgg,
                    icon: const Icon(Icons.link),
                    label: Text(s.expansionLinkToBgg),
                  ),
                ],
              ),
            ),
          ),

        // Owned expansions always shown first
        if (ownedExpansions.isNotEmpty)
          ...ownedExpansions.map((exp) => _ExpansionTile(
                name: exp.name,
                thumbnailUrl: exp.thumbnailUrl ?? exp.imageUrl,
                year: null,
                bggRating: exp.bggRating,
                isOwned: true,
                onAdd: null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => GameDetailScreen(game: exp)),
                ),
              )),

        // BGG expansions (after loading)
        if (expansionsLoaded && bggExpansions.isEmpty && game.bggId != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(s.expansionNone,
                  style: const TextStyle(color: Colors.grey)),
            ),
          ),

        if (expansionsLoaded && bggExpansions.isNotEmpty)
          ...bggExpansions
              .where((item) => !ownedBggIds.contains(item.bggId))
              .map((item) => _ExpansionTile(
                    name: item.name,
                    thumbnailUrl: item.thumbnailUrl,
                    year: item.yearPublished,
                    bggRating: item.bggRating,
                    isOwned: false,
                    onAdd: () => onAddExpansion(item),
                    onTap: null,
                  )),
      ],
    );
  }
}

// ─── BGG link search sheet ────────────────────────────────────────────────────

class _BggSearchSheet extends StatefulWidget {
  final String gameName;
  const _BggSearchSheet({required this.gameName});

  @override
  State<_BggSearchSheet> createState() => _BggSearchSheetState();
}

class _BggSearchSheetState extends State<_BggSearchSheet> {
  late final TextEditingController _controller;
  final _bgg = BggService();
  List<BggSearchResult> _results = [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.gameName);
    // Auto-search with the game name
    WidgetsBinding.instance.addPostFrameCallback((_) => _search(widget.gameName));
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _search(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() { _results = []; _searching = false; });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final r = await _bgg.searchGames(value.trim());
        if (mounted) setState(() { _results = r; _searching = false; });
      } catch (_) {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16, 20, 16,
        16 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Link to BGG',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Search BGG...',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : null,
            ),
            onChanged: _search,
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final r = _results[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: r.thumbnailUrl != null
                        ? NetworkImage(r.thumbnailUrl!)
                        : null,
                    child: r.thumbnailUrl == null
                        ? Text(r.name[0].toUpperCase())
                        : null,
                  ),
                  title: Text(r.name),
                  subtitle: r.year != null ? Text('${r.year}') : null,
                  trailing: r.bggRating != null
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_outline,
                                size: 14, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(r.bggRating!.toStringAsFixed(1),
                                style: theme.textTheme.bodySmall),
                          ],
                        )
                      : null,
                  onTap: () => Navigator.pop(context, r),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Expansion tile ───────────────────────────────────────────────────────────

class _ExpansionTile extends StatelessWidget {
  final String name;
  final String? thumbnailUrl;
  final int? year;
  final double? bggRating;
  final bool isOwned;
  final VoidCallback? onAdd;
  final VoidCallback? onTap;

  const _ExpansionTile({
    required this.name,
    required this.thumbnailUrl,
    required this.year,
    required this.bggRating,
    required this.isOwned,
    required this.onAdd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final theme = Theme.of(context);

    final subtitleParts = <String>[];
    if (year != null) subtitleParts.add('$year');
    if (bggRating != null) subtitleParts.add('BGG: ${bggRating!.toStringAsFixed(1)}');
    final subtitle = subtitleParts.isEmpty ? null : subtitleParts.join('  •  ');

    Widget trailing;
    if (isOwned) {
      trailing = Chip(
        label: Text(s.expansionOwned),
        labelStyle: const TextStyle(fontSize: 11, color: Colors.white),
        backgroundColor: Colors.green.shade600,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      );
    } else {
      trailing = IconButton(
        icon: const Icon(Icons.add_circle_outline),
        tooltip: s.expansionAdd,
        onPressed: onAdd,
        color: theme.colorScheme.primary,
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              thumbnailUrl != null ? NetworkImage(thumbnailUrl!) : null,
          child: thumbnailUrl == null
              ? const Icon(Icons.extension)
              : null,
        ),
        title: Text(name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

// ─── Price rows ───────────────────────────────────────────────────────────────

class _PriceRows extends StatelessWidget {
  final BoardGame game;
  final List<BoardGame> allGames;
  final dynamic s;
  final int sessionCount;

  const _PriceRows({
    required this.game,
    required this.allGames,
    required this.s,
    required this.sessionCount,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final symbol = settings.currencySymbol;

    String _fmt(double v) => '${v.toStringAsFixed(2)} $symbol';

    // Expansions owned for this base game
    final expansions = game.isExpansion
        ? <BoardGame>[]
        : allGames.where((g) => g.baseGameId == game.id).toList();

    final expansionBought = expansions
        .where((e) => e.boughtPrice != null)
        .fold<double>(0, (sum, e) => sum + e.boughtPrice!);
    final expansionCurrent = expansions
        .where((e) => e.currentPrice != null)
        .fold<double>(0, (sum, e) => sum + e.currentPrice!);
    final hasExpansionPrices = expansions.any(
        (e) => e.boughtPrice != null || e.currentPrice != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (game.acquiredAt != null)
          _PriceRow(
            icon: Icons.calendar_today_outlined,
            label: s.gameDetailAcquiredAt,
            value: settings.formatDate(game.acquiredAt!),
          ),
        if (game.boughtPrice != null) ...[
          if (game.acquiredAt != null) const SizedBox(height: 4),
          _PriceRow(
            icon: Icons.shopping_cart_outlined,
            label: s.gameDetailBoughtPrice,
            value: _fmt(game.boughtPrice!),
          ),
        ],
        if (game.currentPrice != null) ...[
          const SizedBox(height: 4),
          _PriceRow(
            icon: Icons.sell_outlined,
            label: s.gameDetailCurrentPrice,
            value: _fmt(game.currentPrice!),
            gain: game.boughtPrice != null
                ? game.currentPrice! - game.boughtPrice!
                : null,
          ),
        ],
        // Cost per play — only when there's a bought price and at least 1 session
        if (game.boughtPrice != null && sessionCount > 0) ...[
          const SizedBox(height: 4),
          _PriceRow(
            icon: Icons.calculate_outlined,
            label: s.gameDetailCostPerPlay,
            value: '${(game.boughtPrice! / sessionCount).toStringAsFixed(2)} $symbol',
            subtitle: '$sessionCount× played',
          ),
        ],
        // With all expansions row — only for base games with priced expansions
        if (!game.isExpansion && hasExpansionPrices) ...[
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 6),
          Text(s.gameDetailWithExpansions,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.outline,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          if (game.boughtPrice != null || expansionBought > 0)
            _PriceRow(
              icon: Icons.shopping_cart_outlined,
              label: s.gameDetailBoughtPrice,
              value: _fmt((game.boughtPrice ?? 0) + expansionBought),
            ),
          if (game.currentPrice != null || expansionCurrent > 0) ...[
            const SizedBox(height: 4),
            _PriceRow(
              icon: Icons.sell_outlined,
              label: s.gameDetailCurrentPrice,
              value: _fmt((game.currentPrice ?? 0) + expansionCurrent),
              gain: (game.boughtPrice != null || expansionBought > 0)
                  ? ((game.currentPrice ?? 0) + expansionCurrent) -
                      ((game.boughtPrice ?? 0) + expansionBought)
                  : null,
            ),
          ],
          if ((game.boughtPrice != null || expansionBought > 0) && sessionCount > 0) ...[
            const SizedBox(height: 4),
            _PriceRow(
              icon: Icons.calculate_outlined,
              label: s.gameDetailCostPerPlay,
              value: _fmt(((game.boughtPrice ?? 0) + expansionBought) / sessionCount),
              subtitle: '$sessionCount× played',
            ),
          ],
        ],
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double? gain;
  final String? subtitle;

  const _PriceRow({
    required this.icon,
    required this.label,
    required this.value,
    this.gain,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(width: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
        if (gain != null) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: gain! >= 0
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${gain! >= 0 ? '+' : ''}${gain!.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: gain! >= 0 ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(width: 6),
          Text(
            subtitle!,
            style: TextStyle(
                fontSize: 11, color: theme.colorScheme.outline),
          ),
        ],
      ],
    );
  }
}
