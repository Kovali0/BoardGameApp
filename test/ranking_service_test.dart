import 'package:flutter_test/flutter_test.dart';
import 'package:board_game_manager/services/ranking_service.dart';

void main() {
  group('RankingService.computeBaseRanks', () {
    test('distinct scores produce sequential ranks', () {
      final result = RankingService.computeBaseRanks({'a': 30, 'b': 20, 'c': 10});
      expect(result, {'a': 1, 'b': 2, 'c': 3});
    });

    test('equal scores produce the same rank', () {
      final result = RankingService.computeBaseRanks({'a': 20, 'b': 20, 'c': 10});
      expect(result['a'], 1);
      expect(result['b'], 1);
      expect(result['c'], 3);
    });

    test('null scores produce rank 0', () {
      final result = RankingService.computeBaseRanks({'a': 10, 'b': null});
      expect(result['a'], 1);
      expect(result['b'], 0);
    });

    test('all null scores produce all zeros', () {
      final result = RankingService.computeBaseRanks({'a': null, 'b': null});
      expect(result, {'a': 0, 'b': 0});
    });

    test('single player gets rank 1', () {
      final result = RankingService.computeBaseRanks({'a': 42});
      expect(result, {'a': 1});
    });

    test('three-way tie all get rank 1', () {
      final result = RankingService.computeBaseRanks({'a': 5, 'b': 5, 'c': 5});
      expect(result, {'a': 1, 'b': 1, 'c': 1});
    });
  });

  group('RankingService.computeTieGroups', () {
    test('no ties returns empty map', () {
      final ranks = {'a': 1, 'b': 2, 'c': 3};
      expect(RankingService.computeTieGroups(ranks), isEmpty);
    });

    test('two players tied at rank 1', () {
      final ranks = {'a': 1, 'b': 1, 'c': 3};
      final groups = RankingService.computeTieGroups(ranks);
      expect(groups[1], containsAll(['a', 'b']));
      expect(groups.length, 1);
    });

    test('rank 0 players are excluded from tie groups', () {
      final ranks = {'a': 0, 'b': 0};
      expect(RankingService.computeTieGroups(ranks), isEmpty);
    });

    test('multiple separate tie groups', () {
      final ranks = {'a': 1, 'b': 1, 'c': 3, 'd': 3};
      final groups = RankingService.computeTieGroups(ranks);
      expect(groups[1], containsAll(['a', 'b']));
      expect(groups[3], containsAll(['c', 'd']));
    });
  });

  group('RankingService.computeFinalRanks', () {
    test('no ties: base ranks unchanged', () {
      final base = {'a': 1, 'b': 2, 'c': 3};
      final result = RankingService.computeFinalRanks(base, {});
      expect(result, {'a': 1, 'b': 2, 'c': 3});
    });

    test('tie broken by tieOrder: first in order gets base rank', () {
      final base = {'a': 1, 'b': 1, 'c': 3};
      final result = RankingService.computeFinalRanks(base, {
        1: ['b', 'a'],
      });
      expect(result['b'], 1);
      expect(result['a'], 2);
      expect(result['c'], 3);
    });

    test('tie with no override assigns sequential ranks from base', () {
      final base = {'a': 1, 'b': 1};
      final result = RankingService.computeFinalRanks(base, {});
      // Default group order ['a', 'b'] → a=1, b=2
      expect(result['a'], 1);
      expect(result['b'], 2);
    });

    test('rank 0 players unchanged', () {
      final base = {'a': 1, 'b': 0};
      final result = RankingService.computeFinalRanks(base, {});
      expect(result['b'], 0);
    });
  });

  group('RankingService.syncTieOrder', () {
    test('removes resolved tie groups', () {
      final base = {'a': 1, 'b': 2}; // no ties
      final updated = RankingService.syncTieOrder(base, {1: ['a', 'b']});
      expect(updated, isEmpty);
    });

    test('adds new tie group with default order', () {
      final base = {'a': 1, 'b': 1};
      final updated = RankingService.syncTieOrder(base, {});
      expect(updated[1], containsAll(['a', 'b']));
    });

    test('preserves existing user order for known group', () {
      final base = {'a': 1, 'b': 1};
      final updated = RankingService.syncTieOrder(base, {1: ['b', 'a']});
      expect(updated[1], ['b', 'a']);
    });

    test('removes player from group when score changes', () {
      final base = {'a': 1, 'b': 2, 'c': 2}; // 'a' no longer tied
      final updated = RankingService.syncTieOrder(base, {1: ['a', 'b']});
      expect(updated.containsKey(1), isFalse);
      expect(updated[2], containsAll(['b', 'c']));
    });
  });
}
