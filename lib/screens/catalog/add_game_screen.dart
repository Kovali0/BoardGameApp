import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../models/board_game.dart';

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
    super.dispose();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Game' : 'Add Game'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                hintText:
                    'e.g. 1. Place board in center\n2. Deal 5 cards each...',
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
