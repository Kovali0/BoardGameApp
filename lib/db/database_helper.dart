import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/board_game.dart';
import '../models/game_session.dart';
import '../models/player_result.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'board_game_manager.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE games (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        min_players INTEGER NOT NULL,
        max_players INTEGER NOT NULL,
        setup_hints TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        game_id TEXT NOT NULL,
        game_name TEXT NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        duration_seconds INTEGER NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE player_results (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        player_name TEXT NOT NULL,
        score INTEGER,
        rank INTEGER NOT NULL,
        started_game INTEGER NOT NULL
      )
    ''');
  }

  // --- Games ---

  Future<void> insertGame(BoardGame game) async {
    final db = await database;
    await db.insert('games', game.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<BoardGame>> getGames() async {
    final db = await database;
    final maps = await db.query('games', orderBy: 'name ASC');
    return maps.map(BoardGame.fromMap).toList();
  }

  Future<void> updateGame(BoardGame game) async {
    final db = await database;
    await db.update('games', game.toMap(),
        where: 'id = ?', whereArgs: [game.id]);
  }

  Future<void> deleteGame(String id) async {
    final db = await database;
    await db.delete('games', where: 'id = ?', whereArgs: [id]);
  }

  // --- Sessions ---

  Future<void> insertSession(GameSession session) async {
    final db = await database;
    await db.insert('sessions', session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    for (final player in session.players) {
      await db.insert('player_results', player.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<List<GameSession>> getSessions() async {
    final db = await database;
    final sessionMaps =
        await db.query('sessions', orderBy: 'start_time DESC');
    final List<GameSession> sessions = [];
    for (final map in sessionMaps) {
      final playerMaps = await db.query(
        'player_results',
        where: 'session_id = ?',
        whereArgs: [map['id']],
        orderBy: 'rank ASC',
      );
      sessions.add(GameSession.fromMap(
          map, playerMaps.map(PlayerResult.fromMap).toList()));
    }
    return sessions;
  }

  Future<void> deleteSession(String id) async {
    final db = await database;
    await db.delete('player_results',
        where: 'session_id = ?', whereArgs: [id]);
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }
}
