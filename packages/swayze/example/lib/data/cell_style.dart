import 'package:flutter/painting.dart';
import 'package:swayze/helpers.dart';

class MyCellStyle {
  final String? fontFamily;
  final Color? fontColor;
  final bool? isBold;
  final bool? isItalic;
  final bool? isUnderline;
  final int? numberDecimalPlaces;
  final Color? backgroundColor;
  final CellHorizontalAlignment? horizontalAlignment;

  const MyCellStyle({
    required this.fontFamily,
    required this.fontColor,
    required this.isBold,
    required this.isItalic,
    required this.isUnderline,
    required this.numberDecimalPlaces,
    required this.backgroundColor,
    required this.horizontalAlignment,
  });

  factory MyCellStyle.fromJson(Map<String, dynamic> json) {
    final fontFamily = json['fontFamily'] as String?;
    final fontColor = json['fontColor'] as String?;

    final isBold = json['isBold'] as bool?;
    final isItalic = json['isItalic'] as bool?;
    final isUnderline = json['isUnderline'] as bool?;

    final numberDecimalPlaces = json['numberDecimalPlaces'] as int?;
    final backgroundColor = json['backgroundColor'] as String?;

    final horizontalAlignmentString = json['alignment'] as String?;
    final horizontalAlignment = horizontalAlignmentString != null
        ? CellHorizontalAlignment.from(horizontalAlignmentString)
        : null;

    return MyCellStyle(
      fontFamily: fontFamily,
      fontColor: fontColor != null ? createColorFromHEX(fontColor) : null,
      isBold: isBold,
      isItalic: isItalic,
      isUnderline: isUnderline,
      numberDecimalPlaces: numberDecimalPlaces,
      backgroundColor:
          backgroundColor != null ? createColorFromHEX(backgroundColor) : null,
      horizontalAlignment: horizontalAlignment,
    );
  }
}

enum CellHorizontalAlignment {
  left('LEFT'),
  center('CENTER'),
  right('RIGHT');

  final String value;
  const CellHorizontalAlignment(this.value);

  factory CellHorizontalAlignment.from(String value) {
    return CellHorizontalAlignment.values.firstWhere(
      (element) => element.value == value,
    );
  }

  /// Convert to a flutter's [TextAlign]
  TextAlign toTextAlign() {
    if (this == CellHorizontalAlignment.center) {
      return TextAlign.center;
    } else if (this == CellHorizontalAlignment.left) {
      return TextAlign.left;
    } else if (this == CellHorizontalAlignment.right) {
      return TextAlign.right;
    }

    return TextAlign.start;
  }

  /// Convert to Flutter's [Alignment].
  Alignment toAlignment() {
    switch (this) {
      case CellHorizontalAlignment.left:
        return Alignment.centerLeft;

      case CellHorizontalAlignment.center:
        return Alignment.center;

      case CellHorizontalAlignment.right:
        return Alignment.centerRight;
    }
  }
}
