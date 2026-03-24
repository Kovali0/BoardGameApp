/// Pure ranking logic — no Flutter dependencies.
///
/// All methods operate on string-keyed maps so they work with both
/// name-keyed (EndSessionScreen) and index-keyed (AddResultsScreen) data.
class RankingService {
  RankingService._();

  /// Computes base ranks from [scores] ({key → nullable score}).
  ///
  /// Rules:
  /// - Equal scores get the same rank (dense ranking).
  /// - Unscored players (null) get rank 0.
  /// - Preserves input insertion order in the result map (important for
  ///   stable tie-group ordering downstream).
  static Map<String, int> computeBaseRanks(Map<String, int?> scores) {
    // Initialise all keys to 0 in insertion order.
    final result = {for (final k in scores.keys) k: 0};

    final scored = scores.entries.where((e) => e.value != null).toList()
      ..sort((a, b) => b.value!.compareTo(a.value!));

    int rank = 1;
    for (int i = 0; i < scored.length; i++) {
      if (i > 0 && scored[i].value != scored[i - 1].value) rank = i + 1;
      result[scored[i].key] = rank;
    }
    return result;
  }

  /// Returns tie groups: {rank → [keys]} for every rank shared by ≥2 players.
  ///
  /// Key order within each group follows the insertion order of [baseRanks].
  static Map<int, List<String>> computeTieGroups(Map<String, int> baseRanks) {
    final groups = <int, List<String>>{};
    for (final entry in baseRanks.entries) {
      if (entry.value == 0) continue;
      groups.putIfAbsent(entry.value, () => []).add(entry.key);
    }
    return Map.fromEntries(groups.entries.where((e) => e.value.length > 1));
  }

  /// Applies [tieOrder] overrides and returns final ranks.
  ///
  /// [tieOrder]: {baseRank → user-ordered list of keys within that tie}.
  /// When a tie group has no override the default group order is used,
  /// meaning all tied players keep the same base rank (true tie).
  static Map<String, int> computeFinalRanks(
    Map<String, int> baseRanks,
    Map<int, List<String>> tieOrder,
  ) {
    final tieGroups = computeTieGroups(baseRanks);
    final result = Map<String, int>.from(baseRanks);

    for (final entry in tieGroups.entries) {
      final baseRank = entry.key;
      final order = tieOrder[baseRank] ?? entry.value;
      for (int i = 0; i < order.length; i++) {
        result[order[i]] = baseRank + i;
      }
    }
    return result;
  }

  /// Keeps [currentTieOrder] in sync when scores change.
  ///
  /// - Removes resolved tie groups (rank no longer tied).
  /// - Adds new tie groups.
  /// - For existing groups: preserves user-set order while updating membership
  ///   (adds newcomers at the end, removes players who are no longer tied).
  static Map<int, List<String>> syncTieOrder(
    Map<String, int> baseRanks,
    Map<int, List<String>> currentTieOrder,
  ) {
    final tieGroups = computeTieGroups(baseRanks);
    final updated = Map<int, List<String>>.from(currentTieOrder)
      ..removeWhere((rank, _) => !tieGroups.containsKey(rank));

    for (final entry in tieGroups.entries) {
      final rank = entry.key;
      final newKeys = entry.value.toSet();
      if (updated.containsKey(rank)) {
        final reordered = updated[rank]!.where(newKeys.contains).toList();
        for (final k in newKeys) {
          if (!reordered.contains(k)) reordered.add(k);
        }
        updated[rank] = reordered;
      } else {
        updated[rank] = List.from(entry.value);
      }
    }
    return updated;
  }
}
