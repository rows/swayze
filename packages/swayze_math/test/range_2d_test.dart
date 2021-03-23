import 'package:swayze_math/swayze_math.dart';
import 'package:test/test.dart';

void main() {
  group('Range2D', () {
    test('size', () {
      final r1 = Range2D.fromLTRB(
        const IntVector2(1, 10),
        const IntVector2(2, 10),
      );
      expect(r1.size, const IntVector2(1, 0));
      final r2 = Range2D.fromLTRB(
        const IntVector2.symmetric(1),
        const IntVector2(27, 42),
      );
      expect(r2.size, const IntVector2(26, 41));
    });
    test('range sides', () {
      final r1 = Range2D.fromLTRB(
        const IntVector2(1, 2),
        const IntVector2(5, 7),
      );
      expect(r1.xRange, const Range(1, 5));
      expect(r1.yRange, const Range(2, 7));
    });
    test('is nil', () {
      expect(
        Range2D.fromLTRB(
          const IntVector2(1, 2),
          const IntVector2(2, 4),
        ).isNil,
        false,
      );
      expect(
        Range2D.fromLTRB(
          const IntVector2(1, 2),
          const IntVector2(1, 4),
        ).isNil,
        true,
      );
      expect(
        Range2D.fromLTRB(
          const IntVector2(1, 2),
          const IntVector2(2, 2),
        ).isNil,
        true,
      );
    });
    test('overlaps', () {
      final r1 = Range2D.fromLTRB(
        const IntVector2(1, 2),
        const IntVector2(5, 7),
      );
      final r2 = Range2D.fromLTRB(
        const IntVector2(2, 0),
        const IntVector2(4, 4),
      );
      final r3 = Range2D.fromLTRB(
        const IntVector2(3, 0),
        const IntVector2(4, 2),
      );

      expect(r1.overlaps(r2), true);
      expect(r1.overlaps(r3), true);

      expect(r2.overlaps(r1), true);
      expect(r3.overlaps(r1), true);
    });
    test('intersection', () {
      final bigger = Range2D.fromLTWH(
        const IntVector2(0, 0),
        const IntVector2(10, 10),
      );

      final inside = Range2D.fromLTWH(
        const IntVector2(5, 5),
        const IntVector2(10, 10),
      );

      final intersection = bigger & inside;

      expect(
        intersection,
        Range2D.fromLTWH(
          const IntVector2(5, 5),
          const IntVector2(5, 5),
        ),
      );
    });
    test('equals', () {
      final r1 = Range2D.fromLTRB(
        const IntVector2(1, 2),
        const IntVector2(5, 7),
      );
      final r2 = Range2D.fromLTWH(
        const IntVector2(1, 2),
        const IntVector2(4, 5),
      );
      expect(r1, r2);
    });
    test('containsRange', () {
      final range = Range2D.fromLTRB(
        const IntVector2(10, 10),
        const IntVector2(20, 20),
      );

      expect(
        range.containsRange(
          Range2D.fromLTRB(
            const IntVector2(0, 0),
            const IntVector2(10, 10),
          ),
        ),
        false,
      );
      expect(
        range.containsRange(
          Range2D.fromLTRB(
            const IntVector2(20, 20),
            const IntVector2(30, 30),
          ),
        ),
        false,
      );

      expect(
        range.containsRange(
          Range2D.fromLTRB(
            const IntVector2(0, 0),
            const IntVector2(15, 15),
          ),
        ),
        false,
      );
      expect(
        range.containsRange(
          Range2D.fromLTRB(
            const IntVector2(15, 15),
            const IntVector2(30, 30),
          ),
        ),
        false,
      );

      expect(
        range.containsRange(
          Range2D.fromLTRB(
            const IntVector2(10, 10),
            const IntVector2(20, 20),
          ),
        ),
        true,
      );
      expect(
        range.containsRange(
          Range2D.fromLTRB(
            const IntVector2(12, 12),
            const IntVector2(18, 18),
          ),
        ),
        true,
      );
    });
    test('containsVector', () {
      final range = Range2D.fromLTRB(
        const IntVector2(10, 10),
        const IntVector2(20, 20),
      );

      expect(
        range.containsVector(const IntVector2(0, 0)),
        false,
      );

      expect(
        range.containsVector(const IntVector2(15, 0)),
        false,
      );

      expect(
        range.containsVector(const IntVector2(0, 15)),
        false,
      );

      expect(
        range.containsVector(const IntVector2(10, 10)),
        true,
      );

      expect(
        range.containsVector(const IntVector2(15, 15)),
        true,
      );

      expect(
        range.containsVector(const IntVector2(20, 20)),
        false,
      );
    });
  });
}
