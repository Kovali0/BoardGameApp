import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/wishlist_item.dart';
import '../../providers/language_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../services/bgg_service.dart';

class AddWishlistItemScreen extends StatefulWidget {
  final WishlistItem? item; // null = add, non-null = edit
  const AddWishlistItemScreen({super.key, this.item});

  @override
  State<AddWishlistItemScreen> createState() => _AddWishlistItemScreenState();
}

class _AddWishlistItemScreenState extends State<AddWishlistItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _noteController;
  late int _priority;

  // BGG search
  final _bgg = BggService();
  final _searchController = TextEditingController();
  List<BggSearchResult> _searchResults = [];
  bool _searching = false;
  bool _showResults = false;
  Timer? _debounce;

  late final TextEditingController _priceController;

  // BGG-filled metadata
  String? _imageUrl;
  String? _thumbnailUrl;
  double? _bggRating;
  double? _complexity;
  int? _minPlayers;
  int? _maxPlayers;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _nameController = TextEditingController(text: i?.name ?? '');
    _noteController = TextEditingController(text: i?.note ?? '');
    _priceController = TextEditingController(
        text: i?.price != null ? i!.price!.toStringAsFixed(2) : '');
    _priority = i?.priority ?? 2;
    _imageUrl = i?.imageUrl;
    _thumbnailUrl = i?.thumbnailUrl;
    _bggRating = i?.bggRating;
    _complexity = i?.complexity;
    _minPlayers = i?.minPlayers;
    _maxPlayers = i?.maxPlayers;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _priceController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _searchResults = [];
        _showResults = false;
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final results = await _bgg.searchGames(value.trim());
        if (mounted) {
          setState(() {
            _searchResults = results;
            _searching = false;
            _showResults = results.isNotEmpty;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  void _selectGame(BggSearchResult result) {
    final s = context.read<LanguageProvider>().strings;
    setState(() {
      _nameController.text = result.name;
      _imageUrl = result.imageUrl;
      _thumbnailUrl = result.thumbnailUrl;
      _bggRating = result.bggRating;
      _complexity = result.complexity;
      _minPlayers = result.minPlayers;
      _maxPlayers = result.maxPlayers;
      _showResults = false;
      _searchController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(s.wishlistBggFilled),
      backgroundColor: Colors.green.shade700,
      duration: const Duration(seconds: 2),
    ));
  }

  double? get _parsedPrice {
    final text = _priceController.text.trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  Future<void> _searchOnline() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final suffix = context.read<LanguageProvider>().strings.wishlistSearchSuffix;
    final encoded = Uri.encodeComponent('$name $suffix');
    final engine = context.read<SettingsProvider>().priceSearch;
    final uri = switch (engine) {
      AppPriceSearch.google => Uri.parse('https://www.google.com/search?q=$encoded&tbm=shop'),
      AppPriceSearch.amazon => Uri.parse('https://www.amazon.com/s?k=$encoded'),
      AppPriceSearch.ceneo  => Uri.parse('https://www.ceneo.pl/;szukaj-$encoded'),
    };
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<WishlistProvider>();
    final name = _nameController.text.trim();
    final note = _noteController.text.trim();
    final price = _parsedPrice;

    if (_isEditing) {
      await provider.updateItem(widget.item!.copyWith(
        name: name,
        note: note.isEmpty ? null : note,
        priority: _priority,
        imageUrl: _imageUrl,
        thumbnailUrl: _thumbnailUrl,
        bggRating: _bggRating,
        complexity: _complexity,
        minPlayers: _minPlayers,
        maxPlayers: _maxPlayers,
        price: price,
      ));
    } else {
      await provider.addItem(
        name: name,
        note: note.isEmpty ? null : note,
        priority: _priority,
        imageUrl: _imageUrl,
        thumbnailUrl: _thumbnailUrl,
        bggRating: _bggRating,
        complexity: _complexity,
        minPlayers: _minPlayers,
        maxPlayers: _maxPlayers,
        price: price,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final currencyCode = context.watch<SettingsProvider>().currencyCode;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? s.wishlistEditTitle : s.wishlistAddTitle),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // BGG search
            Text(s.addGameBggSearchTitle,
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: s.addGameBggSearchHint,
                border: const OutlineInputBorder(),
                prefixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)))
                    : const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                            _showResults = false;
                          });
                        },
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
            if (_showResults) ...[
              const SizedBox(height: 4),
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: _searchResults
                      .take(6)
                      .map((r) => ListTile(
                            dense: true,
                            leading: r.thumbnailUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(r.thumbnailUrl!,
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.casino_outlined)))
                                : const Icon(Icons.casino_outlined),
                            title: Text(r.name,
                                style: const TextStyle(fontSize: 14)),
                            subtitle: r.minPlayers != null
                                ? Text(
                                    '${r.minPlayers}–${r.maxPlayers} players',
                                    style: const TextStyle(fontSize: 12))
                                : null,
                            onTap: () => _selectGame(r),
                          ))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Image preview
            if (_thumbnailUrl != null || _imageUrl != null) ...[
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _thumbnailUrl ?? _imageUrl!,
                    height: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: s.wishlistNameLabel,
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? s.wishlistNameLabel : null,
            ),
            const SizedBox(height: 16),

            // Priority
            Text(s.wishlistPriority,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: [
                ButtonSegment(
                  value: 1,
                  label: Text(s.wishlistPriorityLow),
                  icon: const Icon(Icons.arrow_downward, size: 16),
                ),
                ButtonSegment(
                  value: 2,
                  label: Text(s.wishlistPriorityMedium),
                  icon: const Icon(Icons.remove, size: 16),
                ),
                ButtonSegment(
                  value: 3,
                  label: Text(s.wishlistPriorityHigh),
                  icon: const Icon(Icons.arrow_upward, size: 16),
                ),
              ],
              selected: {_priority},
              onSelectionChanged: (v) => setState(() => _priority = v.first),
            ),
            const SizedBox(height: 16),

            // Note
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: s.wishlistNoteLabel,
                hintText: s.wishlistNoteHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: s.wishlistPriceLabel,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.sell_outlined),
                      suffixText: currencyCode,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final parsed = double.tryParse(v.trim().replaceAll(',', '.'));
                      if (parsed == null || parsed < 0) return '?';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: OutlinedButton.icon(
                    onPressed: _searchOnline,
                    icon: const Icon(Icons.open_in_browser, size: 18),
                    label: Text(s.wishlistSearchOnline),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),

            // BGG info summary if filled
            if (_bggRating != null || _minPlayers != null) ...[
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      if (_minPlayers != null)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.group, size: 16),
                          const SizedBox(width: 4),
                          Text('$_minPlayers–$_maxPlayers'),
                        ]),
                      if (_bggRating != null)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.star_outline,
                              size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(_bggRating!.toStringAsFixed(1)),
                        ]),
                      if (_complexity != null)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.psychology_outlined, size: 16),
                          const SizedBox(width: 4),
                          Text(_complexity!.toStringAsFixed(1)),
                        ]),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              style:
                  FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: Text(s.wishlistSave),
            ),
          ],
        ),
      ),
    );
  }
}
