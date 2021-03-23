import 'package:flutter/material.dart';
import 'package:swayze/helpers.dart';
import 'package:test/test.dart';

void main() {
  group('when converting from hex to Color', () {
    test('should be able to receive hex string without hash', () {
      expect(
        createColorFromHEX('00FF00'),
        equals(const Color.fromARGB(255, 0, 255, 0)),
      );
    });

    test('should be able to receive hex string with hash', () {
      expect(
        createColorFromHEX('00FFFF'),
        equals(const Color.fromARGB(255, 0, 255, 255)),
      );
    });
  });

  group('when converting from Color to hex', () {
    test('should be able to receive hex string without hash', () {
      expect(
        createHexStringFromColor(const Color.fromARGB(255, 0, 255, 0)),
        '#00FF00',
      );
    });
  });
}
