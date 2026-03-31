import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../models/board_game.dart';
import '../../models/wishlist_item.dart';
import 'add_game_screen.dart';
import 'game_detail_screen.dart';
import '../wishlist/add_wishlist_item_screen.dart';
import '../wishlist/wishlist_screen.dart' show WishlistCard, WishlistGridCard;

// ─── Enums ────────────────────────────────────────────────────────────────────

enum _ViewMode { list, grid }

enum _SortOrder { az, za, recentlyAdded, myRating }

enum _GameTypeFilter { all, baseOnly, expansionsOnly }

enum _WishlistSortOrder { az, za, priority, recentlyAdded, priceLow, priceHigh }

// ─── Filter state ─────────────────────────────────────────────────────────────

class _Filters {
  final int? players;
  final int? maxMinutes;
  final double? minRating;
  final int? weightBucket;
  final bool notPlayedOnly;
  final _GameTypeFilter gameTypeFilter;

  const _Filters({
    this.players,
    this.maxMinutes,
    this.minRating,
    this.weightBucket,
    this.notPlayedOnly = false,
    this.gameTypeFilter = _GameTypeFilter.all,
  });

  bool get isActive =>
      players != null ||
      maxMinutes != null ||
      minRating != null ||
      weightBucket != null ||
      notPlayedOnly ||
      gameTypeFilter != _GameTypeFilter.all;

  bool matches(BoardGame g) {
    if (gameTypeFilter == _GameTypeFilter.baseOnly && g.isExpansion) return false;
    if (gameTypeFilter == _GameTypeFilter.expansionsOnly && !g.isExpansion) return false;
    if (players != null) {
      if (g.minPlayers > players! || g.maxPlayers < players!) return false;
    }
    if (maxMinutes != null) {
      final t = g.maxPlaytime ?? g.minPlaytime;
      if (maxMinutes == -1) {
        if (t != null && t <= 120) return false;
      } else {
        if (t != null && t > maxMinutes!) return false;
      }
    }
    if (minRating != null) {
      final r = g.myRating ?? g.bggRating;
      if (r == null || r < minRating!) return false;
    }
    if (weightBucket != null) {
      final w = g.myWeight ?? g.complexity;
      if (w == null) return false;
      if (weightBucket == 1 && w > 2.0) return false;
      if (weightBucket == 2 && (w <= 2.0 || w > 3.5)) return false;
      if (weightBucket == 3 && w <= 3.5) return false;
    }
    if (notPlayedOnly && g.hasBeenPlayed) return false;
    return true;
  }
}

// ─── Sort helper ──────────────────────────────────────────────────────────────

List<BoardGame> _applySortOrder(List<BoardGame> games, _SortOrder sort) {
  final list = List<BoardGame>.from(games);
  switch (sort) {
    case _SortOrder.az:
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    case _SortOrder.za:
      list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    case _SortOrder.recentlyAdded:
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    case _SortOrder.myRating:
      list.sort((a, b) {
        final ra = a.myRating ?? a.bggRating ?? 0.0;
        final rb = b.myRating ?? b.bggRating ?? 0.0;
        return rb.compareTo(ra);
      });
  }
  return list;
}

// ─── Wishlist sort helper ─────────────────────────────────────────────────────

