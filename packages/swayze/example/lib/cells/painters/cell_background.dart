import 'package:cached_value/cached_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A [SingleChildRenderObjectWidget] that render a cell in the canvas, using
/// the given [backgroundColor] and [alignment].
class CellBackgroundPainter extends SingleChildRenderObjectWidget {
  /// The cell model that mandates the paint of this cell
  final Color? backgroundColor;

  final Alignment? alignment;

  const CellBackgroundPainter({
    Key? key,
    required this.backgroundColor,
    this.alignment,
    Widget? child,
  }) : super(key: key, child: child);

  @override
  _RenderCellBackgroundPainter createRenderObject(BuildContext context) =>
      _RenderCellBackgroundPainter(
        alignment: alignment,
        backgroundColor: backgroundColor,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderCellBackgroundPainter renderObject,
  ) {
    renderObject
      ..alignment = alignment
      ..backgroundColor = backgroundColor;
  }
}

class _RenderCellBackgroundPainter extends RenderShiftedBox {
  late Color? _backgroundColor;

  Color? get backgroundColor => _backgroundColor;

  set backgroundColor(Color? value) {
    if (_backgroundColor == value) {
      return;
    }

    _backgroundColor = value;
    markNeedsPaint();
  }

  late Alignment? _alignment;

  Alignment? get alignment => _alignment;

  set alignment(Alignment? value) {
    if (_alignment == value) {
      return;
    }

    _alignment = value;
    markNeedsLayout();
  }

  late final backgroundPaintCache = CachedValue(
    () {
      if (backgroundColor == null) {
        return null;
      }

      return Paint()
        ..color = backgroundColor!
        ..style = PaintingStyle.fill;
    },
  ).withDependency(() => backgroundColor);

  _RenderCellBackgroundPainter({
    required Alignment? alignment,
    required Color? backgroundColor,
    RenderBox? child,
  })  : _alignment = alignment,
        _backgroundColor = backgroundColor,
        super(child);

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void performLayout() {
    if (child != null) {
      final childConstraints = constraints.loosen();
      child!.layout(childConstraints, parentUsesSize: true);

      if (alignment != null) {
        final childParentData = child!.parentData! as BoxParentData;
        childParentData.offset = alignment!.alongOffset(
          size - child!.size as Offset,
        );
      }
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    if (backgroundPaintCache.value != null) {
      canvas.drawRect(Offset.zero & size, backgroundPaintCache.value!);
    }

    if (child != null) {
      final childParentData = child!.parentData! as BoxParentData;
      context.paintChild(child!, childParentData.offset);
    }
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
}
