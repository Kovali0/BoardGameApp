import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/game_provider.dart';
import '../../models/game_session.dart';
import 'session_detail_screen.dart';

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

// ─── Screen ────────────────────────────────────────────────────────────────────

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int? _selectedYear;
  int? _selectedMonth;

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
    final provider = context.watch<SessionProvider>();
    final allSessions = provider.sessions;
    final filteredSessions = _applyFilter(allSessions, _selectedYear, _selectedMonth);
    final filterActive = _selectedYear != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions history'),
        centerTitle: true,
        actions: [
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
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No sessions yet. Play a game!',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : filteredSessions.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No sessions in this period.',
                          style: TextStyle(color: Colors.grey)),
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
    final years = _years(widget.allSessions);
    final months = _year == null ? <int>[] : _months(widget.allSessions, _year!);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter sessions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Year', style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilterChip(
                label: const Text('All'),
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
            const Text('Month', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilterChip(
                  label: const Text('All'),
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
              child: const Text('Apply'),
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

  @override
  Widget build(BuildContext context) {
    final winners =
        session.players.where((p) => p.rank == 1).map((p) => p.playerName).join(' & ');
    final winner = winners.isNotEmpty ? winners : '?';
    final date = session.startTime;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

    final game = context
        .watch<GameProvider>()
        .games
        .where((g) => g.id == session.gameId)
        .firstOrNull;
    final imageUrl = game?.thumbnailUrl ?? game?.imageUrl;

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
        subtitle: Text('Winner: $winner  •  $dateStr'),
        trailing: Text(session.durationFormatted,
            style: Theme.of(context).textTheme.bodySmall),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => SessionDetailScreen(session: session)),
        ),
      ),
    );
  }
}
