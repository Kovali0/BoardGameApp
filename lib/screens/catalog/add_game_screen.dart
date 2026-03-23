import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/language_provider.dart';
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

  late final TextEditingController _minPlaytimeController;
  late final TextEditingController _maxPlaytimeController;
  late final TextEditingController _bggRatingController;
  late final TextEditingController _complexityController;
  late final TextEditingController _myRatingController;
  late final TextEditingController _myWeightController;

  final _bgg = BggService();
  final _searchController = TextEditingController();
  List<BggSearchResult> _searchResults = [];
  bool _searching = false;
  bool _showResults = false;
  bool _searchedWithNoResults = false;
  Timer? _debounce;
  String? _imageUrl;
  String? _thumbnailUrl;

  String? _bggId;
  bool _isExpansion = false;
  List<String> _categories = [];
  List<String> _mechanics = [];
  int? _yearPublished;
  int? _minAge;

  bool get _isEditing => widget.game != null;

  @override
  void initState() {
    super.initState();
    final g = widget.game;
    _nameController = TextEditingController(text: g?.name ?? '');
    _descController = TextEditingController(text: g?.description ?? '');
    _hintsController = TextEditingController(text: g?.setupHints ?? '');
    _minPlayers = g?.minPlayers ?? 2;
    _maxPlayers = g?.maxPlayers ?? 4;
    _minPlaytimeController =
        TextEditingController(text: g?.minPlaytime?.toString() ?? '');
    _maxPlaytimeController =
        TextEditingController(text: g?.maxPlaytime?.toString() ?? '');
    _bggRatingController =
        TextEditingController(text: g?.bggRating?.toStringAsFixed(1) ?? '');
    _complexityController =
        TextEditingController(text: g?.complexity?.toStringAsFixed(1) ?? '');
    _myRatingController =
        TextEditingController(text: g?.myRating?.toStringAsFixed(1) ?? '');
    _myWeightController =
        TextEditingController(text: g?.myWeight?.toStringAsFixed(1) ?? '');
    _imageUrl = g?.imageUrl;
    _thumbnailUrl = g?.thumbnailUrl;
    _bggId = g?.bggId;
    _isExpansion = g?.isExpansion ?? false;
    _categories = g?.categories ?? [];
    _mechanics = g?.mechanics ?? [];
    _yearPublished = g?.yearPublished;
    _minAge = g?.minAge;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _hintsController.dispose();
    _searchController.dispose();
    _minPlaytimeController.dispose();
    _maxPlaytimeController.dispose();
    _bggRatingController.dispose();
    _complexityController.dispose();
    _myRatingController.dispose();
    _myWeightController.dispose();
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
        _searchedWithNoResults = false;
      });
      return;
    }
    setState(() {
      _searching = true;
      _searchedWithNoResults = false;
    });
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final results = await _bgg.searchGames(value.trim());
        if (mounted) {
          setState(() {
            _searchResults = results;
            _searching = false;
            _showResults = results.isNotEmpty;
            _searchedWithNoResults = results.isEmpty;
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
      _searchedWithNoResults = false;
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
        _imageUrl = result.imageUrl;
        _thumbnailUrl = result.thumbnailUrl;
        _bggId = result.id;
        _isExpansion = result.isExpansion;
        _minPlaytimeController.text =
            result.minPlaytime?.toString() ?? '';
        _maxPlaytimeController.text =
            result.maxPlaytime?.toString() ?? '';
        _bggRatingController.text =
            result.bggRating?.toStringAsFixed(1) ?? '';
        _complexityController.text =
            result.complexity?.toStringAsFixed(1) ?? '';
        _categories = result.categories;
        _mechanics = result.mechanics;
        _yearPublished = result.year;
        _minAge = result.minAge;
      });
      final s = context.read<LanguageProvider>().strings;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.addGameBggFilled(result.name)),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (mounted) {
        final s = context.read<LanguageProvider>().strings;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.addGameBggError)),
        );
      }
    } finally {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<GameProvider>();
    final desc = _descController.text.trim();
    final hints = _hintsController.text.trim();
    final minPlaytime = int.tryParse(_minPlaytimeController.text.trim());
    final maxPlaytime = int.tryParse(_maxPlaytimeController.text.trim());
    final bggRating = double.tryParse(_bggRatingController.text.trim());
    final complexity = double.tryParse(_complexityController.text.trim());
    final myRating = double.tryParse(_myRatingController.text.trim());
    final myWeight = double.tryParse(_myWeightController.text.trim());

    if (_isEditing) {
      await provider.updateGame(widget.game!.copyWith(
        name: _nameController.text.trim(),
        description: desc.isEmpty ? null : desc,
        minPlayers: _minPlayers,
        maxPlayers: _maxPlayers,
        setupHints: hints.isEmpty ? null : hints,
        imageUrl: _imageUrl,
        thumbnailUrl: _thumbnailUrl,
        minPlaytime: minPlaytime,
        maxPlaytime: maxPlaytime,
        bggRating: bggRating,
        complexity: complexity,
        myRating: myRating,
        myWeight: myWeight,
        bggId: _bggId,
        isExpansion: _isExpansion,
        categories: _categories,
        mechanics: _mechanics,
      ));
    } else {
      await provider.addGame(
        name: _nameController.text.trim(),
        description: desc.isEmpty ? null : desc,
        minPlayers: _minPlayers,
        maxPlayers: _maxPlayers,
        setupHints: hints.isEmpty ? null : hints,
        imageUrl: _imageUrl,
        thumbnailUrl: _thumbnailUrl,
        minPlaytime: minPlaytime,
        maxPlaytime: maxPlaytime,
        bggRating: bggRating,
        complexity: complexity,
        myRating: myRating,
        myWeight: myWeight,
        bggId: _bggId,
        isExpansion: _isExpansion,
        categories: _categories,
        mechanics: _mechanics,
        yearPublished: _yearPublished,
        minAge: _minAge,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    return Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? s.editGameTitle : s.addGameTitle),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
            children: [
              if (!_isEditing) ...[
                _BggSearchBar(
                  controller: _searchController,
                  searching: _searching,
                  onChanged: _onSearchChanged,
                  onDismiss: () => setState(() => _showResults = false),
                  onClear: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                      _showResults = false;
                      _searching = false;
                      _searchedWithNoResults = false;
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
                if (_searchedWithNoResults) ...[
                  const SizedBox(height: 8),
                  _NotFoundBanner(),
                ],
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
              ],
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: s.addGameNameLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.casino),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: s.addGameDescriptionLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _PlayerCountField(
                      label: s.addGameMinPlayersLabel,
                      value: _minPlayers,
                      onChanged: (v) => setState(() => _minPlayers = v),
                      min: 1,
                      max: _maxPlayers,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _PlayerCountField(
                      label: s.addGameMaxPlayersLabel,
                      value: _maxPlayers,
                      onChanged: (v) => setState(() => _maxPlayers = v),
                      min: _minPlayers,
                      max: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minPlaytimeController,
                      decoration: InputDecoration(
                        labelText: s.addGameMinPlaytimeLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.timer_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 1) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxPlaytimeController,
                      decoration: InputDecoration(
                        labelText: s.addGameMaxPlaytimeLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.timer_outlined),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 1) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('BGG', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.outline)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bggRatingController,
                      decoration: InputDecoration(
                        labelText: s.addGameBggRatingLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.star_outline),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(v.trim());
                        if (n == null || n < 1 || n > 10) return '1–10';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _complexityController,
                      decoration: InputDecoration(
                        labelText: s.addGameBggWeightLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.psychology_outlined),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(v.trim());
                        if (n == null || n < 1 || n > 5) return '1–5';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(s.addGameMyNotesSection, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _myRatingController,
                      decoration: InputDecoration(
                        labelText: s.addGameMyRatingLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.star),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(v.trim());
                        if (n == null || n < 1 || n > 10) return '1–10';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _myWeightController,
                      decoration: InputDecoration(
                        labelText: s.addGameMyWeightLabel,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.psychology),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(v.trim());
                        if (n == null || n < 1 || n > 5) return '1–5';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hintsController,
                decoration: InputDecoration(
                  labelText: s.addGameSetupHintsLabel,
                  hintText: s.addGameSetupHintsHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lightbulb_outline),
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: Text(_isEditing ? s.saveChangesButton : s.addGameButton),
              ),
            ],
          ),
        ),
    );
  }
}

class _BggSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final bool searching;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onDismiss;

  const _BggSearchBar({
    required this.controller,
    required this.searching,
    required this.onChanged,
    required this.onClear,
    required this.onDismiss,
  });

  @override
  State<_BggSearchBar> createState() => _BggSearchBarState();
}

class _BggSearchBarState extends State<_BggSearchBar> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.search, size: 18),
            const SizedBox(width: 6),
            Text(
              s.addGameBggSearchTitle,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: s.addGameBggSearchHint,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.travel_explore),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: widget.onClear,
                  )
                : widget.searching
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
                backgroundColor: result.isExpansion
                    ? theme.colorScheme.secondaryContainer
                    : theme.colorScheme.primaryContainer,
                child: Icon(
                  result.isExpansion ? Icons.extension_outlined : Icons.casino_outlined,
                  size: 20,
                  color: result.isExpansion
                      ? theme.colorScheme.onSecondaryContainer
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            result.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (result.isExpansion) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('EXP',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSecondaryContainer)),
                          ),
                        ],
                      ],
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

class _NotFoundBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = context.watch<LanguageProvider>().strings;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.search_off, size: 18, color: theme.colorScheme.outline),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              s.addGameBggNotFound,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
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
