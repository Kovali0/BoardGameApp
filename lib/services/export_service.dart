import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/board_game.dart';
import '../models/game_session.dart';
import '../models/wishlist_item.dart';
import 'stats_service.dart';

class ExportService {
  ExportService._();

  // ── CSV helpers ─────────────────────────────────────────────────────────────

  static String _cell(dynamic v) {
    if (v == null) return '';
    final s = v.toString();
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  static String _row(List<dynamic> cols) => cols.map(_cell).join(',');

  // ── JSON ────────────────────────────────────────────────────────────────────

  static String generateJson(
    List<BoardGame> games,
    List<GameSession> sessions,
    List<WishlistItem> wishlist,
  ) {
    final data = {
      'exported_at': DateTime.now().toIso8601String(),
      'schema_version': 1,
      'games': games.map((g) => g.toMap()).toList(),
      'sessions': sessions.map((s) {
        final map = s.toMap();
        map['players'] = s.players
            .map((p) => {
                  'player_name': p.playerName,
                  'rank': p.rank,
                  'score': p.score,
                  'started_game': p.startedGame,
                  'team_name': p.teamName,
                })
            .toList();
        return map;
      }).toList(),
      'wishlist': wishlist.map((w) => w.toMap()).toList(),
    };
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  // ── Sessions CSV ─────────────────────────────────────────────────────────────

  static String generateSessionsCsv(List<GameSession> sessions) {
    final sb = StringBuffer();
    sb.writeln(_row([
      'session_id', 'game_name', 'date', 'duration_min', 'location',
      'tiebreaker', 'notes', 'expansions_count',
      'player_name', 'rank', 'score', 'started_game', 'team',
    ]));
    for (final sess in sessions) {
      for (final p in sess.players) {
        sb.writeln(_row([
          sess.id,
          sess.gameName,
          sess.startTime.toIso8601String().substring(0, 10),
          (sess.durationSeconds / 60).round(),
          sess.location,
          sess.tiebreaker,
          sess.notes,
          sess.expansionIds.length,
          p.playerName,
          p.rank,
          p.score,
          p.startedGame ? 'yes' : 'no',
          p.teamName,
        ]));
      }
    }
    return sb.toString();
  }

  // ── Collection CSV ────────────────────────────────────────────────────────────

  static String generateCollectionCsv(List<BoardGame> games) {
    final sb = StringBuffer();
    sb.writeln(_row([
      'name', 'type', 'min_players', 'max_players',
      'min_playtime', 'max_playtime', 'bgg_rating', 'complexity',
      'my_rating', 'year_published', 'min_age',
      'categories', 'mechanics', 'has_been_played', 'added_at',
    ]));
    for (final g in games) {
      sb.writeln(_row([
        g.name,
        g.isExpansion ? 'expansion' : 'base game',
        g.minPlayers,
        g.maxPlayers,
        g.minPlaytime,
        g.maxPlaytime,
        g.bggRating,
        g.complexity,
        g.myRating,
        g.yearPublished,
        g.minAge,
        g.categories.join('; '),
        g.mechanics.join('; '),
        g.hasBeenPlayed ? 'yes' : 'no',
        g.createdAt.toIso8601String().substring(0, 10),
      ]));
    }
    return sb.toString();
  }

  // ── Wishlist CSV ──────────────────────────────────────────────────────────────

  static String generateWishlistCsv(List<WishlistItem> items) {
    final sb = StringBuffer();
    sb.writeln(_row([
      'name', 'priority', 'price', 'bgg_rating', 'complexity',
      'min_players', 'max_players', 'note', 'added_at',
    ]));
    const priorities = {1: 'Low', 2: 'Medium', 3: 'High'};
    for (final item in items) {
      sb.writeln(_row([
        item.name,
        priorities[item.priority] ?? item.priority,
        item.price,
        item.bggRating,
        item.complexity,
        item.minPlayers,
        item.maxPlayers,
        item.note,
        item.addedAt.toIso8601String().substring(0, 10),
      ]));
    }
    return sb.toString();
  }

  // ── Statistics CSV ────────────────────────────────────────────────────────────

  static String generateStatsCsv(List<GameSession> sessions) {
    final sb = StringBuffer();

    // ── Section 1: Global ──
    sb.writeln('GLOBAL STATS');
    sb.writeln(_row([
      'total_sessions', 'unique_games',
      'total_time_hours', 'avg_session_min',
    ]));
    final global = StatsService.computeGlobalStats(sessions);
    if (global != null) {
      sb.writeln(_row([
        global.totalSessions,
        global.uniqueGames,
        (global.totalSeconds / 3600).toStringAsFixed(1),
        (global.avgSeconds / 60).round(),
      ]));
    } else {
      sb.writeln(_row([0, 0, 0, 0]));
    }

    sb.writeln();

    // ── Section 2: Player rankings ──
    sb.writeln('PLAYER RANKINGS');
    sb.writeln(_row(['rank', 'player_name', 'total_games', 'wins', 'win_rate_%']));
    final players = StatsService.computePlayerList(sessions);
    for (int i = 0; i < players.length; i++) {
      final p = players[i];
      final winRate = p.sessions > 0
          ? (p.wins / p.sessions * 100).toStringAsFixed(1)
          : '0.0';
      sb.writeln(_row([i + 1, p.name, p.sessions, p.wins, winRate]));
    }

    sb.writeln();

    // ── Section 3: Game stats ──
    sb.writeln('GAME STATS');
    sb.writeln(_row([
      'game_name', 'sessions', 'avg_duration_min',
      'best_player', 'highest_score', 'lowest_score', 'avg_score',
    ]));
    final gameStats = StatsService.computeGameStats(sessions);
    final sortedGames = gameStats.values.toList()
      ..sort((a, b) => b.sessionCount.compareTo(a.sessionCount));
    for (final g in sortedGames) {
      sb.writeln(_row([
        g.name,
        g.sessionCount,
        (g.avgSeconds / 60).round(),
        g.bestPlayer,
        g.highestScore,
        g.lowestScore,
        g.avgScore?.toStringAsFixed(1),
      ]));
    }

    return sb.toString();
  }

  // ── Share helpers ─────────────────────────────────────────────────────────────

  static Future<void> shareFile(String content, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content, encoding: utf8);
    await Share.shareXFiles([XFile(file.path)], subject: filename);
  }

  static Future<void> shareZip(
    Map<String, String> files,
    String zipName,
  ) async {
    final archive = Archive();
    for (final entry in files.entries) {
      final bytes = utf8.encode(entry.value);
      archive.addFile(ArchiveFile(entry.key, bytes.length, bytes));
    }
    final zipBytes = ZipEncoder().encode(archive)!;
    final dir = await getTemporaryDirectory();
    final zipFile = File('${dir.path}/$zipName');
    await zipFile.writeAsBytes(zipBytes);
    await Share.shareXFiles([XFile(zipFile.path)], subject: zipName);
  }

  // ── High-level actions ────────────────────────────────────────────────────────

  static String _zipName() {
    final d = DateTime.now();
    final date =
        '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
    return 'mbgs_export_$date.zip';
  }

  static String _jsonName() {
    final d = DateTime.now();
    final date =
        '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
    return 'mbgs_backup_$date.json';
  }

  static Future<void> exportJson(
    List<BoardGame> games,
    List<GameSession> sessions,
    List<WishlistItem> wishlist,
  ) async {
    final content = generateJson(games, sessions, wishlist);
    await shareFile(content, _jsonName());
  }

  static Future<void> exportZip(
    List<BoardGame> games,
    List<GameSession> sessions,
    List<WishlistItem> wishlist,
  ) async {
    final files = {
      'backup.json': generateJson(games, sessions, wishlist),
      'sessions.csv': generateSessionsCsv(sessions),
      'collection.csv': generateCollectionCsv(games),
      'wishlist.csv': generateWishlistCsv(wishlist),
      'statistics.csv': generateStatsCsv(sessions),
    };
    await shareZip(files, _zipName());
  }

  static Future<void> exportSessionsCsv(List<GameSession> sessions) async {
    await shareFile(generateSessionsCsv(sessions), 'mbgs_sessions.csv');
  }

  static Future<void> exportCollectionCsv(List<BoardGame> games) async {
    await shareFile(generateCollectionCsv(games), 'mbgs_collection.csv');
  }

  static Future<void> exportWishlistCsv(List<WishlistItem> wishlist) async {
    await shareFile(generateWishlistCsv(wishlist), 'mbgs_wishlist.csv');
  }

  static Future<void> exportStatsCsv(List<GameSession> sessions) async {
    await shareFile(generateStatsCsv(sessions), 'mbgs_statistics.csv');
  }
}
