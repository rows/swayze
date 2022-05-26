import 'package:flutter/widgets.dart' show Color, immutable;

/// Defines the width of the resize header line as well as its colors.
@immutable
class ResizeHeaderStyle {
  /// The color of the resize line circle fill.
  final Color fillColor;

  /// The color of the resize line.
  final Color lineColor;

  const ResizeHeaderStyle({
    required this.fillColor,
    required this.lineColor,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ResizeHeaderStyle &&
        other.fillColor == fillColor &&
        other.lineColor == lineColor;
  }

  @override
  int get hashCode => fillColor.hashCode ^ lineColor.hashCode;
}
