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
      const everythingIsTwo = 2.0;
      final emptyShadowList = List<BoxShadow>.empty();

      final headerPalette = SwayzeHeaderPalette(
        background: everythingIsBlue,
        foreground: everythingIsBlue,
      );

      final selectionStyle = SelectionStyle.semiTransparent(
        color: everythingIsBlue,
      );

      final tableSelectStyle = TableSelectStyle(
        foregroundColor: everythingIsBlue,
        selectedForegroundColor: everythingIsBlue,
        backgroundFillColor: everythingIsBlue,
      );

      final dragAndDropStyle = SwayzeHeaderDragAndDropStyle(
        previewLineColor: everythingIsBlue,
        previewLineWidth: everythingIsTwo,
        previewHeadersColor: everythingIsBlue,
      );

      final dragAndFillHandleStyle =
          SwayzeDragAndFillHandleStyle(color: everythingIsBlue);

      final dragAndFillStyle = SwayzeDragAndFillStyle(
        color: everythingIsBlue,
        handle: dragAndFillHandleStyle,
      );

      final resizeHeaderStyle = ResizeHeaderStyle(
        fillColor: everythingIsBlue,
        lineColor: everythingIsBlue,
      );

      final style = SwayzeStyle.defaultSwayzeStyle.copyWith(
        defaultHeaderPalette: headerPalette,
        selectedHeaderPalette: headerPalette,
        highlightedHeaderPalette: headerPalette,
        headerSeparatorColor: everythingIsBlue,
        headerTextStyle: everythingIsBold,
        tableSelectStyle: tableSelectStyle,
        defaultCellBackground: everythingIsBlue,
        cellSeparatorColor: everythingIsBlue,
        cellSeparatorStrokeWidth: everythingIsTwo,
        userSelectionStyle: selectionStyle,
        selectionAnimationDuration: everythingIsFast,
        inlineEditorShadow: emptyShadowList,
        dragAndDropStyle: dragAndDropStyle,
        dragAndFillStyle: dragAndFillStyle,
        resizeHeaderStyle: resizeHeaderStyle,
      );

      // Overridden with copyWith identical
      expect(style.defaultHeaderPalette, equals(headerPalette));
      expect(style.selectedHeaderPalette, equals(headerPalette));
      expect(style.highlightedHeaderPalette, equals(headerPalette));
      expect(style.headerSeparatorColor, equals(everythingIsBlue));
      expect(style.headerTextStyle, equals(everythingIsBold));
      expect(style.tableSelectStyle, equals(tableSelectStyle));
      expect(style.defaultCellBackground, equals(everythingIsBlue));
      expect(style.cellSeparatorColor, equals(everythingIsBlue));
      expect(style.cellSeparatorStrokeWidth, equals(everythingIsTwo));
      expect(style.userSelectionStyle, equals(selectionStyle));
      expect(style.selectionAnimationDuration, equals(everythingIsFast));
      expect(style.inlineEditorShadow, equals(emptyShadowList));
      expect(style.dragAndDropStyle, equals(dragAndDropStyle));
      expect(style.dragAndFillStyle, equals(dragAndFillStyle));
      expect(style.resizeHeaderStyle, equals(resizeHeaderStyle));

      // Same but not identical checks, ensuring key fields still match
      expect(
        style.defaultHeaderPalette,
        equals(
          SwayzeHeaderPalette(
            background: headerPalette.background,
            foreground: headerPalette.foreground,
          ),
        ),
      );
      expect(
        style.defaultHeaderPalette.hashCode,
        equals(
          headerPalette.hashCode,
        ),
      );
      expect(
        style.tableSelectStyle,
        equals(
          TableSelectStyle(
            foregroundColor: everythingIsBlue,
            selectedForegroundColor: everythingIsBlue,
            backgroundFillColor: everythingIsBlue,
          ),
        ),
      );
      expect(
        style.defaultHeaderPalette.hashCode,
        equals(
          headerPalette.hashCode,
        ),
      );

      expect(
        style.dragAndDropStyle,
        equals(
          SwayzeHeaderDragAndDropStyle(
            previewLineColor: everythingIsBlue,
            previewLineWidth: everythingIsTwo,
            previewHeadersColor: everythingIsBlue,
          ),
        ),
      );
      expect(
        style.dragAndFillStyle,
        equals(
          SwayzeDragAndFillStyle(
            color: everythingIsBlue,
            handle: dragAndFillHandleStyle,
          ),
        ),
      );
      expect(
        dragAndFillHandleStyle,
        equals(
          SwayzeDragAndFillHandleStyle(color: everythingIsBlue),
        ),
      );
      expect(
        resizeHeaderStyle,
        equals(
          ResizeHeaderStyle(
            fillColor: everythingIsBlue,
            lineColor: everythingIsBlue,
          ),
        ),
      );
    });

    test('should be able to use all the defaults', () {
      final style = SwayzeStyle.defaultSwayzeStyle.copyWith();

      // Keep the default
      expect(style, equals(SwayzeStyle.defaultSwayzeStyle));
      expect(style.hashCode, equals(SwayzeStyle.defaultSwayzeStyle.hashCode));
      expect(
        style.defaultHeaderPalette,
        equals(SwayzeStyle.defaultSwayzeStyle.defaultHeaderPalette),
      );
      expect(
        style.selectedHeaderPalette,
        equals(SwayzeStyle.defaultSwayzeStyle.selectedHeaderPalette),
      );
      expect(
        style.highlightedHeaderPalette,
        equals(SwayzeStyle.defaultSwayzeStyle.highlightedHeaderPalette),
      );
      expect(
        style.headerSeparatorColor,
        equals(SwayzeStyle.defaultSwayzeStyle.headerSeparatorColor),
      );
      expect(
        style.headerTextStyle,
        equals(SwayzeStyle.defaultSwayzeStyle.headerTextStyle),
      );
      expect(
        style.tableSelectStyle,
        equals(SwayzeStyle.defaultSwayzeStyle.tableSelectStyle),
      );
      expect(
        style.defaultCellBackground,
        equals(SwayzeStyle.defaultSwayzeStyle.defaultCellBackground),
      );
      expect(
        style.cellSeparatorColor,
        equals(SwayzeStyle.defaultSwayzeStyle.cellSeparatorColor),
      );
      expect(
        style.cellSeparatorStrokeWidth,
        equals(SwayzeStyle.defaultSwayzeStyle.cellSeparatorStrokeWidth),
      );
      expect(
        style.userSelectionStyle,
        equals(SwayzeStyle.defaultSwayzeStyle.userSelectionStyle),
      );
      expect(
        style.selectionAnimationDuration,
        equals(SwayzeStyle.defaultSwayzeStyle.selectionAnimationDuration),
      );
      expect(
        style.inlineEditorShadow,
        equals(SwayzeStyle.defaultSwayzeStyle.inlineEditorShadow),
      );
      expect(
        style.dragAndDropStyle,
        equals(SwayzeStyle.defaultSwayzeStyle.dragAndDropStyle),
      );
      expect(
        style.dragAndFillStyle,
        equals(SwayzeStyle.defaultSwayzeStyle.dragAndFillStyle),
      );
      expect(
        style.resizeHeaderStyle,
        equals(SwayzeStyle.defaultSwayzeStyle.resizeHeaderStyle),
      );
    });
  });
}
