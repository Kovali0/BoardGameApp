import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_session.dart';
import '../../providers/game_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_provider.dart';
import 'tabs/global_stats_tab.dart';
import 'tabs/games_stats_tab.dart';
import 'tabs/players_stats_tab.dart';

// ─── Date range preset ────────────────────────────────────────────────────────

enum _DatePreset { allTime, last30, last3m, last6m, thisYear, custom }

({DateTime? from, DateTime? to}) _presetDates(_DatePreset preset) {
  final now = DateTime.now();
  return switch (preset) {
    _DatePreset.allTime => (from: null, to: null),
    _DatePreset.last30 =>
      (from: DateTime(now.year, now.month, now.day - 30), to: null),
    _DatePreset.last3m =>
      (from: DateTime(now.year, now.month - 3, now.day), to: null),
    _DatePreset.last6m =>
      (from: DateTime(now.year, now.month - 6, now.day), to: null),
    _DatePreset.thisYear => (from: DateTime(now.year, 1, 1), to: null),
    _DatePreset.custom => (from: null, to: null),
  };
}

// ─── Filter helper ────────────────────────────────────────────────────────────

List<GameSession> _applyFilter(
    List<GameSession> all, DateTime? from, DateTime? to) {
  var list = all;
  if (from != null) {
    list = list.where((s) => !s.startTime.isBefore(from)).toList();
  }
  if (to != null) {
    final toEnd = DateTime(to.year, to.month, to.day, 23, 59, 59);
    list = list.where((s) => !s.startTime.isAfter(toEnd)).toList();
  }
  return list;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  _DatePreset _preset = _DatePreset.allTime;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _filterActive => _preset != _DatePreset.allTime;

  String _activeLabel(dynamic s) {
    final settings = context.read<SettingsProvider>();
    return switch (_preset) {
      _DatePreset.allTime => '',
      _DatePreset.last30 => s.statsPresetLast30,
      _DatePreset.last3m => s.statsPresetLast3m,
      _DatePreset.last6m => s.statsPresetLast6m,
      _DatePreset.thisYear => s.statsPresetThisYear,
      _DatePreset.custom => [
          if (_fromDate != null) settings.formatDate(_fromDate!),
          if (_toDate != null) settings.formatDate(_toDate!),
        ].join(' – '),
    };
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FilterSheet(
        initialPreset: _preset,
        initialFrom: _fromDate,
        initialTo: _toDate,
        onApply: (preset, from, to) => setState(() {
          _preset = preset;
          _fromDate = from;
          _toDate = to;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final sessions = context.watch<SessionProvider>().sessions;
    final allGames = context.watch<GameProvider>().games;

    final dates = _preset == _DatePreset.custom
        ? (from: _fromDate, to: _toDate)
        : _presetDates(_preset);
    final filteredSessions =
        _applyFilter(sessions, dates.from, dates.to);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.statsTitle),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterSheet(context),
              ),
              if (_filterActive)
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
        bottom: PreferredSize(
          preferredSize:
              Size.fromHeight(_filterActive ? 96 : 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: s.statsGlobal),
                  Tab(text: s.statsGamesTab),
                  Tab(text: s.statsPlayersTab),
                ],
              ),
              if (_filterActive)
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 8),
                  child: InputChip(
                    avatar: const Icon(Icons.date_range, size: 16),
                    label: Text(
                      _activeLabel(s),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onDeleted: () => setState(() {
                      _preset = _DatePreset.allTime;
                      _fromDate = null;
                      _toDate = null;
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          filteredSessions.isEmpty && allGames.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bar_chart,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(s.statsNoSessions,
                          style: const TextStyle(
                              fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(s.statsPlayGames,
                          style:
                              const TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : GlobalStatsTab(
                  sessions: filteredSessions, allGames: allGames),
          GamesStatsTab(
              sessions: filteredSessions, allGames: allGames),
          PlayersStatsTab(sessions: filteredSessions),
        ],
      ),
    );
  }
}

// ─── Filter sheet ─────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final _DatePreset initialPreset;
  final DateTime? initialFrom;
  final DateTime? initialTo;
  final void Function(_DatePreset preset, DateTime? from, DateTime? to) onApply;

  const _FilterSheet({
    required this.initialPreset,
    required this.initialFrom,
    required this.initialTo,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late _DatePreset _preset;
  DateTime? _from;
  DateTime? _to;

  @override
  void initState() {
    super.initState();
    _preset = widget.initialPreset;
    _from = widget.initialFrom;
    _to = widget.initialTo;
  }

  void _selectPreset(_DatePreset p) {
    setState(() {
      _preset = p;
      if (p != _DatePreset.custom) {
        _from = null;
        _to = null;
      }
    });
  }

  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final initial = isFrom
        ? (_from ?? now.subtract(const Duration(days: 90)))
        : (_to ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
      _preset = _DatePreset.custom;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    final presets = [
      (_DatePreset.allTime, s.statsPresetAllTime),
      (_DatePreset.last30, s.statsPresetLast30),
      (_DatePreset.last3m, s.statsPresetLast3m),
      (_DatePreset.last6m, s.statsPresetLast6m),
      (_DatePreset.thisYear, s.statsPresetThisYear),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 20, 16,
          16 +
              MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.statsFilterTitle,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // ── Preset chips ──
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final (p, label) in presets)
                FilterChip(
                  label: Text(label),
                  selected: _preset == p,
                  onSelected: (_) => _selectPreset(p),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Custom date pickers ──
          Text(s.statsPresetCustom,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DatePickerField(
                  label: s.statsFilterFrom,
                  date: _from,
                  onTap: () => _pickDate(true),
                  isSelected: _preset == _DatePreset.custom && _from != null,
                  settings: settings,
                  theme: theme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DatePickerField(
                  label: s.statsFilterTo,
                  date: _to,
                  onTap: () => _pickDate(false),
                  isSelected: _preset == _DatePreset.custom && _to != null,
                  settings: settings,
                  theme: theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final from = _preset == _DatePreset.custom
                    ? _from
                    : _presetDates(_preset).from;
                final to = _preset == _DatePreset.custom
                    ? _to
                    : _presetDates(_preset).to;
                widget.onApply(_preset, from, to);
                Navigator.pop(context);
              },
              child: Text(s.apply),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool isSelected;
  final SettingsProvider settings;
  final ThemeData theme;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onTap,
    required this.isSelected,
    required this.settings,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 16,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null ? settings.formatDate(date!) : label,
                style: TextStyle(
                  fontSize: 13,
                  color: date != null
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
