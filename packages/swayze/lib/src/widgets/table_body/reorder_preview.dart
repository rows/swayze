import 'package:cached_value/cached_value.dart';
import 'package:flutter/material.dart';

import '../../core/style/style.dart';
import '../../core/viewport_context/viewport_context_provider.dart';

// TODO: [victor] doc.
class ReorderPreview extends StatelessWidget {
  final Axis axis;
  final SwayzeStyle swayzeStyle;
  final Offset translateOffset;

  const ReorderPreview({
    Key? key,
    required this.axis,
    required this.swayzeStyle,
    required this.translateOffset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lineColor = swayzeStyle.userSelectionStyle.borderSide.color;
    final lineWidth = swayzeStyle.userSelectionStyle.borderSide.width + 1;

    if (lineColor == null || lineWidth == 0.0 || lineColor.alpha == 0) {
      return const SizedBox.shrink();
    }

    final viewportContext = ViewportContextProvider.of(context);
    final header = viewportContext.getAxisContextFor(axis: axis);

    final currentHeaderIndex = header.value.draggingCurrentReference! <
            header.value.draggingHeaders!.start
        ? header.value.draggingCurrentReference!
        : header.value.draggingCurrentReference! + 1;
    final dropHeaderAtPosition = viewportContext
            .positionToPixel(
              currentHeaderIndex,
              axis,
              isForFrozenPanes: false,
            )
            .pixel -
        header.value.frozenExtent;

    final headerExtent = header.value.draggingHeaderExtent;
    final headerPosition = viewportContext
        .positionToPixel(
          header.value.draggingHeaders!.start,
          axis,
          isForFrozenPanes: false,
        )
        .pixel;

    return Stack(
      children: [
        _PreviewRect(
          axis: axis,
          pointerPosition: header.value.draggingPosition,
          headerPosition: headerPosition,
          headerExtent: headerExtent,
        ),
        _PreviewLine(
          axis: axis,
          lineColor: lineColor,
          lineWidth: lineWidth,
          translateOffset: translateOffset,
          dropHeaderAtPosition: dropHeaderAtPosition,
        ),
      ],
    );
  }
}

class _PreviewLine extends LeafRenderObjectWidget {
  final Color lineColor;

  final double lineWidth;

  /// The offset in which the painting of lines will be translated by.
  final Offset translateOffset;

  final double dropHeaderAtPosition;

  final Axis axis;

  const _PreviewLine({
    Key? key,
    required this.lineColor,
    required this.lineWidth,
    required this.translateOffset,
    required this.dropHeaderAtPosition,
    required this.axis,
  }) : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderPreviewLine(
      axis,
      lineColor,
      lineWidth,
      translateOffset,
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
      ..translateOffset = translateOffset
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
    markNeedsPaint();
  }

  Offset _translateOffset;

  Offset get translateOffset => _translateOffset;

  set translateOffset(Offset value) {
    _translateOffset = value;
    markNeedsPaint();
  }

  double _dropHeaderAtPosition;
  double get dropHeaderAtPosition => _dropHeaderAtPosition;
  set dropHeaderAtPosition(double value) {
    _dropHeaderAtPosition = value;
    markNeedsPaint();
  }

  Axis _axis;
  Axis get axis => _axis;
  set axis(Axis value) {
    _axis = value;
    markNeedsPaint();
  }

  _RenderPreviewLine(
    this._axis,
    this._lineColor,
    this._lineWidth,
    this._translateOffset,
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
    canvas.translate(translateOffset.dx, translateOffset.dy);
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

// TODO: [victor] doc.
class _PreviewRect extends LeafRenderObjectWidget {
  final Axis axis;
  final Offset pointerPosition;
  final double headerPosition;
  final double headerExtent;

  const _PreviewRect({
    required this.headerPosition,
    required this.headerExtent,
    Key? key,
    required this.axis,
    required this.pointerPosition,
  }) : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderPreviewRect(
        axis,
        pointerPosition,
        headerPosition,
        headerExtent,
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
      ..headerExtent = headerExtent;
  }
}

class _RenderPreviewRect extends RenderBox {
  _RenderPreviewRect(
    this._axis,
    this._pointerPosition,
    this._headerPosition,
    this._headerExtent,
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

  // TODO: [victor] theme.
  late final backgroundPaint = CachedValue(
    () => Paint()..color = Colors.black26,
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
        headerPosition,
        0,
        headerExtent,
        size.height,
      );
      canvas.translate(pointerPosition.dx - previewRect.topCenter.dx, 0);
      canvas.drawRect(previewRect, backgroundPaint.value);
    } else {
      final previewRect = Rect.fromLTWH(
        0,
        headerPosition,
        size.width,
        headerExtent,
      );
      canvas.translate(0, pointerPosition.dy - previewRect.topCenter.dy);
      canvas.drawRect(previewRect, backgroundPaint.value);
    }
    canvas.restore();
  }
}
