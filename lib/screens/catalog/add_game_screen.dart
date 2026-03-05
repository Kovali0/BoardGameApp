import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../models/board_game.dart';
import '../../services/bgg_service.dart';

class AddGameScreen extends StatefulWidget {
  final BoardGame? game;
  const AddGameScreen({super.key, this.game});

  @override
  State<AddGameScreen> createState() => _AddGameScreenState();
}

class _AddGameScreenState extends State<AddGameScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _hintsController;
  late int _minPlayers;
  late int _maxPlayers;

  final _bgg = BggService();
  final _searchController = TextEditingController();
  List<BggSearchResult> _searchResults = [];
  bool _searching = false;
  bool _showResults = false;
  Timer? _debounce;

  bool get _isEditing => widget.game != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.game?.name ?? '');
    _descController =
        TextEditingController(text: widget.game?.description ?? '');
    _hintsController =
        TextEditingController(text: widget.game?.setupHints ?? '');
    _minPlayers = widget.game?.minPlayers ?? 2;
    _maxPlayers = widget.game?.maxPlayers ?? 4;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _hintsController.dispose();
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
            _showResults = true;
          });
        }
      } catch (e, st) {
        debugPrint('[BGG] searchGames error: $e\n$st');
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  Future<void> _selectGame(BggSearchResult result) async {
    setState(() {
      _showResults = false;
      _searchController.clear();
    });

    try {
      if (!mounted) return;
      setState(() {
        _nameController.text = result.name;
        if (result.minPlayers != null) {
          _minPlayers = result.minPlayers!.clamp(1, 20);
        }
        if (result.maxPlayers != null) {
          _maxPlayers = result.maxPlayers!.clamp(_minPlayers, 20);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Filled from Wikidata: ${result.name}'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not fill game details')),
        );
      }
    } finally {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<GameProvider>();
    final desc = _descController.text.trim();
    final hints = _hintsController.text.trim();

    if (_isEditing) {
      await provider.updateGame(widget.game!.copyWith(
        name: _nameController.text.trim(),
        description: desc.isEmpty ? null : desc,
        minPlayers: _minPlayers,
        maxPlayers: _maxPlayers,
        setupHints: hints.isEmpty ? null : hints,
      ));
    } else {
      await provider.addGame(
        name: _nameController.text.trim(),
        description: desc.isEmpty ? null : desc,
        minPlayers: _minPlayers,
        maxPlayers: _maxPlayers,
        setupHints: hints.isEmpty ? null : hints,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showResults = false),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Game' : 'Add Game'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!_isEditing) ...[
                _BggSearchBar(
                  controller: _searchController,
                  searching: _searching,
                  onChanged: _onSearchChanged,
                  onClear: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                      _showResults = false;
                      _searching = false;
                    });
                  },
                ),
                if (_showResults && _searchResults.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _SearchResultsList(
                    results: _searchResults,
                    onSelect: _selectGame,
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
              ],
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Game Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.casino),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _PlayerCountField(
                      label: 'Min Players',
                      value: _minPlayers,
                      onChanged: (v) => setState(() => _minPlayers = v),
                      min: 1,
                      max: _maxPlayers,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _PlayerCountField(
                      label: 'Max Players',
                      value: _maxPlayers,
                      onChanged: (v) => setState(() => _maxPlayers = v),
                      min: _minPlayers,
                      max: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hintsController,
                decoration: const InputDecoration(
                  labelText: 'Setup Hints',
                  hintText: 'e.g. 1. Place board in center\n2. Deal 5 cards each...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lightbulb_outline),
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(_isEditing ? 'Save Changes' : 'Add Game'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BggSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool searching;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _BggSearchBar({
    required this.controller,
    required this.searching,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.search, size: 18),
            const SizedBox(width: 6),
            Text(
              'Search game database',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Type to search BGG database...',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.travel_explore),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: onClear,
                  )
                : searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
          ),
        ),
      ],
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  final List<BggSearchResult> results;
  final ValueChanged<BggSearchResult> onSelect;

  const _SearchResultsList({required this.results, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            '${results.length} result${results.length == 1 ? '' : 's'} found',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
        ...results.map((r) => _SearchResultCard(result: r, onTap: () => onSelect(r))),
      ],
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final BggSearchResult result;
  final VoidCallback onTap;

  const _SearchResultCard({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPlayers = result.minPlayers != null || result.maxPlayers != null;
    final playersLabel = _buildPlayersLabel();

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.casino_outlined,
                  size: 20,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (result.year != null || hasPlayers)
                      const SizedBox(height: 4),
                    if (result.year != null || hasPlayers)
                      Row(
                        children: [
                          if (result.year != null) ...[
                            _InfoChip(
                              icon: Icons.calendar_today,
                              label: '${result.year}',
                            ),
                          ],
                          if (hasPlayers && result.year != null)
                            const SizedBox(width: 6),
                          if (hasPlayers)
                            _InfoChip(
                              icon: Icons.people_outline,
                              label: playersLabel,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildPlayersLabel() {
    final min = result.minPlayers;
    final max = result.maxPlayers;
    if (min != null && max != null) {
      return min == max ? '$min' : '$min–$max';
    }
    if (min != null) return '$min+';
    if (max != null) return '≤$max';
    return '';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerCountField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  const _PlayerCountField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Expanded(
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }
}
