import 'package:swayze_math/swayze_math.dart';
import 'package:test/test.dart';

void main() {
  group('IntVector2', () {
    test('diff', () {
      expect(
        const IntVector2(8, 4) - const IntVector2(2, 2),
        const IntVector2(6, 2),
      );
    });

    test('sum', () {
      expect(
        const IntVector2(5, 5) + const IntVector2.symmetric(2),
        const IntVector2(7, 7),
      );

      var vector = const IntVector2(5, 5);
      vector += const IntVector2(1, 2);

      expect(
        vector,
        const IntVector2(6, 7),
      );
    });

    test('smaller', () {
      expect(
        const IntVector2(5, 6) < const IntVector2(4, 4),
        false,
      );

      expect(
        const IntVector2(5, 1) < const IntVector2(4, 4),
        false,
      );

      expect(
        const IntVector2(3, 4) < const IntVector2(4, 4),
        false,
      );

      expect(
        const IntVector2(4, 4) < const IntVector2(4, 4),
        false,
      );

      expect(
        const IntVector2(3, 1) < const IntVector2(4, 4),
        true,
      );
    });

    test('bigger', () {
      expect(
        const IntVector2(5, 6) > const IntVector2(4, 4),
        true,
      );

      expect(
        const IntVector2(5, 1) > const IntVector2(4, 4),
        false,
      );

      expect(
        const IntVector2(3, 4) > const IntVector2(4, 4),
        false,
      );

      expect(
        const IntVector2(4, 4) > const IntVector2(4, 4),
        false,
      );

      expect(
        const IntVector2(3, 1) > const IntVector2(4, 4),
        false,
      );
    });
  });
}
