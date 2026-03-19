import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../models/board_game.dart';
import 'add_game_screen.dart';
import 'game_detail_screen.dart';

// ─── Filter state ─────────────────────────────────────────────────────────────

class _Filters {
  final int? players;       // game must support exactly this many players
  final int? maxMinutes;    // max playtime bucket (null = any)
  final double? minRating;  // minimum rating threshold
  final int? weightBucket;  // 1=Light, 2=Medium, 3=Heavy (null = any)
  final bool notPlayedOnly;

  const _Filters({
    this.players,
    this.maxMinutes,
    this.minRating,
    this.weightBucket,
    this.notPlayedOnly = false,
  });

  bool get isActive =>
      players != null ||
      maxMinutes != null ||
      minRating != null ||
      weightBucket != null ||
      notPlayedOnly;

  bool matches(BoardGame g) {
    // Players
    if (players != null) {
      if (g.minPlayers > players! || g.maxPlayers < players!) return false;
    }
    // Time — use maxPlaytime if available, else minPlaytime
    if (maxMinutes != null) {
      final t = g.maxPlaytime ?? g.minPlaytime;
      if (maxMinutes == -1) {
        // "Long" bucket: > 120 min
        if (t != null && t <= 120) return false;
      } else {
        if (t != null && t > maxMinutes!) return false;
      }
    }
    // Rating — use myRating if set, else bggRating
    if (minRating != null) {
      final r = g.myRating ?? g.bggRating;
      if (r == null || r < minRating!) return false;
    }
    // Weight — use myWeight if set, else complexity
    if (weightBucket != null) {
      final w = g.myWeight ?? g.complexity;
      if (w == null) return false;
      if (weightBucket == 1 && w > 2.0) return false;
      if (weightBucket == 2 && (w <= 2.0 || w > 3.5)) return false;
      if (weightBucket == 3 && w <= 3.5) return false;
    }
    // Not played
    if (notPlayedOnly && g.hasBeenPlayed) return false;

    return true;
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  _Filters _filters = const _Filters();
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet(BuildContext context, List<BoardGame> games) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FilterSheet(
        initial: _filters,
        onApply: (f) => setState(() => _filters = f),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Games Collection'),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterSheet(
                    context, context.read<GameProvider>().games),
              ),
              if (_filters.isActive)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search game...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),
          Expanded(
            child: Consumer<GameProvider>(
        builder: (context, provider, _) {
          if (provider.games.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.casino_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No games yet. Add your first game!',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final q = _searchQuery.toLowerCase();
          final filtered = provider.games.where((g) {
            if (!_filters.matches(g)) return false;
            if (q.isNotEmpty && !g.name.toLowerCase().contains(q)) return false;
            return true;
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.filter_list_off,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No games match your search or filters.',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() {
                      _filters = const _Filters();
                      _searchQuery = '';
                      _searchController.clear();
                    }),
                    child: const Text('Clear search & filters'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: filtered.length,
            itemBuilder: (context, index) =>
                _GameCard(game: filtered[index]),
          );
        },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddGameScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Game'),
      ),
    );
  }
}

// ─── Filter bottom sheet ──────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final _Filters initial;
  final ValueChanged<_Filters> onApply;

  const _FilterSheet({required this.initial, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  int? _players;
  int? _maxMinutes;
  double? _minRating;
  int? _weightBucket;
  bool _notPlayedOnly = false;

  @override
  void initState() {
    super.initState();
    _players = widget.initial.players;
    _maxMinutes = widget.initial.maxMinutes;
    _minRating = widget.initial.minRating;
    _weightBucket = widget.initial.weightBucket;
    _notPlayedOnly = widget.initial.notPlayedOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 20, 16,
          16 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter games',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => setState(() {
                    _players = null;
                    _maxMinutes = null;
                    _minRating = null;
                    _weightBucket = null;
                    _notPlayedOnly = false;
                  }),
                  child: const Text('Clear all'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Players
            _FilterSection(
              label: 'Players',
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final n in [1, 2, 3, 4, 5, 6, 7, 8])
                    FilterChip(
                      label: Text(n == 8 ? '8+' : '$n'),
                      selected: _players == n,
                      onSelected: (_) =>
                          setState(() => _players = _players == n ? null : n),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Time
            _FilterSection(
              label: 'Playtime',
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _timeChip('≤ 30 min', 30),
                  _timeChip('≤ 60 min', 60),
                  _timeChip('≤ 120 min', 120),
                  _timeChip('Long (120+)', -1),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Rating
            _FilterSection(
              label: 'Min Rating',
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final r in [6.0, 7.0, 8.0, 9.0])
                    FilterChip(
                      label: Text('${r.toStringAsFixed(0)}+'),
                      selected: _minRating == r,
                      onSelected: (_) => setState(
                          () => _minRating = _minRating == r ? null : r),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Weight
            _FilterSection(
              label: 'Weight',
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _weightChip('Light (≤2)', 1),
                  _weightChip('Medium', 2),
                  _weightChip('Heavy (3.5+)', 3),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Not played
            _FilterSection(
              label: 'Status',
              child: FilterChip(
                label: const Text('Not played yet'),
                selected: _notPlayedOnly,
                onSelected: (v) => setState(() => _notPlayedOnly = v),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  widget.onApply(_Filters(
                    players: _players,
                    maxMinutes: _maxMinutes,
                    minRating: _minRating,
                    weightBucket: _weightBucket,
                    notPlayedOnly: _notPlayedOnly,
                  ));
                  Navigator.pop(context);
                },
                child: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeChip(String label, int value) {
    return FilterChip(
      label: Text(label),
      selected: _maxMinutes == value,
      onSelected: (_) =>
          setState(() => _maxMinutes = _maxMinutes == value ? null : value),
    );
  }

  Widget _weightChip(String label, int bucket) {
    return FilterChip(
      label: Text(label),
      selected: _weightBucket == bucket,
      onSelected: (_) => setState(
          () => _weightBucket = _weightBucket == bucket ? null : bucket),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _FilterSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ─── Game card ────────────────────────────────────────────────────────────────

class _GameCard extends StatelessWidget {
  final BoardGame game;
  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: (game.thumbnailUrl ?? game.imageUrl) != null
              ? NetworkImage(game.thumbnailUrl ?? game.imageUrl!)
              : null,
          child: (game.thumbnailUrl ?? game.imageUrl) == null
              ? Text(game.name[0].toUpperCase())
              : null,
        ),
        title: Text(game.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${game.minPlayers}–${game.maxPlayers} players'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => context.read<GameProvider>().togglePlayed(game.id),
              child: Icon(
                game.hasBeenPlayed ? Icons.check_circle : Icons.circle,
                color: game.hasBeenPlayed
                    ? Colors.green
                    : Colors.amber.shade700,
                size: 22,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GameDetailScreen(game: game)),
        ),
      ),
    );
  }
}
