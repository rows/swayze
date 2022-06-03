import 'package:cached_value/cached_value.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/style/style.dart';

/// Renders the resize header line.
///
/// See also:
/// - [_ResizeHeaderLine].
class ResizeHeaderLine extends StatelessWidget {
  final SwayzeStyle style;
  final Axis axis;

  const ResizeHeaderLine({
    Key? key,
    required this.style,
    required this.axis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _ResizeHeaderLine(
      axis: axis,
      fillColor: style.resizeHeaderStyle.fillColor,
      lineColor: style.resizeHeaderStyle.lineColor,
      thickness: style.cellSeparatorStrokeWidth,
    );
  }
}

/// A leaf render object that returns a [RenderBox] that paints an horizontal
/// or vertical line (depending on the axis) with the given properties.
///
/// See also:
/// - [_RenderResizeHeaderLine].
class _ResizeHeaderLine extends LeafRenderObjectWidget {
  final Axis axis;
  final Color lineColor;
  final Color fillColor;
  final double thickness;

  const _ResizeHeaderLine({
    required this.axis,
    required this.lineColor,
    required this.fillColor,
    required this.thickness,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderResizeHeaderLine(axis, lineColor, fillColor, thickness);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderResizeHeaderLine renderObject,
  ) {
    renderObject
      ..axis = axis
      ..lineColor = lineColor
      ..fillColor = fillColor
      ..thickness = thickness;
  }
}

/// Paints the header resize line at the canvas.
class _RenderResizeHeaderLine extends RenderBox {
  Axis _axis;

  Axis get axis => _axis;

  set axis(Axis value) {
    if (_axis == value) {
      return;
    }

    _axis = value;
    markNeedsLayout();
  }

  Color _lineColor;

  Color get lineColor => _lineColor;

  set lineColor(Color value) {
    if (_lineColor == value) {
      return;
    }

    _lineColor = value;
    markNeedsPaint();
  }

  Color _fillColor;

  Color get fillColor => _fillColor;

  set fillColor(Color value) {
    if (_fillColor == value) {
      return;
    }

    _fillColor = value;
    markNeedsPaint();
  }

  double _thickness;

  double get thickness => _thickness;

  set thickness(double value) {
    if (_thickness == value) {
      return;
    }

    _thickness = value;
    markNeedsPaint();
  }

  _RenderResizeHeaderLine(
    this._axis,
    this._lineColor,
    this._fillColor,
    this._thickness,
  );

  @override
  bool get isRepaintBoundary => true;

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  late final lineStrokePaintCache = CachedValue(
    () {
      return Paint()
        ..color = lineColor
        ..strokeWidth = thickness
        ..style = PaintingStyle.stroke;
    },
  )
      .withDependency<Color?>(() => lineColor)
      .withDependency<double?>(() => thickness);

  late final lineFillPaintCache = CachedValue(
    () {
      return Paint()..color = fillColor;
    },
  ).withDependency<Color?>(() => fillColor);

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;

    canvas.save();

    const radius = 5.0;

    // draw the circle first.
    canvas.drawCircle(Offset.zero, radius, lineFillPaintCache.value);

    // only then draw the border of the circle.
    canvas.drawCircle(Offset.zero, radius, lineStrokePaintCache.value);

    if (axis == Axis.horizontal) {
      canvas.drawLine(
        // draw the line after the circle
        const Offset(0, radius),
        Offset(0, size.height),
        lineStrokePaintCache.value,
      );
    } else {
      canvas.drawLine(
        // draw the line after the circle
        const Offset(radius, 0),
        Offset(size.width, 0),
        lineStrokePaintCache.value,
      );
    }

    canvas.restore();
  }
}
