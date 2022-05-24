import 'package:cached_value/cached_value.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/widgets.dart';

import '../../../../config.dart';
import '../../../../core/style/style.dart';
import 'resize_header_mouse_region.dart';

class ResizeHeaderOverlayLine extends StatelessWidget {
  final SwayzeStyle swayzeStyle;
  final ValueNotifier<ResizeWidgetDetails?> resizeWidgetDetails;
  final Axis axis;

  const ResizeHeaderOverlayLine({
    Key? key,
    required this.swayzeStyle,
    required this.resizeWidgetDetails,
    required this.axis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ResizeWidgetDetails?>(
      valueListenable: resizeWidgetDetails,
      builder: (context, resizeWidgetDetails, child) {
        if (resizeWidgetDetails == null) {
          return const SizedBox.shrink();
        }

        return Positioned(
          left: resizeWidgetDetails.left,
          top: resizeWidgetDetails.top,
          child: SizedBox(
            width: resizeWidgetDetails.width,
            height: resizeWidgetDetails.height,
            child: child!,
          ),
        );
      },
      child: const _ResizeHeaderLine(
        fillColor: Colors.red,
        lineColor: Colors.green,
        lineWidth: 1,
      ),
    );
  }
}

class _ResizeHeaderLine extends LeafRenderObjectWidget {
  final Color lineColor;
  final Color fillColor;
  final double lineWidth;

  const _ResizeHeaderLine({
    required this.lineColor,
    required this.fillColor,
    required this.lineWidth,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderResizeHeaderLine(lineColor, fillColor, lineWidth);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderResizeHeaderLine renderObject,
  ) {
    renderObject
      ..lineWidth = lineWidth
      ..lineColor = lineColor
      ..fillColor = fillColor;
  }
}

class _RenderResizeHeaderLine extends RenderBox {
  Color _lineColor;

  Color get lineColor => _lineColor;

  set lineColor(Color value) {
    _lineColor = value;
    markNeedsPaint();
  }

  Color _fillColor;

  Color get fillColor => _fillColor;

  set fillColor(Color value) {
    _fillColor = value;
    markNeedsPaint();
  }

  double _lineWidth;

  double get lineWidth => _lineWidth;

  set lineWidth(double value) {
    _lineWidth = value;
    markNeedsPaint();
  }

  _RenderResizeHeaderLine(
    this._lineColor,
    this._fillColor,
    this._lineWidth,
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
        ..strokeWidth = lineWidth
        ..style = PaintingStyle.stroke;
    },
  ).withDependency<Color?>(() => lineColor);

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

    canvas.drawCircle(Offset.zero, radius, lineFillPaintCache.value);
    canvas.drawCircle(Offset.zero, radius, lineStrokePaintCache.value);

    canvas.drawLine(
      const Offset(0, 5),
      Offset(0, size.height + kColumnHeaderHeight),
      lineStrokePaintCache.value,
    );

    canvas.restore();
  }
}
