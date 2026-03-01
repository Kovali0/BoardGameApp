import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/board_game.dart';
import '../db/database_helper.dart';

class GameProvider with ChangeNotifier {
  final _db = DatabaseHelper();
  final _uuid = const Uuid();
  List<BoardGame> _games = [];

  List<BoardGame> get games => List.unmodifiable(_games);

  Future<void> loadGames() async {
    _games = await _db.getGames();
    notifyListeners();
  }

  Future<void> addGame({
    required String name,
    String? description,
    required int minPlayers,
    required int maxPlayers,
    String? setupHints,
  }) async {
    final game = BoardGame(
      id: _uuid.v4(),
      name: name,
      description: description,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      setupHints: setupHints,
      createdAt: DateTime.now(),
    );
    await _db.insertGame(game);
    _games.add(game);
    _games.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
  }

  Future<void> updateGame(BoardGame game) async {
    await _db.updateGame(game);
    final index = _games.indexWhere((g) => g.id == game.id);
    if (index != -1) {
      _games[index] = game;
      _games.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }
  }

  Future<void> deleteGame(String id) async {
    await _db.deleteGame(id);
    _games.removeWhere((g) => g.id == id);
    notifyListeners();
  }
}
