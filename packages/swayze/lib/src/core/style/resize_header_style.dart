import 'package:flutter/widgets.dart' show Color, immutable;

/// Defines the width of the resize header line as well as its colors.
@immutable
class ResizeHeaderStyle {
  final Color fillColor;
  final Color lineColor;
  final double lineWidth;

  const ResizeHeaderStyle({
    required this.fillColor,
    required this.lineColor,
    required this.lineWidth,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ResizeHeaderStyle &&
        other.fillColor == fillColor &&
        other.lineColor == lineColor &&
        other.lineWidth == lineWidth;
  }

  @override
  int get hashCode =>
      fillColor.hashCode ^ lineColor.hashCode ^ lineWidth.hashCode;
}
