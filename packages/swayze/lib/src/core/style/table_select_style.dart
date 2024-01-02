import 'package:flutter/widgets.dart' show Color, immutable;

/// Styles the square intersection of headers in the top left corner
/// Typically a triangle pointer
@immutable
class TableSelectStyle {
  /// The color of the resize line.
  final Color foregroundColor;

  /// The color of the resize line.
  final Color selectedForegroundColor;

  /// The color of the resize line circle fill.
  final Color backgroundFillColor;

  const TableSelectStyle({
    required this.foregroundColor,
    required this.selectedForegroundColor,
    required this.backgroundFillColor,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is TableSelectStyle &&
        other.foregroundColor == foregroundColor &&
        other.selectedForegroundColor == selectedForegroundColor &&
        other.backgroundFillColor == backgroundFillColor;
  }

  @override
  int get hashCode =>
      foregroundColor.hashCode ^
      selectedForegroundColor.hashCode ^
      backgroundFillColor.hashCode;
}
