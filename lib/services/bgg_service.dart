import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BggSearchResult {
  final String id; // Wikidata Q-id
  final String name;
  final int? year;
  final int? minPlayers;
  final int? maxPlayers;

  const BggSearchResult({
    required this.id,
    required this.name,
    this.year,
    this.minPlayers,
    this.maxPlayers,
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

/// Searches Wikidata for board games (free, no auth required).
class BggService {
  static const _sparqlUrl = 'https://query.wikidata.org/sparql';

  static const _headers = {
    'Accept': 'application/sparql-results+json',
    'User-Agent': 'MBGS-BoardGameApp/1.0 (personal board game tracker)',
  };

  Future<List<BggSearchResult>> searchGames(String query) async {
    if (query.trim().isEmpty) return [];
    debugPrint('[BGG] searchGames: "$query"');

    final escaped = query.toLowerCase().replaceAll('"', '\\"');

    final sparql = '''
SELECT DISTINCT ?item ?itemLabel ?p1872 ?p1873 ?year WHERE {
  ?item wdt:P31 wd:Q131436 .
  ?item rdfs:label ?itemLabel .
  FILTER(lang(?itemLabel) = "en")
  FILTER(contains(lcase(?itemLabel), "$escaped"))
  OPTIONAL { ?item wdt:P1872 ?p1872 }
  OPTIONAL { ?item wdt:P1873 ?p1873 }
  OPTIONAL { ?item wdt:P571 ?year }
}
ORDER BY ?itemLabel
LIMIT 20
''';

    final uri = Uri.parse(_sparqlUrl)
        .replace(queryParameters: {'query': sparql, 'format': 'json'});

    debugPrint('[Wikidata] GET $uri');

    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));

    debugPrint('[Wikidata] status=${response.statusCode}');

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final bindings = (data['results']?['bindings'] as List?) ?? [];

    final results = <BggSearchResult>[];
    for (final b in bindings) {
      final qid = (b['item']?['value'] as String?)?.split('/').last;
      final name = b['itemLabel']?['value'] as String?;
      if (qid == null || name == null || name.isEmpty) continue;

      final yearStr = b['year']?['value'] as String?;
      int? year;
      if (yearStr != null) {
        // Wikidata dates: "1995-01-01T00:00:00Z"
        year = int.tryParse(yearStr.substring(0, 4));
      }

      // Wikidata community enters P1872=actual_min, P1873=actual_max
      // (opposite to property labels) — we take min/max of both to be safe
      final v1 = double.tryParse(b['p1872']?['value'] ?? '')?.toInt();
      final v2 = double.tryParse(b['p1873']?['value'] ?? '')?.toInt();
      int? minP, maxP;
      if (v1 != null && v2 != null) {
        minP = v1 < v2 ? v1 : v2;
        maxP = v1 > v2 ? v1 : v2;
      } else if (v1 != null) {
        minP = v1;
      } else if (v2 != null) {
        maxP = v2;
      }

      results.add(BggSearchResult(
        id: qid,
        name: name,
        year: year,
        minPlayers: minP,
        maxPlayers: maxP,
      ));
    }

    // Exact/prefix matches first
    final q = query.toLowerCase();
    results.sort((a, b) {
      final aName = a.name.toLowerCase();
      final bName = b.name.toLowerCase();
      final aScore = aName == q ? 0 : aName.startsWith(q) ? 1 : 2;
      final bScore = bName == q ? 0 : bName.startsWith(q) ? 1 : 2;
      if (aScore != bScore) return aScore.compareTo(bScore);
      return aName.compareTo(bName);
    });

    debugPrint('[Wikidata] found ${results.length} results');
    return results;
  }

  /// Returns a [BggGameDetail] from a search result, or null if data is missing.
  Future<BggGameDetail?> getGameDetail(String id) async {
    // id is the Wikidata Q-id (e.g. "Q107835072")
    // We already have player counts in the search result;
    // this call is for getting a short description.
    final sparql = '''
SELECT ?itemLabel ?desc ?p1872 ?p1873 ?year WHERE {
  VALUES ?item { wd:$id }
  ?item rdfs:label ?itemLabel FILTER(lang(?itemLabel) = "en")
  OPTIONAL { ?item schema:description ?desc FILTER(lang(?desc) = "en") }
  OPTIONAL { ?item wdt:P1872 ?p1872 }
  OPTIONAL { ?item wdt:P1873 ?p1873 }
  OPTIONAL { ?item wdt:P571 ?year }
}
LIMIT 1
''';

    final uri = Uri.parse(_sparqlUrl)
        .replace(queryParameters: {'query': sparql, 'format': 'json'});

    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final bindings = (data['results']?['bindings'] as List?) ?? [];
    if (bindings.isEmpty) return null;

    final b = bindings.first as Map<String, dynamic>;
    final name = b['itemLabel']?['value'] as String?;
    if (name == null) return null;

    final desc = b['desc']?['value'] as String?;

    final yearStr = b['year']?['value'] as String?;
    int? year;
    if (yearStr != null) year = int.tryParse(yearStr.substring(0, 4));

    final v1 = double.tryParse(b['p1872']?['value'] ?? '')?.toInt();
    final v2 = double.tryParse(b['p1873']?['value'] ?? '')?.toInt();
    int minP = 2, maxP = 4;
    if (v1 != null && v2 != null) {
      minP = v1 < v2 ? v1 : v2;
      maxP = v1 > v2 ? v1 : v2;
    } else if (v1 != null) {
      minP = v1;
      maxP = v1;
    } else if (v2 != null) {
      minP = v2;
      maxP = v2;
    }

    return BggGameDetail(
      id: id,
      name: name,
      description: desc,
      minPlayers: minP,
      maxPlayers: maxP,
      yearPublished: year,
      imageUrl: null, // Wikidata has images but complex to retrieve
    );
  }
}
