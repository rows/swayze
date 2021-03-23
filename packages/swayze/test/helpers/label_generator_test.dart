import 'package:flutter/material.dart';
import 'package:swayze/src/helpers/label_generator.dart';
import 'package:swayze_math/swayze_math.dart';
import 'package:test/test.dart';

void main() {
  group('when providing a vertical axis', () {
    test('should throw exception if negative number is provided', () {
      expect(
        () => generateLabelForIndex(Axis.vertical, -1),
        throwsA(
          const TypeMatcher<UnsupportedError>(),
        ),
      );
    });

    test('should convert the index to the appropriate row number', () {
      expect(generateLabelForIndex(Axis.vertical, 1), '2');
      expect(generateLabelForIndex(Axis.vertical, 15000), '15001');
    });
  });

  group('when providing a horizontal axis', () {
    test('should throw exception if negative number is provided', () {
      expect(
        () => generateLabelForIndex(Axis.horizontal, -1),
        throwsA(
          const TypeMatcher<UnsupportedError>(),
        ),
      );

      expect(generateLabelForIndex(Axis.horizontal, 0), 'A');
      expect(generateLabelForIndex(Axis.horizontal, 25), 'Z');

      expect(generateLabelForIndex(Axis.horizontal, 26), 'AA');
      expect(generateLabelForIndex(Axis.horizontal, 51), 'AZ');
    });
  });

  group('generateLabelForCoordinate', () {
    test('should throw exception if negative number is provided', () {
      expect(
        () => generateLabelForCoordinate(const IntVector2(-1, 0)),
        throwsA(
          const TypeMatcher<UnsupportedError>(),
        ),
      );
      expect(
        () => generateLabelForCoordinate(const IntVector2(0, -1)),
        throwsA(
          const TypeMatcher<UnsupportedError>(),
        ),
      );
      expect(
        () => generateLabelForCoordinate(const IntVector2(-1, -1)),
        throwsA(
          const TypeMatcher<UnsupportedError>(),
        ),
      );

      expect(generateLabelForCoordinate(const IntVector2(0, 0)), 'A1');
      expect(generateLabelForCoordinate(const IntVector2(25, 50)), 'Z51');

      expect(generateLabelForCoordinate(const IntVector2(26, 50)), 'AA51');
      expect(generateLabelForCoordinate(const IntVector2(51, 50)), 'AZ51');
    });
  });
}
