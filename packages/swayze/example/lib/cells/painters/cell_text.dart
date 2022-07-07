import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:swayze/controller.dart';
import 'package:swayze/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../data/cell_data.dart';
import 'cell_background.dart';

const _kCellPadding = EdgeInsets.symmetric(
  vertical: 6.0,
  horizontal: 8.0,
);

const _kDefaultCellTextStyle = TextStyle(
  fontSize: 14,
  color: Colors.black,
  height: 1.428,
  letterSpacing: -0.1,
);

class CellTextOnly extends StatelessWidget {
  final MyCellData data;
  final IntVector2 position;
  final TextDirection textDirection;

  const CellTextOnly({
    Key? key,
    required this.data,
    required this.position,
    required this.textDirection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CellBackgroundPainter(
      backgroundColor: data.style?.backgroundColor,
      child: CellTextPainter(
        data: data,
        textDirection: textDirection,
      ),
    );
  }
}

/// A [SingleChildRenderObjectWidget] that render a the text of a cell
/// in the canvas.
class CellTextPainter extends SingleChildRenderObjectWidget {
  /// The cell model that mandates the paint of this cell
  final MyCellData data;

  final TextDirection textDirection;

  final double clipPadding;

  const CellTextPainter({
    Key? key,
    required this.data,
    required this.textDirection,
    this.clipPadding = 0.0,
    Widget? child,
  }) : super(key: key, child: child);

  @override
  _RenderCellTextPainter createRenderObject(BuildContext context) {
    return _RenderCellTextPainter(
      textDirection,
      clipPadding,
    )..update(data);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderCellTextPainter renderObject,
  ) {
    renderObject
      ..update(data)
      ..clipPadding = clipPadding;
  }
}

class _RenderCellTextPainter extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  final TextDirection textDirection;
  MyCellData? previousData;
  TextStyle? previousStyle;
  TextAlign? previousTextAlign;

  late final TextPainter textPainter = TextPainter(
    textDirection: textDirection,
  );

  _RenderCellTextPainter(
    this.textDirection,
    this._clipPadding,
  );

  /// Updates text on [textPainter] with the given [SwayzeCellData] and
  /// [SwayzeStyle].
  void update(MyCellData data) {
    var changedAnything = false;

    final style = data.toTextStyle(_kDefaultCellTextStyle);

    if (style != previousStyle || data.value != previousData?.value) {
      textPainter.text = TextSpan(
        text: data.value,
        style: style,
      );
      previousData = data;
      previousStyle = style;
      changedAnything = true;
    }

    final textAlign =
        data.style?.horizontalAlignment?.toTextAlign() ?? TextAlign.left;

    if (textAlign != previousTextAlign) {
      textPainter.textAlign = textAlign;
      previousTextAlign = textAlign;
      changedAnything = true;
    }

    if (!changedAnything) {
      return;
    }

    markNeedsLayout();
  }

  double get clipPadding => _clipPadding;
  double _clipPadding;

  set clipPadding(double value) {
    if (value == _clipPadding) {
      return;
    }

    _clipPadding = value;
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void performLayout() {
    if (child != null) {
      final actualChild = child!;
      final childConstraints = constraints.loosen();
      actualChild.layout(childConstraints, parentUsesSize: true);

      final childParentData = actualChild.parentData! as BoxParentData;

      final xPos = math.max(size.width - actualChild.size.width, 0.0);
      childParentData.offset = Offset(xPos, 0);
    }

    final contentWidth = size.width - _kCellPadding.horizontal;
    textPainter.layout(minWidth: contentWidth);

    final hasOverflowedHorizontally = textPainter.width > contentWidth;

    // If a numeric cell overflows the grid width, align it to the left
    // unless its alignment is explicitly set.
    if (hasOverflowedHorizontally) {
      textPainter.textAlign = TextAlign.left;
      textPainter.layout(minWidth: contentWidth);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    paintText(context, offset);

    if (child != null) {
      final childParentData = child!.parentData! as BoxParentData;
      context.paintChild(child!, offset + childParentData.offset);
    }
  }

  void paintText(PaintingContext context, Offset offset) {
    final canvas = context.canvas;

    canvas.save();

    final textVerticalCenter = textPainter.height > size.height
        ? _kCellPadding.top + offset.dy
        : (size.height / 2 - textPainter.height / 2) + offset.dy;

    final isToLeft = textPainter.textAlign == TextAlign.left ||
        (textPainter.textDirection == TextDirection.ltr
            ? textPainter.textAlign == TextAlign.start
            : textPainter.textAlign == TextAlign.end);

    final isToRight = textPainter.textAlign == TextAlign.right ||
        (textPainter.textDirection == TextDirection.ltr
            ? textPainter.textAlign == TextAlign.end
            : textPainter.textAlign == TextAlign.start);

    final isCentered = textPainter.textAlign == TextAlign.center;

    late final double textHorizontalPos;
    if (isToLeft) {
      textHorizontalPos = _kCellPadding.left;
    } else if (isToRight) {
      textHorizontalPos = _computeRightAlignedTextHorizontalPosition();
    } else if (isCentered) {
      textHorizontalPos = (size.width - textPainter.size.width) / 2;
    }

    final clippedSize = size + Offset(-clipPadding * 2, -clipPadding * 2);
    canvas.clipRect(Offset(clipPadding, clipPadding) & clippedSize);

    canvas.translate(textHorizontalPos, textVerticalCenter);

    textPainter.paint(canvas, Offset.zero);

    canvas.restore();
  }

  /// Calculate the horizontal position of the text when it's right aligned.
  ///
  /// It takes into consideration the child's width in order to proper display
  /// the text when, for example, a badge is shown on the cell.
  double _computeRightAlignedTextHorizontalPosition() {
    if (child != null) {
      return size.width - textPainter.size.width - child!.size.width;
    }

    return size.width - _kCellPadding.right - textPainter.size.width;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (child != null) {
      final childParentData = child!.parentData! as BoxParentData;
      final isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset? transformed) {
          assert(transformed == position - childParentData.offset);
          return child!.hitTest(result, position: transformed!);
        },
      );
      return isHit;
    }
    return false;
  }

  /// Describe the text semantics.
  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    config
      ..textDirection = TextDirection.ltr
      ..label = textPainter.text?.toPlainText() ?? '';
  }
}
