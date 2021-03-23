import 'package:cached_value/cached_value.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/controller/controller.dart';
import '../selection_rendering_helpers.dart';

/// The amount of secondary selections with the same style that trigger them to
/// be combined rather than overlapped.
const kOverlapThreshold = 5;

/// A [LeafRenderObjectWidget] that renders a group of [SelectionRenderData]
/// with the same [selectionStyle].
///
/// When the amount of selections is bigger than [kOverlapThreshold],
/// it combines its visible rectangles using [PathOperation.union].
class SecondarySelectionGroup extends LeafRenderObjectWidget {
  final Iterable<SelectionRenderData> selectionGroup;
  final SelectionStyle selectionStyle;

  final Rect activeCellRect;

  const SecondarySelectionGroup({
    Key? key,
    required this.selectionGroup,
    required this.selectionStyle,
    required this.activeCellRect,
  }) : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderSelectionOverlapCombiner(
        selectionGroup,
        selectionStyle,
        activeCellRect,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSelectionOverlapCombiner renderObject,
  ) {
    renderObject
      ..selectionStyle = selectionStyle
      ..selectionGroup = selectionGroup
      ..activeCellRect = activeCellRect;
  }
}

class RenderSelectionOverlapCombiner extends RenderBox {
  RenderSelectionOverlapCombiner(
    this._selectionGroup,
    this._selectionStyle,
    this._activeCellRect,
  );

  Iterable<SelectionRenderData> _selectionGroup;

  Iterable<SelectionRenderData> get selectionGroup {
    return _selectionGroup;
  }

  set selectionGroup(Iterable<SelectionRenderData> value) {
    _selectionGroup = value;
    markNeedsPaint();
  }

  SelectionStyle _selectionStyle;

  SelectionStyle get selectionStyle {
    return _selectionStyle;
  }

  set selectionStyle(SelectionStyle value) {
    _selectionStyle = value;
    markNeedsPaint();
  }

  Rect _activeCellRect;

  Rect get activeCellRect {
    return _activeCellRect;
  }

  set activeCellRect(Rect value) {
    _activeCellRect = value;
    markNeedsPaint();
  }

  late final backgroundPaint = CachedValue(
    () => Paint()
      ..color = _selectionStyle.backgroundColor ?? const Color(0x00000000),
  ).withDependency(() => _selectionStyle.backgroundColor);

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;

    canvas.save();

    canvas.translate(offset.dx, offset.dy);

    final activeCellPath = Path()..addRect(_activeCellRect);

    if (_selectionGroup.length <= kOverlapThreshold) {
      // When there is less secondary selections than kOverlapThreshold,
      // just render each selection rectangle with the active cell rectangle
      // cropped into it.
      for (final selectionRenderData in _selectionGroup) {
        final selectionRect = selectionRenderData.rect;

        final selectionPath = Path()..addRect(selectionRect);

        final overallPath = Path.combine(
          PathOperation.difference,
          selectionPath,
          activeCellPath,
        );

        paintSelectionBorder(canvas, selectionRect, selectionRenderData.border);
        canvas.drawPath(overallPath, backgroundPaint.value);
      }
    } else {
      // When there is more secondary selections than kOverlapThreshold,
      // combine all shapes into a single one using union and crop the active
      // cell rectangle

      var backgroundPath = Path();
      for (final selectionRenderData in _selectionGroup) {
        final selectionRect = selectionRenderData.rect;
        final selectionPath = Path()..addRect(selectionRect);
        backgroundPath = Path.combine(
          PathOperation.union,
          backgroundPath,
          selectionPath,
        );

        paintSelectionBorder(canvas, selectionRect, selectionRenderData.border);
      }

      final overallPath = Path.combine(
        PathOperation.difference,
        backgroundPath,
        activeCellPath,
      );

      canvas.drawPath(overallPath, backgroundPaint.value);
    }

    canvas.restore();
  }
}
