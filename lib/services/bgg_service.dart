import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

class BggSearchResult {
  final String id; // BGG numeric ID
  final String name;
  final int? year;
  final int? minPlayers;
  final int? maxPlayers;
  final String? imageUrl;

  const BggSearchResult({
    required this.id,
    required this.name,
    this.year,
    this.minPlayers,
    this.maxPlayers,
    this.imageUrl,
  });
}

class BggGameDetail {
  final String id;
  final String name;
  final String? description;
  final int minPlayers;
  final int maxPlayers;
  final int? yearPublished;
  final String? imageUrl;

  const BggGameDetail({
    required this.id,
    required this.name,
    this.description,
    required this.minPlayers,
    required this.maxPlayers,
    this.yearPublished,
    this.imageUrl,
  });
}

class BggService {
  static const _bggToken = '7fb814ad-3f61-4c01-a3fb-761c06d906ef';
  static const _baseUrl = 'https://boardgamegeek.com/xmlapi2';

  static const _headers = {
    'Authorization': 'Bearer $_bggToken',
    'User-Agent': 'MBGS-BoardGameApp/1.0 (personal board game tracker)',
  };

  Future<List<BggSearchResult>> searchGames(String query) async {
    if (query.trim().isEmpty) return [];
    debugPrint('[BGG] searchGames: "$query"');

    // Step 1: Search by name — returns IDs and basic names
    final searchUri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
      'query': query.trim(),
      'type': 'boardgame',
    });

    final searchResponse = await http
        .get(searchUri, headers: _headers)
        .timeout(const Duration(seconds: 20));

    debugPrint('[BGG] search status=${searchResponse.statusCode}');
    if (searchResponse.statusCode != 200) return [];

    final searchDoc = xml.XmlDocument.parse(searchResponse.body);
    final items = searchDoc.findAllElements('item').toList();
    debugPrint('[BGG] search raw hits: ${items.length}');
    if (items.isEmpty) return [];

    // Take top 20 results for detail lookup
    final ids = items
        .take(20)
        .map((e) => e.getAttribute('id'))
        .where((id) => id != null)
        .join(',');

    // Step 2: Fetch details (player counts, year) for all IDs in one call
    var detailUri = Uri.parse('$_baseUrl/thing').replace(queryParameters: {
      'id': ids,
      'type': 'boardgame',
    });

    var detailResponse = await http
        .get(detailUri, headers: _headers)
        .timeout(const Duration(seconds: 20));

    // BGG may return 202 (queued) — retry until ready
    while (detailResponse.statusCode == 202) {
      debugPrint('[BGG] 202 queued, retrying...');
      await Future.delayed(const Duration(seconds: 2));
      detailResponse = await http
          .get(detailUri, headers: _headers)
          .timeout(const Duration(seconds: 20));
    }

    debugPrint('[BGG] detail status=${detailResponse.statusCode}');
    if (detailResponse.statusCode != 200) return [];

    final detailDoc = xml.XmlDocument.parse(detailResponse.body);
    final detailItems = detailDoc.findAllElements('item');

    final results = <BggSearchResult>[];
    for (final item in detailItems) {
      final id = item.getAttribute('id');
      if (id == null) continue;

      final primaryName = item
          .findAllElements('name')
          .where((e) => e.getAttribute('type') == 'primary')
          .firstOrNull;
      final name = primaryName?.getAttribute('value');
      if (name == null || name.isEmpty) continue;

      final yearStr =
          item.findAllElements('yearpublished').firstOrNull?.getAttribute('value');
      final year = yearStr != null ? int.tryParse(yearStr) : null;

      final minStr =
          item.findAllElements('minplayers').firstOrNull?.getAttribute('value');
      final maxStr =
          item.findAllElements('maxplayers').firstOrNull?.getAttribute('value');
      final minPlayers = minStr != null ? int.tryParse(minStr) : null;
      final maxPlayers = maxStr != null ? int.tryParse(maxStr) : null;

      final rawImage =
          item.findAllElements('image').firstOrNull?.innerText.trim();
      final imageUrl = _normalizeImageUrl(rawImage);

      results.add(BggSearchResult(
        id: id,
        name: name,
        year: year,
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
        imageUrl: imageUrl,
      ));
    }

    // Exact/prefix matches first, then alphabetical
    final q = query.toLowerCase();
    results.sort((a, b) {
      final aName = a.name.toLowerCase();
      final bName = b.name.toLowerCase();
      final aScore = aName == q ? 0 : aName.startsWith(q) ? 1 : 2;
      final bScore = bName == q ? 0 : bName.startsWith(q) ? 1 : 2;
      if (aScore != bScore) return aScore.compareTo(bScore);
      return aName.compareTo(bName);
    });

    debugPrint('[BGG] found ${results.length} board games');
    return results;
  }

  Future<BggGameDetail?> getGameDetail(String id) async {
    final uri = Uri.parse('$_baseUrl/thing').replace(queryParameters: {
      'id': id,
      'type': 'boardgame',
    });

    var response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));

    while (response.statusCode == 202) {
      debugPrint('[BGG] 202 queued, retrying...');
      await Future.delayed(const Duration(seconds: 2));
      response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
    }

    if (response.statusCode != 200) return null;

    final doc = xml.XmlDocument.parse(response.body);
    final item = doc.findAllElements('item').firstOrNull;
    if (item == null) return null;

    final primaryName = item
        .findAllElements('name')
        .where((e) => e.getAttribute('type') == 'primary')
        .firstOrNull;
    final name = primaryName?.getAttribute('value');
    if (name == null) return null;

    final yearStr =
        item.findAllElements('yearpublished').firstOrNull?.getAttribute('value');
    final year = yearStr != null ? int.tryParse(yearStr) : null;

    final minStr =
        item.findAllElements('minplayers').firstOrNull?.getAttribute('value');
    final maxStr =
        item.findAllElements('maxplayers').firstOrNull?.getAttribute('value');
    final minPlayers = (minStr != null ? int.tryParse(minStr) : null) ?? 2;
    final maxPlayers = (maxStr != null ? int.tryParse(maxStr) : null) ?? 4;

    final descRaw =
        item.findAllElements('description').firstOrNull?.innerText;
    final desc = descRaw
        ?.replaceAll('&#10;', '\n')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .trim();

    final rawImage =
        item.findAllElements('image').firstOrNull?.innerText.trim();

    return BggGameDetail(
      id: id,
      name: name,
      description: (desc == null || desc.isEmpty) ? null : desc,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      yearPublished: year,
      imageUrl: _normalizeImageUrl(rawImage),
    );
  }

  /// BGG returns protocol-relative URLs like "//cf.geekdo-images.com/...".
  /// Prepend https: when needed.
  static String? _normalizeImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('//')) return 'https:$raw';
    return raw;
  }
}
