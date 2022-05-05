import 'package:cached_value/cached_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../controller.dart';
import '../../core/style/style.dart';
import '../../core/viewport_context/viewport_context.dart';
import '../../core/viewport_context/viewport_context_provider.dart';
import '../internal_scope.dart';

// TODO: [victor] doc.
class ReorderPreview extends StatelessWidget {
  final Axis axis;
  final List<double> columnSizes;
  final List<double> rowSizes;
  final SwayzeStyle swayzeStyle;
  final Offset translateOffset;

  const ReorderPreview({
    Key? key,
    required this.axis,
    required this.columnSizes,
    required this.rowSizes,
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
    final selectionController = InternalScope.of(context).controller.selection;
    final tableController =
        InternalScope.of(context).controller.tableDataController;

    final header = viewportContext.getAxisContextFor(axis: axis);
    final dropHeaderAtPosition = viewportContext
        .positionToPixel(
          header.value.draggingCurrentReference! <
                  header.value.draggingHeaderIndex!
              ? header.value.draggingCurrentReference!
              : header.value.draggingCurrentReference! + 1,
          axis,
          isForFrozenPanes: false,
        )
        .pixel;

    // TODO: [victor] similar to selection rendering logic.
    final selection = selectionController.userSelectionState.selections;
    final selectionModel = selection.first;
    final range = selectionModel.bound(to: tableController.tableRange);
    final leftTopPixelOffset = getOffset(viewportContext, range.leftTop);
    final rightBottomPixelOffset =
        getOffset(viewportContext, range.rightBottom);
    final sizeOffset = rightBottomPixelOffset - leftTopPixelOffset;
    final size = Size(sizeOffset.dx, sizeOffset.dy);

    return Stack(
      children: [
        _PreviewRect(
          axis: axis,
          pointerPosition: header.value.draggingPosition,
          preview: leftTopPixelOffset & size,
        ),
        _PreviewLine(
          axis: axis,
          columnSizes: columnSizes,
          rowSizes: rowSizes,
          lineColor: lineColor,
          lineWidth: lineWidth,
          translateOffset: translateOffset,
          dropHeaderAtPosition: dropHeaderAtPosition,
        ),
      ],
    );
  }

  // TODO: [victor] same as selection
  Offset getOffset(ViewportContext viewportContext, IntVector2 coordinate) {
    final x = viewportContext
        .positionToPixel(
          coordinate.dx,
          Axis.horizontal,
          isForFrozenPanes: false,
        )
        .pixel;
    final y = viewportContext
        .positionToPixel(
          coordinate.dy,
          Axis.vertical,
          isForFrozenPanes: false,
        )
        .pixel;

    return Offset(x, y);
  }
}

class _PreviewLine extends LeafRenderObjectWidget {
  /// The size of each visible column
  final List<double> columnSizes;

  /// The size of each visible row
  final List<double> rowSizes;

  final Color lineColor;

  final double lineWidth;

  /// The offset in which the painting of lines will be translated by.
  final Offset translateOffset;

  final double dropHeaderAtPosition;

  final Axis axis;

  const _PreviewLine({
    Key? key,
    required this.columnSizes,
    required this.rowSizes,
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
  final Rect preview;
  final Offset pointerPosition;

  const _PreviewRect({
    Key? key,
    required this.axis,
    required this.preview,
    required this.pointerPosition,
  }) : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderPreviewRect(
        axis,
        preview,
        pointerPosition,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPreviewRect renderObject,
  ) {
    renderObject
      ..axis = axis
      ..preview = preview
      ..pointerPosition = pointerPosition;
  }
}

class _RenderPreviewRect extends RenderBox {
  _RenderPreviewRect(
    this._axis,
    this._preview,
    this._pointerPosition,
  );

  Rect _preview;

  Rect get preview {
    return _preview;
  }

  set preview(Rect value) {
    _preview = value;
    markNeedsPaint();
  }

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
      canvas.translate(pointerPosition.dx - _preview.topCenter.dx, 0);
      canvas.drawRect(_preview, backgroundPaint.value);
    } else {
      canvas.translate(0, pointerPosition.dy - _preview.topCenter.dy);
      canvas.drawRect(_preview, backgroundPaint.value);
    }
    canvas.restore();
  }
}