List<WishlistItem> _applyWishlistSort(
    List<WishlistItem> items, _WishlistSortOrder sort) {
  final list = List<WishlistItem>.from(items);
  switch (sort) {
    case _WishlistSortOrder.az:
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    case _WishlistSortOrder.za:
      list.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    case _WishlistSortOrder.priority:
      list.sort((a, b) {
        final pc = b.priority.compareTo(a.priority);
        return pc != 0 ? pc : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    case _WishlistSortOrder.recentlyAdded:
      list.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    case _WishlistSortOrder.priceLow:
      list.sort((a, b) {
        final pa = a.price ?? double.infinity;
        final pb = b.price ?? double.infinity;
        return pa.compareTo(pb);
      });
    case _WishlistSortOrder.priceHigh:
      list.sort((a, b) {
        final pa = a.price ?? -1;
        final pb = b.price ?? -1;
        return pb.compareTo(pa);
      });
  }
  return list;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  _Filters _filters = const _Filters();
  _ViewMode _viewMode = _ViewMode.list;
  _SortOrder _sortOrder = _SortOrder.recentlyAdded;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  // Wishlist tab state
  _ViewMode _wishlistViewMode = _ViewMode.list;
  _WishlistSortOrder _wishlistSortOrder = _WishlistSortOrder.priority;
  int? _wishlistPriorityFilter; // null = all, 1/2/3 = filter by priority

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  void _showWishlistFilterSheet(BuildContext context) {
    final s = context.read<LanguageProvider>().strings;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          int? selected = _wishlistPriorityFilter;
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16,
                16 + MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.wishlistFilterByPriority,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => setModalState(() => selected = null),
                      child: Text(s.catalogFilterClearAll),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: Text(s.wishlistPriorityHigh),
                      selected: selected == 3,
                      onSelected: (_) => setModalState(
                          () => selected = selected == 3 ? null : 3),
                    ),
                    FilterChip(
                      label: Text(s.wishlistPriorityMedium),
                      selected: selected == 2,
                      onSelected: (_) => setModalState(
                          () => selected = selected == 2 ? null : 2),
                    ),
                    FilterChip(
                      label: Text(s.wishlistPriorityLow),
                      selected: selected == 1,
                      onSelected: (_) => setModalState(
                          () => selected = selected == 1 ? null : 1),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() => _wishlistPriorityFilter = selected);
                      Navigator.pop(ctx);
                    },
                    child: Text(s.apply),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final isCollection = _tabController.index == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.catalogTitle),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            isCollection
                ? (_viewMode == _ViewMode.list
                    ? Icons.grid_view
                    : Icons.view_list)
                : (_wishlistViewMode == _ViewMode.list
                    ? Icons.grid_view
                    : Icons.view_list),
          ),
          onPressed: () => setState(() {
            if (isCollection) {
              _viewMode = _viewMode == _ViewMode.list
                  ? _ViewMode.grid
                  : _ViewMode.list;
            } else {
              _wishlistViewMode = _wishlistViewMode == _ViewMode.list
                  ? _ViewMode.grid
                  : _ViewMode.list;
            }
          }),
        ),
        actions: isCollection
            ? [
                PopupMenuButton<_SortOrder>(
                  icon: const Icon(Icons.sort),
                  onSelected: (v) => setState(() => _sortOrder = v),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: _SortOrder.az, child: Text(s.catalogSortAZ)),
                    PopupMenuItem(value: _SortOrder.za, child: Text(s.catalogSortZA)),
                    PopupMenuItem(value: _SortOrder.recentlyAdded, child: Text(s.catalogSortRecentlyAdded)),
                    PopupMenuItem(value: _SortOrder.myRating, child: Text(s.catalogSortMyRating)),
                  ],
                ),
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
              ]
            : [
                PopupMenuButton<_WishlistSortOrder>(
                  icon: const Icon(Icons.sort),
                  onSelected: (v) => setState(() => _wishlistSortOrder = v),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: _WishlistSortOrder.priority, child: Text(s.wishlistSortPriority)),
                    PopupMenuItem(value: _WishlistSortOrder.az, child: Text(s.catalogSortAZ)),
                    PopupMenuItem(value: _WishlistSortOrder.za, child: Text(s.catalogSortZA)),
                    PopupMenuItem(value: _WishlistSortOrder.recentlyAdded, child: Text(s.catalogSortRecentlyAdded)),
                    PopupMenuItem(value: _WishlistSortOrder.priceLow, child: Text(s.wishlistSortPriceLow)),
                    PopupMenuItem(value: _WishlistSortOrder.priceHigh, child: Text(s.wishlistSortPriceHigh)),
                  ],
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () => _showWishlistFilterSheet(context),
                    ),
                    if (_wishlistPriorityFilter != null)
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: s.catalogTabCollection),
            Tab(text: s.catalogTabWishlist),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Collection tab ──────────────────────────────────────────────
          Column(
            children: [
              const _CollectionValueCard(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: s.catalogSearchHint,
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
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.casino_outlined,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(s.catalogEmpty,
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    final q = _searchQuery.toLowerCase();
                    var filtered = provider.games.where((g) {
                      if (!_filters.matches(g)) return false;
                      if (q.isNotEmpty && !g.name.toLowerCase().contains(q))
                        return false;
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
                            Text(s.catalogNoResults,
                                style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => setState(() {
                                _filters = const _Filters();
                                _searchQuery = '';
                                _searchController.clear();
                              }),
                              child: Text(s.catalogClearFilters),
                            ),
                          ],
                        ),
                      );
                    }

                    filtered = _applySortOrder(filtered, _sortOrder);

                    if (_viewMode == _ViewMode.grid) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.82,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) =>
                            _GameGridCard(game: filtered[index]),
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

          // ── Wishlist tab ────────────────────────────────────────────────
          Consumer<WishlistProvider>(
            builder: (context, wishlist, _) {
              if (wishlist.items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bookmark_border,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(s.wishlistEmpty,
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              var filtered = wishlist.items.where((item) {
                if (_wishlistPriorityFilter != null &&
                    item.priority != _wishlistPriorityFilter) return false;
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
                      Text(s.wishlistNoResults,
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(
                            () => _wishlistPriorityFilter = null),
                        child: Text(s.wishlistClearFilters),
                      ),
                    ],
                  ),
                );
              }

              filtered = _applyWishlistSort(filtered, _wishlistSortOrder);

              if (_wishlistViewMode == _ViewMode.grid) {
                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.78,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      WishlistGridCard(item: filtered[index]),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: filtered.length,
                itemBuilder: (context, index) =>
                    WishlistCard(item: filtered[index]),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => isCollection
                ? const AddGameScreen()
                : const AddWishlistItemScreen(),
          ),
        ),
        icon: const Icon(Icons.add),
        label: Text(isCollection ? s.catalogAddGame : s.wishlistAddItem),
      ),
    );
  }
}

