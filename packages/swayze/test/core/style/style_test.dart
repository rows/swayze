import 'package:flutter/material.dart';
import 'package:swayze/controller.dart';
import 'package:swayze/widgets.dart';
import 'package:test/test.dart';

void main() {
  group('copyWith', () {
    test('should be able to override all fields', () {
      final everythingIsBlue = Colors.blue.shade100;
      const everythingIsBold = TextStyle(fontWeight: FontWeight.bold);
      const everythingIsFast = Duration(milliseconds: 510);

      final headerPalette = SwayzeHeaderPalette(
        background: everythingIsBlue,
        foreground: everythingIsBlue,
      );

      final selectionStyle = SelectionStyle.semiTransparent(
        color: everythingIsBlue,
      );

      final style = SwayzeStyle.defaultSwayzeStyle.copyWith(
        defaultHeaderPalette: headerPalette,
        selectedHeaderPalette: headerPalette,
        headerSeparatorColor: everythingIsBlue,
        headerTextStyle: everythingIsBold,
        cellSeparatorColor: everythingIsBlue,
        userSelectionStyle: selectionStyle,
        selectionAnimationDuration: everythingIsFast,
      );

      // Overridden with copyWith
      expect(style.defaultHeaderPalette, equals(headerPalette));
      expect(style.selectedHeaderPalette, equals(headerPalette));
      expect(style.headerSeparatorColor, equals(everythingIsBlue));
      expect(style.headerTextStyle, equals(everythingIsBold));
      expect(style.cellSeparatorColor, equals(everythingIsBlue));
      expect(style.userSelectionStyle, equals(selectionStyle));
      expect(style.selectionAnimationDuration, equals(everythingIsFast));
    });

    test('should be able to use all the defaults', () {
      final style = SwayzeStyle.defaultSwayzeStyle.copyWith();

      // Keep the default
      expect(
        style.headerSeparatorColor,
        equals(SwayzeStyle.defaultSwayzeStyle.headerSeparatorColor),
      );
      expect(
        style.defaultHeaderPalette,
        equals(SwayzeStyle.defaultSwayzeStyle.defaultHeaderPalette),
      );
      expect(
        style.selectedHeaderPalette,
        equals(SwayzeStyle.defaultSwayzeStyle.selectedHeaderPalette),
      );
      expect(
        style.headerTextStyle,
        equals(SwayzeStyle.defaultSwayzeStyle.headerTextStyle),
      );

      expect(
        style.cellSeparatorColor,
        equals(SwayzeStyle.defaultSwayzeStyle.cellSeparatorColor),
      );
      expect(
        style.userSelectionStyle,
        equals(SwayzeStyle.defaultSwayzeStyle.userSelectionStyle),
      );
      expect(
        style.selectionAnimationDuration,
        equals(SwayzeStyle.defaultSwayzeStyle.selectionAnimationDuration),
      );
    });
  });
}
