import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/wishlist_item.dart';
import '../../providers/language_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/game_provider.dart';
import 'add_wishlist_item_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final provider = context.watch<WishlistProvider>();
    final items = provider.items;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.wishlistTitle),
        centerTitle: true,
      ),
      body: items.isEmpty
          ? Center(
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
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              itemBuilder: (context, index) =>
                  WishlistCard(item: items[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AddWishlistItemScreen()),
        ),
        icon: const Icon(Icons.add),
        label: Text(s.wishlistAddItem),
      ),
    );
  }
}

// ─── Wishlist card ────────────────────────────────────────────────────────────

class WishlistCard extends StatelessWidget {
  final WishlistItem item;
  const WishlistCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final currencyCode = context.watch<SettingsProvider>().currencyCode;
    final imageUrl = item.thumbnailUrl ?? item.imageUrl;

    // Build subtitle: priority • optional info
    final priorityLabel = switch (item.priority) {
      3 => s.wishlistPriorityHigh,
      2 => s.wishlistPriorityMedium,
      _ => s.wishlistPriorityLow,
    };

    final subtitleParts = <String>[priorityLabel];
    if (item.minPlayers != null) subtitleParts.add('${item.minPlayers}–${item.maxPlayers} players');
    if (item.bggRating != null) subtitleParts.add('BGG ${item.bggRating!.toStringAsFixed(1)}');
    if (item.price != null) subtitleParts.add('${item.price!.toStringAsFixed(2)} $currencyCode');

    final subtitleLine = subtitleParts.join('  ·  ');
    final subtitleText = (item.note != null && item.note!.isNotEmpty)
        ? '$subtitleLine\n${item.note!}'
        : subtitleLine;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: imageUrl == null
              ? Text(item.name[0].toUpperCase(),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer))
              : null,
        ),
        title: Text(item.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitleText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _confirmMove(context, s),
              child: Icon(Icons.library_add_outlined,
                  color: Theme.of(context).colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddWishlistItemScreen(item: item)),
        ),
        onLongPress: () => _confirmDelete(context, s),
      ),
    );
  }

  void _confirmMove(BuildContext context, dynamic s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.wishlistMoveConfirmTitle),
        content: Text(s.wishlistMoveConfirmContent(item.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context
                  .read<WishlistProvider>()
                  .moveToCollection(item.id, context.read<GameProvider>());
            },
            child: Text(s.wishlistMoveToCollection),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, dynamic s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.wishlistDeleteTitle),
        content: Text(s.wishlistDeleteContent(item.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<WishlistProvider>().deleteItem(item.id);
            },
            child: Text(s.delete),
          ),
        ],
      ),
    );
  }
}

// ─── Wishlist grid card ───────────────────────────────────────────────────────

class WishlistGridCard extends StatelessWidget {
  final WishlistItem item;
  const WishlistGridCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.thumbnailUrl ?? item.imageUrl;
    final currencyCode = context.watch<SettingsProvider>().currencyCode;
    final priorityColor = switch (item.priority) {
      3 => Colors.red.shade400,
      2 => Colors.orange.shade400,
      _ => Colors.grey.shade400,
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AddWishlistItemScreen(item: item)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl != null
                      ? Image.network(imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _WishlistGridPlaceholder(name: item.name))
                      : _WishlistGridPlaceholder(name: item.name),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: priorityColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.8),
                            width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.price != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${item.price!.toStringAsFixed(2)} $currencyCode',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistGridPlaceholder extends StatelessWidget {
  final String name;
  const _WishlistGridPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
