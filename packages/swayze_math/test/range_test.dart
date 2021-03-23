import 'package:swayze_math/swayze_math.dart';
import 'package:test/test.dart';

void main() {
  group('Range', () {
    group('iterable', () {
      test('iterating', () {
        const range = Range(10, 20);
        expect(range.iterable.length, 10);
        var actual = range.start;
        for (final i in range.iterable) {
          expect(i, actual);
          actual++;
        }

        var actual2 = range.start;
        for (final index in range.iterable) {
          expect(index, actual2);
          actual2++;
        }
      });
      test('first last', () {
        const range = Range(10, 20);
        expect(range.iterable.first, 10);
        expect(range.iterable.last, 19);

        const rangeNil = Range(10, 10);
        expect(
          () => rangeNil.iterable.first,
          throwsA(const TypeMatcher<StateError>()),
        );
        expect(
          () => rangeNil.iterable.last,
          throwsA(const TypeMatcher<StateError>()),
        );
      });
      test('length', () {
        const range = Range(10, 20);
        expect(range.iterable.length, 10);
        const rangeNil = Range(10, 10);
        expect(rangeNil.iterable.length, 0);
      });
      test('single', () {
        const range = Range(10, 20);
        expect(
          () => range.iterable.single,
          throwsA(const TypeMatcher<StateError>()),
        );
        const rangeNil = Range(10, 10);
        expect(
          () => rangeNil.iterable.single,
          throwsA(const TypeMatcher<StateError>()),
        );
        const rangeSingle = Range(10, 11);
        expect(rangeSingle.iterable.single, 10);
      });
      test('empty', () {
        const range = Range(10, 20);
        expect(range.iterable.isEmpty, false);
        expect(range.iterable.isNotEmpty, true);
        const rangeNil = Range(10, 10);
        expect(rangeNil.iterable.isEmpty, true);
        expect(rangeNil.iterable.isNotEmpty, false);
      });
      test('forEach', () {
        const range = Range(10, 20);
        var actual = range.start;
        void forEachContent(int i) {
          expect(i, actual);
          actual++;
        }

        range.iterable.forEach(forEachContent);
      });
      test('toSet', () {
        const range = Range(10, 20);

        expect(range.iterable.toSet(), {
          10,
          11,
          12,
          13,
          14,
          15,
          16,
          17,
          18,
          19,
        });
      });
      test('toList', () {
        const range = Range(10, 20);

        expect(range.iterable.toList(), [
          10,
          11,
          12,
          13,
          14,
          15,
          16,
          17,
          18,
          19,
        ]);
      });
    });

    test('isNil', () {
      expect(const Range(4, 4).isNil, true);
      expect(const Range(1, 4).isNil, false);
    });

    test('cloning', () {
      const jango = Range(762, 1447);
      final gree = jango.clone();
      expect(jango == gree, true);
    });

    test('diff', () {
      const range = Range(10, 20);

      expect((range - const Range(15, 25)).toList(), [const Range(10, 15)]);
      expect((range - const Range(2, 12)).toList(), [const Range(12, 20)]);

      expect((range - const Range(13, 16)).toList(), [
        const Range(10, 13),
        const Range(16, 20),
      ]);

      expect((range - const Range(3, 26)).toList(), <Range>[]);
    });

    test('union', () {
      const range = Range(10, 20);

      expect((range + const Range(3, 26)).toList(), [const Range(3, 26)]);

      expect((range + const Range(13, 16)).toList(), [const Range(10, 20)]);
      expect((range + const Range(10, 20)).toList(), [const Range(10, 20)]);

      expect((range + const Range(17, 36)).toList(), [const Range(10, 36)]);
      expect((range + const Range(20, 36)).toList(), [const Range(10, 36)]);

      expect((range + const Range(7, 16)).toList(), [const Range(7, 20)]);
      expect((range + const Range(7, 10)).toList(), [const Range(7, 20)]);

      expect((range + const Range(27, 56)).toList(), [
        const Range(10, 20),
        const Range(27, 56),
      ]);
      expect((range + const Range(2, 4)).toList(), [
        const Range(10, 20),
        const Range(2, 4),
      ]);
    });

    test('stretch merge', () {
      const range = Range(10, 20);

      expect(range | const Range(30, 40), const Range(10, 40));
      expect(range | const Range(10, 19), const Range(10, 20));
      expect(range | const Range(11, 20), const Range(10, 20));
      expect(range | const Range(15, 25), const Range(10, 25));
    });

    test('intersection', () {
      const range = Range(10, 20);

      expect(range & const Range(30, 40), const Range(20, 20));
      expect(range & const Range(15, 25), const Range(15, 20));
      expect(range & const Range(5, 15), const Range(10, 15));
      expect(range & const Range(5, 25), const Range(10, 20));
    });

    test('overlaps', () {
      const range = Range(10, 20);

      expect(range.overlaps(const Range(15, 25)), true);
      expect(range.overlaps(const Range(5, 15)), true);
      expect(range.overlaps(const Range(5, 25)), true);
      expect(range.overlaps(const Range(15, 17)), true);
      expect(range.overlaps(const Range(10, 20)), true);
      expect(range.overlaps(const Range(25, 27)), false);
    });

    test('contains', () {
      const range = Range(10, 20);
      expect(range.contains(1), false);
      expect(range.contains(10), true);
      expect(range.contains(15), true);
      expect(range.contains(19), true);
      expect(range.contains(20), false);
      expect(range.contains(21), false);
    });

    test('containsRange', () {
      const range = Range(10, 20);
      expect(range.containsRange(const Range(15, 25)), false);
      expect(range.containsRange(const Range(5, 15)), false);
      expect(range.containsRange(const Range(5, 25)), false);
      expect(range.containsRange(const Range(15, 17)), true);
      expect(range.containsRange(const Range(10, 20)), true);
      expect(range.containsRange(const Range(25, 27)), false);
    });
  });

  group('RangeList', () {
    test('add', () {
      final rangeList = RangeCompactList();

      rangeList.add(const Range(10, 11));
      expect(rangeList.toList(), [
        const Range(10, 11),
      ]);
      rangeList.add(const Range(12, 13));
      expect(rangeList.toList(), [
        const Range(10, 11),
        const Range(12, 13),
      ]);
      rangeList.add(const Range(4, 5));
      expect(rangeList.toList(), [
        const Range(10, 11),
        const Range(12, 13),
        const Range(4, 5),
      ]);
      rangeList.add(const Range(10, 12));
      expect(rangeList.toList(), [
        const Range(4, 5),
        const Range(10, 13),
      ]);
      rangeList.add(const Range(15, 16));
      expect(rangeList.toList(), [
        const Range(4, 5),
        const Range(10, 13),
        const Range(15, 16),
      ]);
      rangeList.add(const Range(6, 8));
      expect(rangeList.toList(), [
        const Range(4, 5),
        const Range(10, 13),
        const Range(15, 16),
        const Range(6, 8),
      ]);
      rangeList.add(const Range(18, 19));
      expect(rangeList.toList(), [
        const Range(4, 5),
        const Range(10, 13),
        const Range(15, 16),
        const Range(6, 8),
        const Range(18, 19),
      ]);
      rangeList.add(const Range(1, 2));
      expect(rangeList.toList(), [
        const Range(4, 5),
        const Range(10, 13),
        const Range(15, 16),
        const Range(6, 8),
        const Range(18, 19),
        const Range(1, 2),
      ]);

      rangeList.add(const Range(2, 18));
      expect(rangeList.toList(), [const Range(1, 19)]);
    });

    test('add nil', () {
      final rangeList = RangeCompactList();

      rangeList.add(const Range(10, 10));
      expect(rangeList.isEmpty, true);
    });

    test('clone', () {
      final jango = RangeCompactList()
        ..add(const Range(10, 20))
        ..add(const Range(30, 40));
      final gree = jango.clone();
      expect(jango == gree, true);
    });

    test('union', () {
      final rangeList = RangeCompactList()
        ..add(const Range(10, 20))
        ..add(const Range(30, 40));
      final anotherRangeList = rangeList + const Range(20, 30);
      expect(anotherRangeList.toList(), [
        const Range(10, 40),
      ]);
    });

    test('intersection', () {
      final rangeList = RangeCompactList()
        ..add(const Range(10, 20))
        ..add(const Range(30, 40));
      final anotherRangeList = rangeList & const Range(15, 35);
      expect(anotherRangeList.toList(), [
        const Range(15, 20),
        const Range(30, 35),
      ]);
    });
  });
}
