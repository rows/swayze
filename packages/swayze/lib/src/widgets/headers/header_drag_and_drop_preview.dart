import 'package:cached_value/cached_value.dart';
import 'package:flutter/material.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../core/style/style.dart';
import '../../core/viewport_context/viewport_context_provider.dart';

/// Renders the preview line and block of a header drag and drop action.
class HeaderDragAndDropPreview extends StatelessWidget {
  final Axis axis;
  final SwayzeStyle swayzeStyle;

  const HeaderDragAndDropPreview({
    Key? key,
    required this.axis,
    required this.swayzeStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lineColor = swayzeStyle.dragAndDropStyle.previewLineColor;
    final lineWidth = swayzeStyle.dragAndDropStyle.previewLineWidth;

    final viewportContext = ViewportContextProvider.of(context);
    final header = viewportContext.getAxisContextFor(axis: axis);
    final dragState = header.value.headerDragState;
    if (dragState == null || lineWidth == 0.0 || lineColor.alpha == 0) {
      return const SizedBox.shrink();
    }

    final currentHeaderIndex = dragState.dropAtIndex < dragState.headers.start
        ? dragState.dropAtIndex
        : dragState.dropAtIndex + 1;

    final dropHeaderAtPosition = viewportContext
        .positionToPixel(
          currentHeaderIndex,
          axis,
          isForFrozenPanes: currentHeaderIndex < header.value.frozenRange.end,
        )
        .pixel;

    final headerExtent = dragState.headersExtent;
    final headerPosition = viewportContext
        .positionToPixel(
          dragState.headers.start,
          axis,
          isForFrozenPanes: false,
        )
        .pixel;

    final blockedRange = Range(
      dragState.headers.start,
      dragState.headers.end + 1,
    );

    return Stack(
      children: [
        _PreviewRect(
          axis: axis,
          pointerPosition: dragState.position,
          headerPosition: headerPosition,
          headerExtent: headerExtent,
          color: swayzeStyle.dragAndDropStyle.previewHeadersColor,
        ),
        if (!blockedRange.contains(currentHeaderIndex))
          _PreviewLine(
            axis: axis,
            lineColor: lineColor,
            lineWidth: lineWidth,
            dropHeaderAtPosition: dropHeaderAtPosition,
          ),
      ],
    );
  }
}

class _PreviewLine extends LeafRenderObjectWidget {
  final Color lineColor;

  final double lineWidth;

  final double dropHeaderAtPosition;

  final Axis axis;

  const _PreviewLine({
    Key? key,
    required this.lineColor,
    required this.lineWidth,
    required this.dropHeaderAtPosition,
    required this.axis,
  }) : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderPreviewLine(
      axis,
      lineColor,
      lineWidth,
      dropHeaderAtPosition,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPreviewLine renderObject,
  ) {
    renderObject
      ..axis = axis
      ..lineWidth = lineWidth
      ..lineColor = lineColor
      ..dropHeaderAtPosition = dropHeaderAtPosition;
  }
}

class _RenderPreviewLine extends RenderBox {
  Color _lineColor;

  Color get lineColor => _lineColor;

  set lineColor(Color value) {
    _lineColor = value;
    markNeedsPaint();
  }

  double _lineWidth;

  double get lineWidth => _lineWidth;

  set lineWidth(double value) {
    _lineWidth = value;
    markNeedsLayout();
  }

  double _dropHeaderAtPosition;
  double get dropHeaderAtPosition => _dropHeaderAtPosition;
  set dropHeaderAtPosition(double value) {
    _dropHeaderAtPosition = value;
    markNeedsLayout();
  }

  Axis _axis;
  Axis get axis => _axis;
  set axis(Axis value) {
    _axis = value;
    markNeedsLayout();
  }

  _RenderPreviewLine(
    this._axis,
    this._lineColor,
    this._lineWidth,
    this._dropHeaderAtPosition,
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

  late final linePaintCache = CachedValue(
    () {
      return Paint()
        ..color = lineColor
        ..strokeWidth = lineWidth;
    },
  ).withDependency<Color?>(() => lineColor).withDependency(() => lineWidth);

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.translate(-0.5, -0.5);
    canvas.save();

    if (axis == Axis.horizontal) {
      canvas.translate(dropHeaderAtPosition, 0);
      canvas.drawLine(
        Offset.zero,
        Offset(0, size.height),
        linePaintCache.value,
      );
    } else {
      canvas.translate(0, dropHeaderAtPosition);
      canvas.drawLine(
        Offset.zero,
        Offset(size.width, 0),
        linePaintCache.value,
      );
    }
    canvas.restore();
  }
}

/// Renders a preview rect that represents the headers being dragged.
/// The preview follows the position of [pointerPosition].
class _PreviewRect extends LeafRenderObjectWidget {
  final Axis axis;
  final Offset pointerPosition;
  final double headerPosition;
  final double headerExtent;
  final Color color;

  const _PreviewRect({
    required this.headerPosition,
    required this.headerExtent,
    Key? key,
    required this.axis,
    required this.pointerPosition,
    required this.color,
  }) : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderPreviewRect(
        axis,
        pointerPosition,
        headerPosition,
        headerExtent,
        color,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPreviewRect renderObject,
  ) {
    renderObject
      ..axis = axis
      ..pointerPosition = pointerPosition
      ..headerPosition = headerPosition
      ..headerExtent = headerExtent
      ..color = color;
  }
}

class _RenderPreviewRect extends RenderBox {
  _RenderPreviewRect(
    this._axis,
    this._pointerPosition,
    this._headerPosition,
    this._headerExtent,
    this._color,
  );

  Offset _pointerPosition;
  Offset get pointerPosition => _pointerPosition;
  set pointerPosition(Offset value) {
    _pointerPosition = value;
    markNeedsPaint();
  }

  Axis _axis;
  Axis get axis => _axis;
  set axis(Axis value) {
    _axis = value;
    markNeedsPaint();
  }

  double _headerPosition;
  double get headerPosition => _headerPosition;
  set headerPosition(double value) {
    _headerPosition = value;
    markNeedsPaint();
  }

  double _headerExtent;
  double get headerExtent => _headerExtent;
  set headerExtent(double value) {
    _headerExtent = value;
    markNeedsPaint();
  }

  Color _color;
  Color get color => _color;
  set color(Color value) {
    _color = value;
    markNeedsPaint();
  }

  late final backgroundPaint = CachedValue(
    () => Paint()..color = color,
  );

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
    if (axis == Axis.horizontal) {
      final previewRect = Rect.fromLTWH(
        pointerPosition.dx - headerExtent / 2,
        0,
        headerExtent,
        size.height,
      );
      canvas.drawRect(previewRect, backgroundPaint.value);
    } else {
      final previewRect = Rect.fromLTWH(
        0,
        pointerPosition.dy - headerExtent / 2,
        size.width,
        headerExtent,
      );
      canvas.drawRect(previewRect, backgroundPaint.value);
    }
    canvas.restore();
  }
}
