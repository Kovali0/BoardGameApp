import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/game_session.dart';
import '../../../providers/language_provider.dart';
import '../../../services/stats_service.dart';
import '../details/head_to_head_screen.dart';
import '../details/player_detail_screen.dart';
import '../shared/stat_widgets.dart';

class PlayersStatsTab extends StatefulWidget {
  final List<GameSession> sessions;
  const PlayersStatsTab({super.key, required this.sessions});

  @override
  State<PlayersStatsTab> createState() => _PlayersStatsTabState();
}

class _PlayersStatsTabState extends State<PlayersStatsTab> {
  String? _playerA;
  String? _playerB;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final playerList = StatsService.computePlayerList(widget.sessions);

    if (playerList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(s.statsNoPlayers,
                style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(s.statsPlayForPlayerStats,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final playerNames = playerList.map((e) => e.name).toList();
    if (_playerA != null && !playerNames.contains(_playerA)) _playerA = null;
    if (_playerB != null && !playerNames.contains(_playerB)) _playerB = null;

    final canCompare =
        _playerA != null && _playerB != null && _playerA != _playerB;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Head-to-head picker ──
        if (playerList.length >= 2) ...[
          StatsSectionHeader(s.statsHeadToHead),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _playerA,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            hintText: s.statsSelectPlayer,
                          ),
                          hint: Text(s.statsSelectPlayer,
                              style: const TextStyle(fontSize: 13)),
                          isExpanded: true,
                          items: playerNames
                              .where((n) => n != _playerB)
                              .map((n) => DropdownMenuItem(
                                  value: n,
                                  child: Text(n,
                                      overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (v) => setState(() => _playerA = v),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'VS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _playerB,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            hintText: s.statsSelectPlayer,
                          ),
                          hint: Text(s.statsSelectPlayer,
                              style: const TextStyle(fontSize: 13)),
                          isExpanded: true,
                          items: playerNames
                              .where((n) => n != _playerA)
                              .map((n) => DropdownMenuItem(
                                  value: n,
                                  child: Text(n,
                                      overflow: TextOverflow.ellipsis)))
                              .toList(),
                          onChanged: (v) => setState(() => _playerB = v),
                        ),
                      ),
                    ],
                  ),
                  if (canCompare) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => HeadToHeadScreen(
                            playerA: _playerA!,
                            playerB: _playerB!,
                            sessions: widget.sessions,
                          ),
                        )),
                        icon: const Icon(Icons.compare_arrows, size: 18),
                        label: Text(s.statsViewRivalry),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Player list ──
        for (int i = 0; i < playerList.length; i++) ...[
          Card(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text(playerList[i].name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${playerList[i].sessions} session${playerList[i].sessions == 1 ? '' : 's'} · '
                '${playerList[i].wins} win${playerList[i].wins == 1 ? '' : 's'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PlayerDetailScreen(
                  playerName: playerList[i].name,
                  sessions: widget.sessions,
                ),
              )),
            ),
          ),
          if (i < playerList.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}
