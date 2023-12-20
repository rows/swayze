import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';

import '../../../widgets.dart';
import '../controller/selection/model/selection_style.dart';
import 'resize_header_style.dart';

/// Describes a collection of colors for headers in a determinate state.
@immutable
class SwayzeHeaderPalette {
  /// A [Color] for the backdrop of headers.
  final Color background;

  /// A [Color] for things such as the label of headers.
  final Color foreground;

  const SwayzeHeaderPalette({
    required this.background,
    required this.foreground,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwayzeHeaderPalette &&
          runtimeType == other.runtimeType &&
          background == other.background &&
          foreground == other.foreground;

  @override
  int get hashCode => background.hashCode ^ foreground.hashCode;
}

/// Describes a set of interface options used by elements inside a table.
@immutable
class SwayzeStyle {
  /// The default instance of [SwayzeStyle].
  ///
  /// It defines all due properties with arbitrary values.
  static late final defaultSwayzeStyle = SwayzeStyle(
    defaultHeaderPalette: const SwayzeHeaderPalette(
      background: Color(0xFFF7F7F7),
      foreground: Color(0xFF6F6F6F),
    ),
    selectedHeaderPalette: const SwayzeHeaderPalette(
      background: Color(0xFFFFC800),
      foreground: Color(0xFF000000),
    ),
    highlightedHeaderPalette: const SwayzeHeaderPalette(
      background: Color(0xFFE1E1E1),
      foreground: Color(0xFF000000),
    ),
    headerSeparatorColor: const Color(0xFFE1E1E1),
    headerTextStyle: const TextStyle(
      fontSize: 12,
    ),
    cellSeparatorColor: const Color(0xFFE1E1E1),
    cellSeparatorStrokeWidth: 1.0,
    defaultCellBackground: const Color(0xFFFFFFFF),
    userSelectionStyle: SelectionStyle.semiTransparent(
      color: Colors.amberAccent,
    ),
    selectionAnimationDuration: kDefaultScrollAnimationDuration,
    inlineEditorShadow: const [
      BoxShadow(
        color: Color(0x33000000),
        blurRadius: 10,
        offset: Offset(2, 2),
      ),
    ],
    dragAndDropStyle: const SwayzeHeaderDragAndDropStyle(
      previewHeadersColor: Colors.black26,
      previewLineColor: Colors.amberAccent,
      previewLineWidth: 2.0,
    ),
    dragAndFillStyle: const SwayzeDragAndFillStyle(
      color: Color(0xFF6F6F6F),
      handle: SwayzeDragAndFillHandleStyle(
        color: Color(0xFFFFC800),
      ),
    ),
    resizeHeaderStyle: const ResizeHeaderStyle(
      fillColor: Color(0xFFFFF6D4),
      lineColor: Color(0xFFFFC800),
    ),
  );

  // Headers
  /// A [SwayzeHeaderPalette] for the default state.
  final SwayzeHeaderPalette defaultHeaderPalette;

  /// A [SwayzeHeaderPalette] for when this header is selected.
  final SwayzeHeaderPalette selectedHeaderPalette;

  /// A [SwayzeHeaderPalette] for when this header is selected.
  final SwayzeHeaderPalette highlightedHeaderPalette;

  /// The color of the lines that separate headers.
  final Color headerSeparatorColor;

  /// The style of the text in the headers, color will by overwritten by
  /// [SwayzeHeaderPalette.foreground].
  final TextStyle headerTextStyle;

  /// The color of the lines that separates cells.
  final Color cellSeparatorColor;

  /// The width of the line that separates cells.
  final double cellSeparatorStrokeWidth;

  /// The color of the lines that separates cells.
  final Color defaultCellBackground;

  // Selections
  /// The default [UserSelectionStyle] for every [TableBodySelection] with
  /// decoration omitted.
  final SelectionStyle userSelectionStyle;

  /// The duration for the implicit animation on selections move and resize.
  final Duration selectionAnimationDuration;

  final List<BoxShadow> inlineEditorShadow;

  final SwayzeHeaderDragAndDropStyle dragAndDropStyle;

  final SwayzeDragAndFillStyle dragAndFillStyle;

  /// The style of the resize header line widget.
  final ResizeHeaderStyle resizeHeaderStyle;

  const SwayzeStyle({
    required this.defaultHeaderPalette,
    required this.selectedHeaderPalette,
    required this.highlightedHeaderPalette,
    required this.headerSeparatorColor,
    required this.headerTextStyle,
    required this.defaultCellBackground,
    required this.cellSeparatorColor,
    required this.cellSeparatorStrokeWidth,
    required this.userSelectionStyle,
    required this.selectionAnimationDuration,
    required this.inlineEditorShadow,
    required this.dragAndDropStyle,
    required this.dragAndFillStyle,
    required this.resizeHeaderStyle,
  });

  /// Copy an instance of [SwayzeStyle] with certain modifications.
  ///
  /// Use this to extend an existing style, such as [defaultSwayzeStyle].
  SwayzeStyle copyWith({
    SwayzeHeaderPalette? defaultHeaderPalette,
    SwayzeHeaderPalette? selectedHeaderPalette,
    SwayzeHeaderPalette? highlightedHeaderPalette,
    Color? headerSeparatorColor,
    TextStyle? headerTextStyle,
    Color? defaultCellBackground,
    Color? cellSeparatorColor,
    double? cellSeparatorStrokeWidth,
    SelectionStyle? userSelectionStyle,
    Duration? selectionAnimationDuration,
    List<BoxShadow>? inlineEditorShadow,
    SwayzeHeaderDragAndDropStyle? dragAndDropStyle,
    SwayzeDragAndFillStyle? dragAndFillStyle,
    ResizeHeaderStyle? resizeHeaderStyle,
  }) {
    return SwayzeStyle(
      defaultHeaderPalette: defaultHeaderPalette ?? this.defaultHeaderPalette,
      selectedHeaderPalette:
          selectedHeaderPalette ?? this.selectedHeaderPalette,
      highlightedHeaderPalette:
          highlightedHeaderPalette ?? this.highlightedHeaderPalette,
      headerSeparatorColor: headerSeparatorColor ?? this.headerSeparatorColor,
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      defaultCellBackground:
          defaultCellBackground ?? this.defaultCellBackground,
      cellSeparatorColor: cellSeparatorColor ?? this.cellSeparatorColor,
      cellSeparatorStrokeWidth:
          cellSeparatorStrokeWidth ?? this.cellSeparatorStrokeWidth,
      userSelectionStyle: userSelectionStyle ?? this.userSelectionStyle,
      selectionAnimationDuration:
          selectionAnimationDuration ?? this.selectionAnimationDuration,
      inlineEditorShadow: inlineEditorShadow ?? this.inlineEditorShadow,
      dragAndDropStyle: dragAndDropStyle ?? this.dragAndDropStyle,
      dragAndFillStyle: dragAndFillStyle ?? this.dragAndFillStyle,
      resizeHeaderStyle: resizeHeaderStyle ?? this.resizeHeaderStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwayzeStyle &&
          runtimeType == other.runtimeType &&
          defaultHeaderPalette == other.defaultHeaderPalette &&
          selectedHeaderPalette == other.selectedHeaderPalette &&
          highlightedHeaderPalette == other.highlightedHeaderPalette &&
          headerSeparatorColor == other.headerSeparatorColor &&
          headerTextStyle == other.headerTextStyle &&
          cellSeparatorColor == other.cellSeparatorColor &&
          defaultCellBackground == other.defaultCellBackground &&
          userSelectionStyle == other.userSelectionStyle &&
          selectionAnimationDuration == other.selectionAnimationDuration &&
          inlineEditorShadow == other.inlineEditorShadow &&
          dragAndDropStyle == other.dragAndDropStyle &&
          dragAndFillStyle == other.dragAndFillStyle &&
          resizeHeaderStyle == other.resizeHeaderStyle;

  @override
  int get hashCode =>
      defaultHeaderPalette.hashCode ^
      selectedHeaderPalette.hashCode ^
      highlightedHeaderPalette.hashCode ^
      headerSeparatorColor.hashCode ^
      headerTextStyle.hashCode ^
      cellSeparatorColor.hashCode ^
      defaultCellBackground.hashCode ^
      userSelectionStyle.hashCode ^
      inlineEditorShadow.hashCode ^
      dragAndDropStyle.hashCode ^
      dragAndFillStyle.hashCode ^
      resizeHeaderStyle.hashCode;
}

/// Style for header drag and drop preview widgets.
@immutable
class SwayzeHeaderDragAndDropStyle {
  /// The color of the line that previews where dragged headers will be dropped.
  final Color previewLineColor;

  /// Width of the line that previews where dragged headers will be dropped.
  final double previewLineWidth;

  /// The color of the preview headers that are being dragged.
  final Color previewHeadersColor;

  const SwayzeHeaderDragAndDropStyle({
    required this.previewLineColor,
    required this.previewLineWidth,
    required this.previewHeadersColor,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwayzeHeaderDragAndDropStyle &&
          runtimeType == other.runtimeType &&
          previewLineColor == other.previewLineColor &&
          previewLineWidth == other.previewLineWidth &&
          previewHeadersColor == other.previewHeadersColor;

  @override
  int get hashCode =>
      previewLineColor.hashCode ^
      previewLineWidth.hashCode ^
      previewHeadersColor.hashCode;
}

/// Style for the drag and fill selection.
@immutable
class SwayzeDragAndFillStyle {
  /// The color of the selection.
  final Color color;

  /// The width of the selection border.
  ///
  /// Defaults to `1.0`.
  final double borderWidth;

  final SwayzeDragAndFillHandleStyle handle;

  const SwayzeDragAndFillStyle({
    required this.color,
    this.borderWidth = 1.0,
    required this.handle,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwayzeDragAndFillStyle &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          borderWidth == other.borderWidth &&
          handle == other.handle;

  @override
  int get hashCode => color.hashCode ^ borderWidth.hashCode ^ handle.hashCode;
}

/// Style for the drag and fill handle.
@immutable
class SwayzeDragAndFillHandleStyle {
  /// The color of the handle.
  final Color color;

  /// The size of the handle rectangle.
  ///
  /// Defaults to `Size(5.0, 5.0)`.
  final Size size;

  /// The width of the border.
  ///
  /// Defaults to `1.0`.
  final double borderWidth;

  const SwayzeDragAndFillHandleStyle({
    required this.color,
    this.size = const Size(5.0, 5.0),
    this.borderWidth = 1.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwayzeDragAndFillHandleStyle &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          size == other.size &&
          borderWidth == other.borderWidth;

  @override
  int get hashCode => color.hashCode ^ size.hashCode ^ borderWidth.hashCode;
}
