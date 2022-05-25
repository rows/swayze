import 'package:cached_value/cached_value.dart';
import 'package:flutter/widgets.dart';

import '../../../../config.dart';
import '../../../../core/style/style.dart';

/// Paints the header resize line at the given position and with the
/// given size in [resizeWidgetDetails].
class ResizeHeaderOverlayLine extends StatelessWidget {
  final SwayzeStyle swayzeStyle;
  final ValueNotifier<Rect?> resizeLineRect;
  final Axis axis;

  const ResizeHeaderOverlayLine({
    Key? key,
    required this.swayzeStyle,
    required this.resizeLineRect,
    required this.axis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Rect?>(
      valueListenable: resizeLineRect,
      builder: (context, resizeLineRect, child) {
        if (resizeLineRect == null) {
          return const SizedBox.shrink();
        }

        return Positioned(
          left: resizeLineRect.left,
          top: resizeLineRect.top,
          child: SizedBox(
            width: resizeLineRect.width,
            height: resizeLineRect.height,
            child: child!,
          ),
        );
      },
      child: _ResizeHeaderLine(
        axis: axis,
        fillColor: swayzeStyle.resizeHeaderStyle.fillColor,
        lineColor: swayzeStyle.resizeHeaderStyle.lineColor,
        lineThickness: swayzeStyle.resizeHeaderStyle.lineThickness,
      ),
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
  final double lineThickness;

  const _ResizeHeaderLine({
    required this.axis,
    required this.lineColor,
    required this.fillColor,
    required this.lineThickness,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderResizeHeaderLine(axis, lineColor, fillColor, lineThickness);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderResizeHeaderLine renderObject,
  ) {
    renderObject
      ..axis = axis
      ..lineThickness = lineThickness
      ..lineColor = lineColor
      ..fillColor = fillColor;
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
    markNeedsPaint();
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

  double _lineThickness;

  double get lineThickness => _lineThickness;

  set lineThickness(double value) {
    if (_lineThickness == value) {
      return;
    }

    _lineThickness = value;
    markNeedsPaint();
  }

  _RenderResizeHeaderLine(
    this._axis,
    this._lineColor,
    this._fillColor,
    this._lineThickness,
  );

  @override
  bool get alwaysNeedsCompositing => true;

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
        ..strokeWidth = lineThickness
        ..style = PaintingStyle.stroke;
    },
  )
      .withDependency<Color?>(() => lineColor)
      .withDependency<double>(() => lineThickness);

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
        const Offset(0, 5),
        Offset(0, size.height + kColumnHeaderHeight),
        lineStrokePaintCache.value,
      );
    } else {
      canvas.drawLine(
        // draw the line after the circle
        const Offset(5, 0),
        Offset(size.width + kRowHeaderWidth, 0),
        lineStrokePaintCache.value,
      );
    }

    canvas.restore();
  }
}
