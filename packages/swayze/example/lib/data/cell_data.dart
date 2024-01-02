import 'package:flutter/painting.dart';
import 'package:swayze/controller.dart';
import 'package:swayze_math/swayze_math.dart';

import 'cell_style.dart';

class MyCellData extends SwayzeCellData {
  final String? value;

  final MyCellStyle? style;

  const MyCellData({
    required String id,
    required IntVector2 position,
    required this.style,
    required this.value,
  }) : super(
          id: id,
          position: position,
        );

  @override
  Alignment get contentAlignment => Alignment.center;

  @override
  bool get hasVisibleContent => true;

  factory MyCellData.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;

    final rawPosition = json['position'] as Map<String, dynamic>;
    final position = IntVector2(
      rawPosition['x'] as int,
      rawPosition['y'] as int,
    );
    final value = json['value'] as String?;

    final styleMap = json['style'] as Map<String, dynamic>?;
    final style = styleMap != null ? MyCellStyle.fromJson(styleMap) : null;

    return MyCellData(
      id: id,
      position: position,
      value: value,
      style: style,
    );
  }

  TextStyle toTextStyle(
    TextStyle defaultTextStyle,
  ) {
    var textStyle = defaultTextStyle;

    if (style?.fontColor != null) {
      final color = style!.fontColor!;
      textStyle = textStyle.copyWith(color: color);
    }

    if (style?.isBold == true) {
      textStyle = textStyle.copyWith(fontWeight: FontWeight.bold);
    }

    if (style?.isItalic == true) {
      textStyle = textStyle.apply(fontStyle: FontStyle.italic);
    }

    if (style?.isUnderline == true) {
      textStyle = textStyle.copyWith(decoration: TextDecoration.underline);
    }

    return textStyle;
  }
}
