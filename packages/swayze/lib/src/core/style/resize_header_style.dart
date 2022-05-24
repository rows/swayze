import 'package:flutter/widgets.dart' show Color, immutable;

/// Defines the width of the resize header line as well as its colors.
@immutable
class ResizeHeaderStyle {
  /// The color of the resize line circle fill.
  final Color fillColor;

  /// The color of the resize line.
  final Color lineColor;

  /// The thickness of the line.
  final double lineThickness;

  const ResizeHeaderStyle({
    required this.fillColor,
    required this.lineColor,
    required this.lineThickness,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ResizeHeaderStyle &&
        other.fillColor == fillColor &&
        other.lineColor == lineColor &&
        other.lineThickness == lineThickness;
  }

  @override
  int get hashCode =>
      fillColor.hashCode ^ lineColor.hashCode ^ lineThickness.hashCode;
}
