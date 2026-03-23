import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/game_provider.dart';
import '../../models/game_session.dart';
import 'session_detail_screen.dart';
import '../session/new_session_screen.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum _HistorySortOrder { newest, oldest, byGame }

// ─── Filter helpers ────────────────────────────────────────────────────────────

List<int> _years(List<GameSession> s) =>
    s.map((x) => x.startTime.year).toSet().toList()..sort((a, b) => b.compareTo(a));

List<int> _months(List<GameSession> s, int year) =>
    s.where((x) => x.startTime.year == year)
     .map((x) => x.startTime.month).toSet().toList()
     ..sort((a, b) => b.compareTo(a));

List<GameSession> _applyFilter(
    List<GameSession> all, int? year, int? month,
    {bool withExpansionsOnly = false}) {
  var list = all;
  if (year != null) {
    list = list.where((s) => s.startTime.year == year).toList();
    if (month != null) {
      list = list.where((s) => s.startTime.month == month).toList();
    }
  }
  if (withExpansionsOnly) {
    list = list.where((s) => s.expansionIds.isNotEmpty).toList();
  }
  return list;
}

List<GameSession> _applySort(List<GameSession> sessions, _HistorySortOrder sort) {
  final list = List<GameSession>.from(sessions);
  switch (sort) {
    case _HistorySortOrder.newest:
      list.sort((a, b) => b.startTime.compareTo(a.startTime));
    case _HistorySortOrder.oldest:
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
    case _HistorySortOrder.byGame:
      list.sort((a, b) => a.gameName.toLowerCase().compareTo(b.gameName.toLowerCase()));
  }
  return list;
}

const _kMonths = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

// ─── Screen ────────────────────────────────────────────────────────────────────

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int? _selectedYear;
  int? _selectedMonth;
  bool _withExpansionsOnly = false;
  _HistorySortOrder _sortOrder = _HistorySortOrder.newest;

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
        initialWithExpansions: _withExpansionsOnly,
        onApply: (year, month, withExpansions) => setState(() {
          _selectedYear = year;
          _selectedMonth = month;
          _withExpansionsOnly = withExpansions;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final provider = context.watch<SessionProvider>();
    final allSessions = provider.sessions;
    final filteredSessions = _applySort(
      _applyFilter(allSessions, _selectedYear, _selectedMonth,
          withExpansionsOnly: _withExpansionsOnly),
      _sortOrder,
    );
    final filterActive = _selectedYear != null || _withExpansionsOnly;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.historyTitle),
        centerTitle: true,
        actions: [
          PopupMenuButton<_HistorySortOrder>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _sortOrder = v),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _HistorySortOrder.newest,
                child: Text(s.historySortNewest),
              ),
              PopupMenuItem(
                value: _HistorySortOrder.oldest,
                child: Text(s.historySortOldest),
              ),
              PopupMenuItem(
                value: _HistorySortOrder.byGame,
                child: Text(s.historySortByGame),
              ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterSheet(context, allSessions),
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
      ),
      body: allSessions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(s.historyEmpty,
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : filteredSessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(s.historyNoPeriod,
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredSessions.length,
                  itemBuilder: (context, index) =>
                      _SessionCard(session: filteredSessions[index]),
                ),
    );
  }
}

// ─── Filter bottom sheet ───────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  final List<GameSession> allSessions;
  final int? initialYear;
  final int? initialMonth;
  final bool initialWithExpansions;
  final void Function(int? year, int? month, bool withExpansions) onApply;

  const _FilterSheet({
    required this.allSessions,
    required this.initialYear,
    required this.initialMonth,
    required this.initialWithExpansions,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  int? _year;
  int? _month;
  bool _withExpansions = false;

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
    _month = widget.initialMonth;
    _withExpansions = widget.initialWithExpansions;
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
          Text(s.historyFilterTitle,
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
          const SizedBox(height: 12),
          FilterChip(
            label: Text(s.historyFilterWithExpansions),
            avatar: const Icon(Icons.extension, size: 14),
            selected: _withExpansions,
            onSelected: (v) => setState(() => _withExpansions = v),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onApply(_year, _month, _withExpansions);
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

// ─── Session card ─────────────────────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final GameSession session;
  const _SessionCard({required this.session});

  void _rematch(BuildContext context, game) {
    final playerNames = session.players.map((p) => p.playerName).toList();
    final teamAssignments = <String, String>{};
    for (final p in session.players) {
      if (p.teamName != null) teamAssignments[p.playerName] = p.teamName!;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewSessionScreen(
          preselectedGame: game,
          prefilledPlayers: playerNames,
          prefilledGuestGameName: game == null ? session.gameName : null,
          prefilledExpansionIds: session.expansionIds.isNotEmpty
              ? session.expansionIds
              : null,
          prefilledTeamAssignments:
              teamAssignments.isNotEmpty ? teamAssignments : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final winners =
        session.players.where((p) => p.rank == 1).map((p) => p.playerName).join(' & ');
    final winner = winners.isNotEmpty ? winners : '?';
    final dateStr = context.watch<SettingsProvider>().formatDate(session.startTime);

    final game = context
        .watch<GameProvider>()
        .games
        .where((g) => g.id == session.gameId)
        .firstOrNull;
    final imageUrl = game?.thumbnailUrl ?? game?.imageUrl;

    final expansionNames = session.expansionIds.isEmpty
        ? <String>[]
        : session.expansionIds
            .map((id) => game?.id == id
                ? null
                : context
                    .watch<GameProvider>()
                    .games
                    .where((g) => g.id == id)
                    .firstOrNull
                    ?.name)
            .whereType<String>()
            .toList();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
          child: imageUrl == null ? const Icon(Icons.emoji_events) : null,
        ),
        title: Text(session.gameName,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${context.watch<LanguageProvider>().strings.historyWinner(winner)}  •  $dateStr'),
            if (expansionNames.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 2,
                children: expansionNames
                    .map((name) => Chip(
                          label: Text(name,
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.white)),
                          backgroundColor: Colors.deepPurple.shade400,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(session.durationFormatted,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 2),
            GestureDetector(
              onTap: () => _rematch(context, game),
              child: Icon(Icons.replay,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SessionDetailScreen(session: session)),
        ),
      ),
    );
  }
}
