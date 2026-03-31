import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/wishlist_item.dart';
import '../db/database_helper.dart';
import 'game_provider.dart';

class WishlistProvider with ChangeNotifier {
  final _db = DatabaseHelper();
  final _uuid = const Uuid();
  List<WishlistItem> _items = [];

  List<WishlistItem> get items => List.unmodifiable(_items);

  Future<void> loadItems() async {
    _items = await _db.getWishlistItems();
    notifyListeners();
  }

  Future<void> addItem({
    required String name,
    String? note,
    required int priority,
    String? imageUrl,
    String? thumbnailUrl,
    double? bggRating,
    double? complexity,
    int? minPlayers,
    int? maxPlayers,
    double? price,
  }) async {
    final item = WishlistItem(
      id: _uuid.v4(),
      name: name,
      note: note,
      priority: priority,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      bggRating: bggRating,
      complexity: complexity,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      price: price,
      addedAt: DateTime.now(),
    );
    await _db.insertWishlistItem(item);
    _items.add(item);
    _items.sort((a, b) {
      final pc = b.priority.compareTo(a.priority);
      return pc != 0 ? pc : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    notifyListeners();
  }

  Future<void> updateItem(WishlistItem updated) async {
    await _db.updateWishlistItem(updated);
    final idx = _items.indexWhere((i) => i.id == updated.id);
    if (idx != -1) {
      _items[idx] = updated;
      _items.sort((a, b) {
        final pc = b.priority.compareTo(a.priority);
        return pc != 0 ? pc : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      notifyListeners();
    }
  }

  Future<void> deleteItem(String id) async {
    await _db.deleteWishlistItem(id);
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  /// Moves a wishlist item into the game collection and removes it from wishlist.
  Future<void> moveToCollection(String id, GameProvider gameProvider) async {
    final item = _items.firstWhere((i) => i.id == id);
    await gameProvider.addGame(
      name: item.name,
      description: null,
      minPlayers: item.minPlayers ?? 1,
      maxPlayers: item.maxPlayers ?? 8,
      imageUrl: item.imageUrl,
      thumbnailUrl: item.thumbnailUrl,
      bggRating: item.bggRating,
      complexity: item.complexity,
    );
    await deleteItem(id);
  }

  // ── Import ──────────────────────────────────────────────────────────────────

  /// Imports wishlist items from JSON. Uses 'id' for duplicate detection.
  Future<({int added, int skipped})> importWishlistFromJson(
      List<Map<String, dynamic>> maps) async {
    final existingIds = _items.map((i) => i.id).toSet();
    int added = 0, skipped = 0;
    for (final map in maps) {
      final id = map['id'] as String?;
      if (id == null || existingIds.contains(id)) {
        skipped++;
        continue;
      }
      try {
        final item = WishlistItem.fromMap(map);
        await _db.insertWishlistItem(item);
        _items.add(item);
        existingIds.add(id);
        added++;
      } catch (_) {
        skipped++;
      }
    }
    if (added > 0) {
      _items.sort((a, b) {
        final pc = b.priority.compareTo(a.priority);
        return pc != 0 ? pc : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      notifyListeners();
    }
    return (added: added, skipped: skipped);
  }

  /// Imports wishlist items from CSV. Deduplicates by lowercase name.
  Future<({int added, int skipped})> importWishlistFromCsv(
      List<Map<String, dynamic>> maps) async {
    final existingNames = _items.map((i) => i.name.toLowerCase()).toSet();
    int added = 0, skipped = 0;
    for (final map in maps) {
      final name = (map['name'] as String? ?? '').trim();
      if (name.isEmpty || existingNames.contains(name.toLowerCase())) {
        skipped++;
        continue;
      }
      try {
        final addedAt =
            DateTime.tryParse(map['added_at'] as String? ?? '') ??
                DateTime.now();
        final item = WishlistItem(
          id: _uuid.v4(),
          name: name,
          note: map['note'] as String?,
          priority: map['priority'] as int? ?? 2,
          bggRating: map['bgg_rating'] as double?,
          complexity: map['complexity'] as double?,
          minPlayers: map['min_players'] as int?,
          maxPlayers: map['max_players'] as int?,
          price: map['price'] as double?,
          addedAt: addedAt,
        );
        await _db.insertWishlistItem(item);
        _items.add(item);
        existingNames.add(name.toLowerCase());
        added++;
      } catch (_) {
        skipped++;
      }
    }
    if (added > 0) {
      _items.sort((a, b) {
        final pc = b.priority.compareTo(a.priority);
        return pc != 0 ? pc : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      notifyListeners();
    }
    return (added: added, skipped: skipped);
  }
}
