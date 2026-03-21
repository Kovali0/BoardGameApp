class WishlistItem {
  final String id;
  final String name;
  final String? note;
  final int priority; // 1=Low, 2=Medium, 3=High
  final String? imageUrl;
  final String? thumbnailUrl;
  final double? bggRating;
  final double? complexity;
  final int? minPlayers;
  final int? maxPlayers;
  final double? price;
  final DateTime addedAt;

  const WishlistItem({
    required this.id,
    required this.name,
    this.note,
    required this.priority,
    this.imageUrl,
    this.thumbnailUrl,
    this.bggRating,
    this.complexity,
    this.minPlayers,
    this.maxPlayers,
    this.price,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'note': note,
        'priority': priority,
        'image_url': imageUrl,
        'thumbnail_url': thumbnailUrl,
        'bgg_rating': bggRating,
        'complexity': complexity,
        'min_players': minPlayers,
        'max_players': maxPlayers,
        'price': price,
        'added_at': addedAt.toIso8601String(),
      };

  factory WishlistItem.fromMap(Map<String, dynamic> map) => WishlistItem(
        id: map['id'] as String,
        name: map['name'] as String,
        note: map['note'] as String?,
        priority: map['priority'] as int? ?? 2,
        imageUrl: map['image_url'] as String?,
        thumbnailUrl: map['thumbnail_url'] as String?,
        bggRating: map['bgg_rating'] as double?,
        complexity: map['complexity'] as double?,
        minPlayers: map['min_players'] as int?,
        maxPlayers: map['max_players'] as int?,
        price: map['price'] as double?,
        addedAt: DateTime.parse(map['added_at'] as String),
      );

  WishlistItem copyWith({
    String? name,
    String? note,
    int? priority,
    String? imageUrl,
    String? thumbnailUrl,
    double? bggRating,
    double? complexity,
    int? minPlayers,
    int? maxPlayers,
    Object? price = _sentinel,
  }) =>
      WishlistItem(
        id: id,
        name: name ?? this.name,
        note: note ?? this.note,
        priority: priority ?? this.priority,
        imageUrl: imageUrl ?? this.imageUrl,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        bggRating: bggRating ?? this.bggRating,
        complexity: complexity ?? this.complexity,
        minPlayers: minPlayers ?? this.minPlayers,
        maxPlayers: maxPlayers ?? this.maxPlayers,
        price: price == _sentinel ? this.price : price as double?,
        addedAt: addedAt,
      );
}

const _sentinel = Object();
