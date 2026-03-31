import 'dart:convert';

class BoardGame {
  final String id;
  final String name;
  final String? description;
  final int minPlayers;
  final int maxPlayers;
  final String? setupHints;
  final DateTime createdAt;
  final bool hasBeenPlayed;
  final String? imageUrl;
  final String? thumbnailUrl;
  final int? minPlaytime;
  final int? maxPlaytime;
  final double? bggRating;
  final double? complexity;
  final double? myRating;
  final double? myWeight;
  final String? bggId;
  final bool isExpansion;
  final String? baseGameId;
  final List<String> categories;
  final List<String> mechanics;
  final int? yearPublished;
  final int? minAge;
  final double? boughtPrice;
  final double? currentPrice;
  final DateTime? acquiredAt;
  final bool isSealed;

  const BoardGame({
    required this.id,
    required this.name,
    this.description,
    required this.minPlayers,
    required this.maxPlayers,
    this.setupHints,
    required this.createdAt,
    this.hasBeenPlayed = false,
    this.imageUrl,
    this.thumbnailUrl,
    this.minPlaytime,
    this.maxPlaytime,
    this.bggRating,
    this.complexity,
    this.myRating,
    this.myWeight,
    this.bggId,
    this.isExpansion = false,
    this.baseGameId,
    this.categories = const [],
    this.mechanics = const [],
    this.yearPublished,
    this.minAge,
    this.boughtPrice,
    this.currentPrice,
    this.acquiredAt,
    this.isSealed = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'min_players': minPlayers,
        'max_players': maxPlayers,
        'setup_hints': setupHints,
        'created_at': createdAt.toIso8601String(),
        'has_been_played': hasBeenPlayed ? 1 : 0,
        'image_url': imageUrl,
        'thumbnail_url': thumbnailUrl,
        'min_playtime': minPlaytime,
        'max_playtime': maxPlaytime,
        'bgg_rating': bggRating,
        'complexity': complexity,
        'my_rating': myRating,
        'my_weight': myWeight,
        'bgg_id': bggId,
        'is_expansion': isExpansion ? 1 : 0,
        'base_game_id': baseGameId,
        'categories': jsonEncode(categories),
        'mechanics': jsonEncode(mechanics),
        'year_published': yearPublished,
        'min_age': minAge,
        'bought_price': boughtPrice,
        'current_price': currentPrice,
        'acquired_at': acquiredAt?.toIso8601String(),
        'is_sealed': isSealed ? 1 : 0,
      };

  static List<String> _parseJsonList(dynamic raw) {
    if (raw is String && raw.isNotEmpty) {
      try {
        return List<String>.from(jsonDecode(raw) as List);
      } catch (_) {}
    }
    return [];
  }

  factory BoardGame.fromMap(Map<String, dynamic> map) => BoardGame(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        minPlayers: map['min_players'] as int,
        maxPlayers: map['max_players'] as int,
        setupHints: map['setup_hints'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        hasBeenPlayed: (map['has_been_played'] as int? ?? 0) == 1,
        imageUrl: map['image_url'] as String?,
        thumbnailUrl: map['thumbnail_url'] as String?,
        minPlaytime: map['min_playtime'] as int?,
        maxPlaytime: map['max_playtime'] as int?,
        bggRating: map['bgg_rating'] as double?,
        complexity: map['complexity'] as double?,
        myRating: map['my_rating'] as double?,
        myWeight: map['my_weight'] as double?,
        bggId: map['bgg_id'] as String?,
        isExpansion: (map['is_expansion'] as int? ?? 0) == 1,
        baseGameId: map['base_game_id'] as String?,
        categories: _parseJsonList(map['categories']),
        mechanics: _parseJsonList(map['mechanics']),
        yearPublished: map['year_published'] as int?,
        minAge: map['min_age'] as int?,
        boughtPrice: (map['bought_price'] as num?)?.toDouble(),
        currentPrice: (map['current_price'] as num?)?.toDouble(),
        acquiredAt: map['acquired_at'] != null
            ? DateTime.tryParse(map['acquired_at'] as String)
            : null,
        isSealed: (map['is_sealed'] as int? ?? 0) == 1,
      );

  BoardGame copyWith({
    String? name,
    String? description,
    int? minPlayers,
    int? maxPlayers,
    String? setupHints,
    bool? hasBeenPlayed,
    String? imageUrl,
    String? thumbnailUrl,
    int? minPlaytime,
    int? maxPlaytime,
    double? bggRating,
    double? complexity,
    double? myRating,
    double? myWeight,
    String? bggId,
    bool? isExpansion,
    String? baseGameId,
    List<String>? categories,
    List<String>? mechanics,
    int? yearPublished,
    int? minAge,
    Object? boughtPrice = _sentinel,
    Object? currentPrice = _sentinel,
    Object? acquiredAt = _sentinel,
    bool? isSealed,
  }) =>
      BoardGame(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        minPlayers: minPlayers ?? this.minPlayers,
        maxPlayers: maxPlayers ?? this.maxPlayers,
        setupHints: setupHints ?? this.setupHints,
        createdAt: createdAt,
        hasBeenPlayed: hasBeenPlayed ?? this.hasBeenPlayed,
        imageUrl: imageUrl ?? this.imageUrl,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        minPlaytime: minPlaytime ?? this.minPlaytime,
        maxPlaytime: maxPlaytime ?? this.maxPlaytime,
        bggRating: bggRating ?? this.bggRating,
        complexity: complexity ?? this.complexity,
        myRating: myRating ?? this.myRating,
        myWeight: myWeight ?? this.myWeight,
        bggId: bggId ?? this.bggId,
        isExpansion: isExpansion ?? this.isExpansion,
        baseGameId: baseGameId ?? this.baseGameId,
        categories: categories ?? this.categories,
        mechanics: mechanics ?? this.mechanics,
        yearPublished: yearPublished ?? this.yearPublished,
        minAge: minAge ?? this.minAge,
        boughtPrice:
            boughtPrice == _sentinel ? this.boughtPrice : boughtPrice as double?,
        currentPrice: currentPrice == _sentinel
            ? this.currentPrice
            : currentPrice as double?,
        acquiredAt:
            acquiredAt == _sentinel ? this.acquiredAt : acquiredAt as DateTime?,
        isSealed: isSealed ?? this.isSealed,
      );
}

const _sentinel = Object();
