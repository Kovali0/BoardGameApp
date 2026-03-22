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
  final String? thumbnailUrl;
  final int? minPlaytime;
  final int? maxPlaytime;
  final double? bggRating;
  final double? complexity;
  final bool isExpansion; // true if type=boardgameexpansion on BGG

  const BggSearchResult({
    required this.id,
    required this.name,
    this.year,
    this.minPlayers,
    this.maxPlayers,
    this.imageUrl,
    this.thumbnailUrl,
    this.minPlaytime,
    this.maxPlaytime,
    this.bggRating,
    this.complexity,
    this.isExpansion = false,
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
  final String? thumbnailUrl;
  final int? minPlaytime;
  final int? maxPlaytime;
  final double? bggRating;
  final double? complexity;

  const BggGameDetail({
    required this.id,
    required this.name,
    this.description,
    required this.minPlayers,
    required this.maxPlayers,
    this.yearPublished,
    this.imageUrl,
    this.thumbnailUrl,
    this.minPlaytime,
    this.maxPlaytime,
    this.bggRating,
    this.complexity,
  });
}

class BggExpansionItem {
  final String bggId;
  final String name;
  final String? thumbnailUrl;
  final String? imageUrl;
  final double? bggRating;
  final int? yearPublished;
  final int? minPlayers;
  final int? maxPlayers;
  final int? minPlaytime;
  final int? maxPlaytime;
  final double? complexity;

  const BggExpansionItem({
    required this.bggId,
    required this.name,
    this.thumbnailUrl,
    this.imageUrl,
    this.bggRating,
    this.yearPublished,
    this.minPlayers,
    this.maxPlayers,
    this.minPlaytime,
    this.maxPlaytime,
    this.complexity,
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

    // Step 1: Search by name — boardgame + boardgameexpansion
    final searchUri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
      'query': query.trim(),
      'type': 'boardgame,boardgameexpansion',
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

    // Step 2: Fetch details for all IDs — no type filter so expansions are included
    var detailUri = Uri.parse('$_baseUrl/thing').replace(queryParameters: {
      'id': ids,
      'stats': '1',
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

      final itemType = item.getAttribute('type') ?? '';
      final isExpansion = itemType == 'boardgameexpansion';

      final primaryName = item
          .findAllElements('name')
          .where((e) => e.getAttribute('type') == 'primary')
          .firstOrNull ??
          item.findAllElements('name').firstOrNull;
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

      final minTimeStr =
          item.findAllElements('minplaytime').firstOrNull?.getAttribute('value');
      final maxTimeStr =
          item.findAllElements('maxplaytime').firstOrNull?.getAttribute('value');
      final minPlaytime = minTimeStr != null ? int.tryParse(minTimeStr) : null;
      final maxPlaytime = maxTimeStr != null ? int.tryParse(maxTimeStr) : null;

      final rawImage =
          item.findAllElements('image').firstOrNull?.innerText.trim();
      final rawThumb =
          item.findAllElements('thumbnail').firstOrNull?.innerText.trim();

      final ratings = item.findAllElements('ratings').firstOrNull;
      final ratingStr =
          ratings?.findAllElements('average').firstOrNull?.getAttribute('value');
      final complexityStr =
          ratings?.findAllElements('averageweight').firstOrNull?.getAttribute('value');
      final bggRating = ratingStr != null ? double.tryParse(ratingStr) : null;
      final complexity =
          complexityStr != null ? double.tryParse(complexityStr) : null;

      results.add(BggSearchResult(
        id: id,
        name: name,
        year: year,
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
        imageUrl: _normalizeImageUrl(rawImage),
        thumbnailUrl: _normalizeImageUrl(rawThumb),
        minPlaytime: minPlaytime,
        maxPlaytime: maxPlaytime,
        bggRating: (bggRating != null && bggRating > 0) ? bggRating : null,
        complexity: (complexity != null && complexity > 0) ? complexity : null,
        isExpansion: isExpansion,
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
      'stats': '1',
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

    final minTimeStr =
        item.findAllElements('minplaytime').firstOrNull?.getAttribute('value');
    final maxTimeStr =
        item.findAllElements('maxplaytime').firstOrNull?.getAttribute('value');
    final minPlaytime = minTimeStr != null ? int.tryParse(minTimeStr) : null;
    final maxPlaytime = maxTimeStr != null ? int.tryParse(maxTimeStr) : null;

    final descRaw =
        item.findAllElements('description').firstOrNull?.innerText;
    final desc = descRaw
        ?.replaceAll('&#10;', '\n')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .trim();

    final rawImage =
        item.findAllElements('image').firstOrNull?.innerText.trim();
    final rawThumb =
        item.findAllElements('thumbnail').firstOrNull?.innerText.trim();

    final ratings = item.findAllElements('ratings').firstOrNull;
    final ratingStr =
        ratings?.findAllElements('average').firstOrNull?.getAttribute('value');
    final complexityStr =
        ratings?.findAllElements('averageweight').firstOrNull?.getAttribute('value');
    final bggRating = ratingStr != null ? double.tryParse(ratingStr) : null;
    final complexity =
        complexityStr != null ? double.tryParse(complexityStr) : null;

    return BggGameDetail(
      id: id,
      name: name,
      description: (desc == null || desc.isEmpty) ? null : desc,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      yearPublished: year,
      imageUrl: _normalizeImageUrl(rawImage),
      thumbnailUrl: _normalizeImageUrl(rawThumb),
      minPlaytime: minPlaytime,
      maxPlaytime: maxPlaytime,
      bggRating: (bggRating != null && bggRating > 0) ? bggRating : null,
      complexity: (complexity != null && complexity > 0) ? complexity : null,
    );
  }

  Future<List<BggExpansionItem>> fetchExpansions(String bggId) async {
    debugPrint('[BGG] fetchExpansions for bggId=$bggId');

    // Step 1: fetch base game details to find expansion links
    final baseUri = Uri.parse('$_baseUrl/thing').replace(queryParameters: {
      'id': bggId,
      'stats': '1',
    });

    var baseResponse = await http
        .get(baseUri, headers: _headers)
        .timeout(const Duration(seconds: 20));

    while (baseResponse.statusCode == 202) {
      debugPrint('[BGG] 202 queued, retrying...');
      await Future.delayed(const Duration(seconds: 2));
      baseResponse = await http
          .get(baseUri, headers: _headers)
          .timeout(const Duration(seconds: 20));
    }

    if (baseResponse.statusCode != 200) return [];

    final baseDoc = xml.XmlDocument.parse(baseResponse.body);
    final baseItem = baseDoc.findAllElements('item').firstOrNull;
    if (baseItem == null) return [];

    // Collect expansion IDs: <link type="boardgameexpansion"> without inbound="true"
    final expansionIds = baseItem
        .findAllElements('link')
        .where((e) =>
            e.getAttribute('type') == 'boardgameexpansion' &&
            e.getAttribute('inbound') != 'true')
        .map((e) => e.getAttribute('id'))
        .where((id) => id != null && id.isNotEmpty)
        .cast<String>()
        .toList();

    debugPrint('[BGG] found ${expansionIds.length} expansion IDs');
    if (expansionIds.isEmpty) return [];

    // Step 2: batch-fetch details in chunks of 20 to avoid URL limits
    final results = <BggExpansionItem>[];
    const chunkSize = 20;
    for (int start = 0; start < expansionIds.length; start += chunkSize) {
      final chunk = expansionIds.skip(start).take(chunkSize).toList();
      final ids = chunk.join(',');
      var detailUri = Uri.parse('$_baseUrl/thing').replace(queryParameters: {
        'id': ids,
        'type': 'boardgameexpansion',
        'stats': '1',
      });

      var detailResponse = await http
          .get(detailUri, headers: _headers)
          .timeout(const Duration(seconds: 30));

      while (detailResponse.statusCode == 202) {
        debugPrint('[BGG] 202 queued, retrying...');
        await Future.delayed(const Duration(seconds: 2));
        detailResponse = await http
            .get(detailUri, headers: _headers)
            .timeout(const Duration(seconds: 30));
      }

      if (detailResponse.statusCode != 200) continue;

      final detailDoc = xml.XmlDocument.parse(detailResponse.body);
      for (final item in detailDoc.findAllElements('item')) {
        final id = item.getAttribute('id');
        if (id == null) continue;

        // Primary name, with fallback to any name element
        final nameEl = item
            .findAllElements('name')
            .where((e) => e.getAttribute('type') == 'primary')
            .firstOrNull ??
            item.findAllElements('name').firstOrNull;
        final name = nameEl?.getAttribute('value');
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

      final minTimeStr =
          item.findAllElements('minplaytime').firstOrNull?.getAttribute('value');
      final maxTimeStr =
          item.findAllElements('maxplaytime').firstOrNull?.getAttribute('value');
      final minPlaytime = minTimeStr != null ? int.tryParse(minTimeStr) : null;
      final maxPlaytime = maxTimeStr != null ? int.tryParse(maxTimeStr) : null;

      final rawImage =
          item.findAllElements('image').firstOrNull?.innerText.trim();
      final rawThumb =
          item.findAllElements('thumbnail').firstOrNull?.innerText.trim();

      final ratings = item.findAllElements('ratings').firstOrNull;
      final ratingStr =
          ratings?.findAllElements('average').firstOrNull?.getAttribute('value');
      final complexityStr =
          ratings?.findAllElements('averageweight').firstOrNull?.getAttribute('value');
      final bggRating = ratingStr != null ? double.tryParse(ratingStr) : null;
      final complexity =
          complexityStr != null ? double.tryParse(complexityStr) : null;

      results.add(BggExpansionItem(
        bggId: id,
        name: name,
        thumbnailUrl: _normalizeImageUrl(rawThumb),
        imageUrl: _normalizeImageUrl(rawImage),
        bggRating: (bggRating != null && bggRating > 0) ? bggRating : null,
        yearPublished: year,
        minPlayers: minPlayers,
        maxPlayers: maxPlayers,
        minPlaytime: minPlaytime,
        maxPlaytime: maxPlaytime,
        complexity: (complexity != null && complexity > 0) ? complexity : null,
      ));
      } // end for item in chunk
    } // end for chunk

    // Sort by year asc then name
    results.sort((a, b) {
      final ya = a.yearPublished ?? 0;
      final yb = b.yearPublished ?? 0;
      if (ya != yb) return ya.compareTo(yb);
      return a.name.compareTo(b.name);
    });

    debugPrint('[BGG] fetchExpansions returning ${results.length} items');
    return results;
  }

  /// BGG returns protocol-relative URLs like "//cf.geekdo-images.com/...".
  /// Prepend https: when needed.
  static String? _normalizeImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('//')) return 'https:$raw';
    return raw;
  }
}