// ─── Collection value card ────────────────────────────────────────────────────

class _CollectionValueCard extends StatefulWidget {
  const _CollectionValueCard();

  @override
  State<_CollectionValueCard> createState() => _CollectionValueCardState();
}

class _CollectionValueCardState extends State<_CollectionValueCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    return Consumer<GameProvider>(
      builder: (context, provider, _) {
        final games = provider.games;

        double totalSpent = 0;
        double totalCurrent = 0;
        int tracked = 0;

        for (final g in games) {
          final hasBought = g.boughtPrice != null;
          final hasCurrent = g.currentPrice != null;
          if (hasBought || hasCurrent) tracked++;
          if (hasBought) totalSpent += g.boughtPrice!;
          if (hasCurrent) totalCurrent += g.currentPrice!;
        }

        if (tracked == 0) return const SizedBox.shrink();

        final gain = totalCurrent - totalSpent;
        final gainPositive = gain >= 0;

        return Card(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        s.catalogCollectionValue,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const Spacer(),
                      Text(
                        s.catalogGamesTracked(tracked),
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 18,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ],
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _ValueTile(
                            label: s.catalogTotalSpent,
                            value: totalSpent,
                            icon: Icons.payments_outlined,
                          ),
                        ),
                        Expanded(
                          child: _ValueTile(
                            label: s.catalogCurrentValue,
                            value: totalCurrent,
                            icon: Icons.trending_up,
                          ),
                        ),
                        Expanded(
                          child: _ValueTile(
                            label: s.catalogValueGain,
                            value: gain,
                            icon: gainPositive
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: gainPositive
                                ? Colors.green.shade600
                                : Colors.red.shade400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ValueTile extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color? color;

  const _ValueTile({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurface;
    return Column(
      children: [
        Icon(icon, size: 16, color: effectiveColor),
        const SizedBox(height: 2),
        Text(
          value.toStringAsFixed(2),
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: effectiveColor),
        ),
        Text(
          label,
          style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.outline),
        ),
      ],
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
  _GameTypeFilter _gameTypeFilter = _GameTypeFilter.all;

  @override
  void initState() {
    super.initState();
    _players = widget.initial.players;
    _maxMinutes = widget.initial.maxMinutes;
    _minRating = widget.initial.minRating;
    _weightBucket = widget.initial.weightBucket;
    _notPlayedOnly = widget.initial.notPlayedOnly;
    _gameTypeFilter = widget.initial.gameTypeFilter;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16,
          20,
          16,
          16 +
              MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.catalogFilterTitle,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => setState(() {
                    _players = null;
                    _maxMinutes = null;
                    _minRating = null;
                    _weightBucket = null;
                    _notPlayedOnly = false;
                    _gameTypeFilter = _GameTypeFilter.all;
                  }),
                  child: Text(s.catalogFilterClearAll),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Players
            _FilterSection(
              label: s.catalogFilterPlayers,
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
              label: s.catalogFilterPlaytime,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _timeChip(s.catalogFilterPlaytime30, 30),
                  _timeChip(s.catalogFilterPlaytime60, 60),
                  _timeChip(s.catalogFilterPlaytime120, 120),
                  _timeChip(s.catalogFilterPlaytimeLong, -1),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Rating
            _FilterSection(
              label: s.catalogFilterMinRating,
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
              label: s.catalogFilterWeight,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _weightChip(s.catalogFilterWeightLight, 1),
                  _weightChip(s.catalogFilterWeightMedium, 2),
                  _weightChip(s.catalogFilterWeightHeavy, 3),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Not played
            _FilterSection(
              label: s.catalogFilterStatus,
              child: FilterChip(
                label: Text(s.catalogFilterNotPlayed),
                selected: _notPlayedOnly,
                onSelected: (v) => setState(() => _notPlayedOnly = v),
              ),
            ),
            const SizedBox(height: 12),

            // Game type
            _FilterSection(
              label: s.filterGameType,
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilterChip(
                    label: Text(s.filterAll),
                    selected: _gameTypeFilter == _GameTypeFilter.all,
                    onSelected: (_) => setState(
                        () => _gameTypeFilter = _GameTypeFilter.all),
                  ),
                  FilterChip(
                    label: Text(s.filterGameTypeBase),
                    selected: _gameTypeFilter == _GameTypeFilter.baseOnly,
                    onSelected: (_) => setState(
                        () => _gameTypeFilter = _GameTypeFilter.baseOnly),
                  ),
                  FilterChip(
                    label: Text(s.filterGameTypeExpansions),
                    selected: _gameTypeFilter == _GameTypeFilter.expansionsOnly,
                    onSelected: (_) => setState(
                        () => _gameTypeFilter = _GameTypeFilter.expansionsOnly),
                  ),
                ],
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
                    gameTypeFilter: _gameTypeFilter,
                  ));
                  Navigator.pop(context);
                },
                child: Text(s.apply),
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
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ─── Game list card ───────────────────────────────────────────────────────────

class _GameCard extends StatelessWidget {
  final BoardGame game;
  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
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
        subtitle: game.isExpansion
            ? Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(s.catalogGamePlayers(game.minPlayers, game.maxPlayers)),
                  Chip(
                    label: const Text('EXP',
                        style: TextStyle(fontSize: 10, color: Colors.white)),
                    backgroundColor: Colors.deepPurple.shade400,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              )
            : Text(s.catalogGamePlayers(game.minPlayers, game.maxPlayers)),
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

// ─── Game grid card ───────────────────────────────────────────────────────────

class _GameGridCard extends StatelessWidget {
  final BoardGame game;
  const _GameGridCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final imageUrl = game.thumbnailUrl ?? game.imageUrl;
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GameDetailScreen(game: game)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _GridPlaceholder(name: game.name),
                    )
                  : _GridPlaceholder(name: game.name),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          game.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            context.read<GameProvider>().togglePlayed(game.id),
                        child: Icon(
                          game.hasBeenPlayed
                              ? Icons.check_circle
                              : Icons.circle,
                          color: game.hasBeenPlayed
                              ? Colors.green
                              : colorScheme.outlineVariant,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  if (game.isExpansion)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Chip(
                        label: const Text('EXP',
                            style: TextStyle(fontSize: 9, color: Colors.white)),
                        backgroundColor: Colors.deepPurple.shade400,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPlaceholder extends StatelessWidget {
  final String name;
  const _GridPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
