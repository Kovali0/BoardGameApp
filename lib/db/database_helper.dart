import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/board_game.dart';
import '../models/game_session.dart';
import '../models/player_result.dart';
import '../models/wishlist_item.dart';

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
    return openDatabase(
      path,
      version: 14,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE sessions ADD COLUMN is_from_collection INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE games ADD COLUMN has_been_played INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE games ADD COLUMN image_url TEXT',
      );
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE games ADD COLUMN thumbnail_url TEXT');
      await db.execute('ALTER TABLE games ADD COLUMN min_playtime INTEGER');
      await db.execute('ALTER TABLE games ADD COLUMN max_playtime INTEGER');
      await db.execute('ALTER TABLE games ADD COLUMN bgg_rating REAL');
      await db.execute('ALTER TABLE games ADD COLUMN complexity REAL');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE games ADD COLUMN my_rating REAL');
      await db.execute('ALTER TABLE games ADD COLUMN my_weight REAL');
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS wishlist (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          note TEXT,
          priority INTEGER NOT NULL DEFAULT 2,
          image_url TEXT,
          thumbnail_url TEXT,
          bgg_rating REAL,
          complexity REAL,
          min_players INTEGER,
          max_players INTEGER,
          added_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 8) {
      await db.execute('ALTER TABLE wishlist ADD COLUMN price REAL');
    }
    if (oldVersion < 9) {
      await db.execute('ALTER TABLE games ADD COLUMN bgg_id TEXT');
      await db.execute('ALTER TABLE games ADD COLUMN is_expansion INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE games ADD COLUMN base_game_id TEXT');
    }
    if (oldVersion < 10) {
      await db.execute("ALTER TABLE sessions ADD COLUMN expansion_ids TEXT DEFAULT '[]'");
    }
    if (oldVersion < 11) {
      await db.execute("ALTER TABLE games ADD COLUMN categories TEXT DEFAULT '[]'");
      await db.execute("ALTER TABLE games ADD COLUMN mechanics TEXT DEFAULT '[]'");
      await db.execute('ALTER TABLE games ADD COLUMN year_published INTEGER');
      await db.execute('ALTER TABLE games ADD COLUMN min_age INTEGER');
    }
    if (oldVersion < 12) {
      await db.execute('ALTER TABLE player_results ADD COLUMN team_name TEXT');
    }
    if (oldVersion < 13) {
      await db.execute('ALTER TABLE sessions ADD COLUMN location TEXT');
    }
    if (oldVersion < 14) {
      await db.execute('ALTER TABLE sessions ADD COLUMN tiebreaker TEXT');
    }
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
        created_at TEXT NOT NULL,
        has_been_played INTEGER NOT NULL DEFAULT 0,
        image_url TEXT,
        thumbnail_url TEXT,
        min_playtime INTEGER,
        max_playtime INTEGER,
        bgg_rating REAL,
        complexity REAL,
        my_rating REAL,
        my_weight REAL,
        bgg_id TEXT,
        is_expansion INTEGER DEFAULT 0,
        base_game_id TEXT,
        categories TEXT DEFAULT '[]',
        mechanics TEXT DEFAULT '[]',
        year_published INTEGER,
        min_age INTEGER
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
        notes TEXT,
        is_from_collection INTEGER NOT NULL DEFAULT 1,
        expansion_ids TEXT DEFAULT '[]',
        location TEXT,
        tiebreaker TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE wishlist (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        note TEXT,
        priority INTEGER NOT NULL DEFAULT 2,
        image_url TEXT,
        thumbnail_url TEXT,
        bgg_rating REAL,
        complexity REAL,
        min_players INTEGER,
        max_players INTEGER,
        price REAL,
        added_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE player_results (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        player_name TEXT NOT NULL,
        score INTEGER,
        rank INTEGER NOT NULL,
        started_game INTEGER NOT NULL,
        team_name TEXT
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
    await db.transaction((txn) async {
      await txn.insert('sessions', session.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      for (final player in session.players) {
        await txn.insert('player_results', player.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<GameSession>> getSessions() async {
    final db = await database;
    final sessionMaps =
        await db.query('sessions', orderBy: 'start_time DESC');
    if (sessionMaps.isEmpty) return [];

    final sessionIds = sessionMaps.map((m) => m['id'] as String).toList();
    final placeholders = List.filled(sessionIds.length, '?').join(',');
    final playerMaps = await db.query(
      'player_results',
      where: 'session_id IN ($placeholders)',
      whereArgs: sessionIds,
      orderBy: 'rank ASC',
    );

    final playersBySession = <String, List<PlayerResult>>{};
    for (final p in playerMaps) {
      final sid = p['session_id'] as String;
      playersBySession.putIfAbsent(sid, () => []).add(PlayerResult.fromMap(p));
    }

    return sessionMaps.map((map) {
      final id = map['id'] as String;
      return GameSession.fromMap(map, playersBySession[id] ?? []);
    }).toList();
  }

  Future<void> deleteSession(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('player_results',
          where: 'session_id = ?', whereArgs: [id]);
      await txn.delete('sessions', where: 'id = ?', whereArgs: [id]);
    });
  }

  // --- Wishlist ---

  Future<void> insertWishlistItem(WishlistItem item) async {
    final db = await database;
    await db.insert('wishlist', item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<WishlistItem>> getWishlistItems() async {
    final db = await database;
    final maps = await db.query('wishlist', orderBy: 'priority DESC, name ASC');
    return maps.map(WishlistItem.fromMap).toList();
  }

  Future<void> updateWishlistItem(WishlistItem item) async {
    final db = await database;
    await db.update('wishlist', item.toMap(),
        where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteWishlistItem(String id) async {
    final db = await database;
    await db.delete('wishlist', where: 'id = ?', whereArgs: [id]);
  }
}
