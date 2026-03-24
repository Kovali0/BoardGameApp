import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_session.dart';
import '../../providers/game_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/session_provider.dart';
import 'tabs/global_stats_tab.dart';
import 'tabs/games_stats_tab.dart';
import 'tabs/players_stats_tab.dart';

// ─── Filter helpers ────────────────────────────────────────────────────────────

List<int> _years(List<GameSession> s) =>
    s.map((x) => x.startTime.year).toSet().toList()..sort((a, b) => b.compareTo(a));

List<int> _months(List<GameSession> s, int year) =>
    s.where((x) => x.startTime.year == year)
     .map((x) => x.startTime.month).toSet().toList()
     ..sort((a, b) => b.compareTo(a));

List<GameSession> _applyFilter(List<GameSession> all, int? year, int? month) {
  if (year == null) return all;
  final byYear = all.where((s) => s.startTime.year == year);
  if (month == null) return byYear.toList();
  return byYear.where((s) => s.startTime.month == month).toList();
}

const _kMonths = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

// ─── Screen ───────────────────────────────────────────────────────────────────

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int? _selectedYear;
  int? _selectedMonth;

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

  void _showFilterSheet(BuildContext context, List<GameSession> allSessions) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _FilterSheet(
        allSessions: allSessions,
        initialYear: _selectedYear,
        initialMonth: _selectedMonth,
        onApply: (year, month) => setState(() {
          _selectedYear = year;
          _selectedMonth = month;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final sessions = context.watch<SessionProvider>().sessions;
    final allGames = context.watch<GameProvider>().games;
    final filteredSessions = _applyFilter(sessions, _selectedYear, _selectedMonth);
    final filterActive = _selectedYear != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.statsTitle),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterSheet(context, sessions),
              ),
              if (filterActive)
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
            Tab(text: s.statsGlobal),
            Tab(text: s.statsGamesTab),
            Tab(text: s.statsPlayersTab),
          ],
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
                      const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        s.statsNoSessions,
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.statsPlayGames,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : GlobalStatsTab(sessions: filteredSessions, allGames: allGames),
          GamesStatsTab(sessions: filteredSessions, allGames: allGames),
          PlayersStatsTab(sessions: filteredSessions),
        ],
      ),
    );
  }
}

// ─── Filter sheet ─────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final List<GameSession> allSessions;
  final int? initialYear;
  final int? initialMonth;
  final void Function(int? year, int? month) onApply;

  const _FilterSheet({
    required this.allSessions,
    required this.initialYear,
    required this.initialMonth,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  int? _year;
  int? _month;

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
    _month = widget.initialMonth;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final years = _years(widget.allSessions);
    final months = _year == null ? <int>[] : _months(widget.allSessions, _year!);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.statsFilterTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(s.filterYear, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilterChip(
                label: Text(s.filterAll),
                selected: _year == null,
                onSelected: (_) => setState(() { _year = null; _month = null; }),
              ),
              for (final y in years)
                FilterChip(
                  label: Text('$y'),
                  selected: _year == y,
                  onSelected: (_) => setState(() { _year = y; _month = null; }),
                ),
            ],
          ),
          if (_year != null) ...[
            const SizedBox(height: 12),
            Text(s.filterMonth, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilterChip(
                  label: Text(s.filterAll),
                  selected: _month == null,
                  onSelected: (_) => setState(() => _month = null),
                ),
                for (final m in months)
                  FilterChip(
                    label: Text(_kMonths[m]),
                    selected: _month == m,
                    onSelected: (_) => setState(() => _month = m),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onApply(_year, _month);
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
