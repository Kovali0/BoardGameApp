class BoardGame {
  final String id;
  final String name;
  final String? description;
  final int minPlayers;
  final int maxPlayers;
  final String? setupHints;
  final DateTime createdAt;
  final bool hasBeenPlayed;

  const BoardGame({
    required this.id,
    required this.name,
    this.description,
    required this.minPlayers,
    required this.maxPlayers,
    this.setupHints,
    required this.createdAt,
    this.hasBeenPlayed = false,
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
      };

  factory BoardGame.fromMap(Map<String, dynamic> map) => BoardGame(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        minPlayers: map['min_players'] as int,
        maxPlayers: map['max_players'] as int,
        setupHints: map['setup_hints'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        hasBeenPlayed: (map['has_been_played'] as int? ?? 0) == 1,
      );

  BoardGame copyWith({
    String? name,
    String? description,
    int? minPlayers,
    int? maxPlayers,
    String? setupHints,
    bool? hasBeenPlayed,
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
      );
}
