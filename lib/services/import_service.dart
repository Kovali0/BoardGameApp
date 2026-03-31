import 'dart:convert';

class ImportService {
  ImportService._();

  // ── JSON parsing ─────────────────────────────────────────────────────────────

  static ({
    List<Map<String, dynamic>> games,
    List<Map<String, dynamic>> sessions,
    List<Map<String, dynamic>> wishlist,
    String? error,
  }) parseJson(String content) {
    try {
      final data = jsonDecode(content) as Map<String, dynamic>;
      final games =
          (data['games'] as List? ?? []).cast<Map<String, dynamic>>();
      final sessions =
          (data['sessions'] as List? ?? []).cast<Map<String, dynamic>>();
      final wishlist =
          (data['wishlist'] as List? ?? []).cast<Map<String, dynamic>>();
      return (games: games, sessions: sessions, wishlist: wishlist, error: null);
    } catch (e) {
      return (
        games: <Map<String, dynamic>>[],
        sessions: <Map<String, dynamic>>[],
        wishlist: <Map<String, dynamic>>[],
        error: e.toString(),
      );
    }
  }

  // ── Collection CSV ────────────────────────────────────────────────────────────
  // Columns: name, type, min_players, max_players, min_playtime, max_playtime,
  //          bgg_rating, complexity, my_rating, year_published, min_age,
  //          categories, mechanics, has_been_played, added_at

  static List<Map<String, dynamic>> parseCollectionCsv(String content) {
    final lines = _splitLines(content);
    if (lines.length < 2) return [];
    final result = <Map<String, dynamic>>[];
    for (int i = 1; i < lines.length; i++) {
      final c = _parseCsvRow(lines[i]);
      if (c.isEmpty || _s(c, 0).isEmpty) continue;
      result.add({
        'name': _s(c, 0),
        'is_expansion': _s(c, 1) == 'expansion' ? 1 : 0,
        'min_players': int.tryParse(_s(c, 2)) ?? 2,
        'max_players': int.tryParse(_s(c, 3)) ?? 4,
        'min_playtime': int.tryParse(_s(c, 4)),
        'max_playtime': int.tryParse(_s(c, 5)),
        'bgg_rating': double.tryParse(_s(c, 6)),
        'complexity': double.tryParse(_s(c, 7)),
        'my_rating': double.tryParse(_s(c, 8)),
        'year_published': int.tryParse(_s(c, 9)),
        'min_age': int.tryParse(_s(c, 10)),
        'categories': _s(c, 11),
        'mechanics': _s(c, 12),
        'has_been_played': _s(c, 13) == 'yes' ? 1 : 0,
        'added_at': _s(c, 14),
      });
    }
    return result;
  }

  // ── Sessions CSV ──────────────────────────────────────────────────────────────
  // Columns: session_id, game_name, date, duration_min, location, tiebreaker,
  //          notes, expansions_count, player_name, rank, score, started_game, team
  // Returns list of session maps, each with nested 'players' list.

  static List<Map<String, dynamic>> parseSessionsCsv(String content) {
    final lines = _splitLines(content);
    if (lines.length < 2) return [];
    final sessionMap = <String, Map<String, dynamic>>{};
    for (int i = 1; i < lines.length; i++) {
      final c = _parseCsvRow(lines[i]);
      if (c.length < 9 || _s(c, 0).isEmpty) continue;
      final sid = _s(c, 0);
      if (!sessionMap.containsKey(sid)) {
        final dateStr = _s(c, 2);
        sessionMap[sid] = {
          'id': sid,
          'game_id': '',
          'game_name': _s(c, 1),
          'start_time': dateStr.isNotEmpty
              ? '${dateStr}T00:00:00.000'
              : DateTime.now().toIso8601String(),
          'duration_seconds': (int.tryParse(_s(c, 3)) ?? 0) * 60,
          'location': _s(c, 4).isEmpty ? null : _s(c, 4),
          'tiebreaker': _s(c, 5).isEmpty ? null : _s(c, 5),
          'notes': _s(c, 6).isEmpty ? null : _s(c, 6),
          'is_from_collection': 1,
          'expansion_ids': '[]',
          'players': <Map<String, dynamic>>[],
        };
      }
      (sessionMap[sid]!['players'] as List<Map<String, dynamic>>).add({
        'player_name': _s(c, 8),
        'rank': int.tryParse(_s(c, 9)) ?? 1,
        'score': int.tryParse(_s(c, 10)),
        'started_game': _s(c, 11) == 'yes',
        'team_name': _s(c, 12).isEmpty ? null : _s(c, 12),
      });
    }
    return sessionMap.values.toList();
  }

  // ── Wishlist CSV ──────────────────────────────────────────────────────────────
  // Columns: name, priority, price, bgg_rating, complexity,
  //          min_players, max_players, note, added_at

  static List<Map<String, dynamic>> parseWishlistCsv(String content) {
    final lines = _splitLines(content);
    if (lines.length < 2) return [];
    const priorityMap = {'Low': 1, 'Medium': 2, 'High': 3};
    final result = <Map<String, dynamic>>[];
    for (int i = 1; i < lines.length; i++) {
      final c = _parseCsvRow(lines[i]);
      if (c.isEmpty || _s(c, 0).isEmpty) continue;
      result.add({
        'name': _s(c, 0),
        'priority': priorityMap[_s(c, 1)] ?? 2,
        'price': double.tryParse(_s(c, 2)),
        'bgg_rating': double.tryParse(_s(c, 3)),
        'complexity': double.tryParse(_s(c, 4)),
        'min_players': int.tryParse(_s(c, 5)),
        'max_players': int.tryParse(_s(c, 6)),
        'note': _s(c, 7).isEmpty ? null : _s(c, 7),
        'added_at': _s(c, 8),
      });
    }
    return result;
  }

  // ── CSV helpers ───────────────────────────────────────────────────────────────

  static String _s(List<String> cols, int i) =>
      i < cols.length ? cols[i].trim() : '';

  static List<String> _splitLines(String content) => content
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  static List<String> _parseCsvRow(String row) {
    final result = <String>[];
    final sb = StringBuffer();
    bool inQuotes = false;
    for (int i = 0; i < row.length; i++) {
      final ch = row[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < row.length && row[i + 1] == '"') {
          sb.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        result.add(sb.toString());
        sb.clear();
      } else {
        sb.write(ch);
      }
    }
    result.add(sb.toString());
    return result;
  }
}
