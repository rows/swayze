import 'package:cached_value/cached_value.dart';
import 'package:flutter/widgets.dart';

import '../../core/style/style.dart';

// TODO: [victor] doc.
class ReorderPreview extends StatelessWidget {
  final List<double> columnSizes;
  final List<double> rowSizes;
  final SwayzeStyle swayzeStyle;
  final Offset translateOffset;
  final int currentDropColumn;

  const ReorderPreview({
    Key? key,
    required this.columnSizes,
    required this.rowSizes,
    required this.swayzeStyle,
    required this.translateOffset,
    required this.currentDropColumn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lineColor = swayzeStyle.userSelectionStyle.borderSide.color;
    final lineWidth = swayzeStyle.userSelectionStyle.borderSide.width + 1;

    if (lineColor == null || lineWidth == 0.0 || lineColor.alpha == 0) {
      return const SizedBox.shrink();
    }

    return _ReorderPreviewPainter(
      columnSizes: columnSizes,
      rowSizes: rowSizes,
      lineColor: lineColor,
      lineWidth: lineWidth,
      translateOffset: translateOffset,
      currentDropColumn: currentDropColumn,
    );
  }
}

class _ReorderPreviewPainter extends LeafRenderObjectWidget {
  /// The size of each visible column
  final List<double> columnSizes;

  /// The size of each visible row
  final List<double> rowSizes;

  final Color lineColor;

  final double lineWidth;

  /// The offset in which the painting of lines will be translated by.
  final Offset translateOffset;

  final int currentDropColumn;

  const _ReorderPreviewPainter({
    Key? key,
    required this.columnSizes,
    required this.rowSizes,
    required this.lineColor,
    required this.lineWidth,
    required this.translateOffset,
    required this.currentDropColumn,
  }) : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderReorderDragDropPreviewLine(
      columnSizes,
      rowSizes,
      lineColor,
      lineWidth,
      translateOffset,
      currentDropColumn,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderReorderDragDropPreviewLine renderObject,
  ) {
    renderObject
      ..columnSizes = columnSizes
      ..rowSizes = rowSizes
      ..lineWidth = lineWidth
      ..lineColor = lineColor
      ..translateOffset = translateOffset
      ..currentDropColumn = currentDropColumn;
  }
}

class _RenderReorderDragDropPreviewLine extends RenderBox {
  List<double> _columnSizes;

  List<double> get columnSizes => _columnSizes;

  set columnSizes(List<double> value) {
    _columnSizes = value;
    markNeedsPaint();
  }

  List<double> _rowSizes;

  List<double> get rowSizes => _rowSizes;

  set rowSizes(List<double> value) {
    _rowSizes = value;
    markNeedsPaint();
  }

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

  int _currentDropColumn;
  int get currentDropColumn => _currentDropColumn;
  set currentDropColumn(int value) {
    _currentDropColumn = value;
    markNeedsPaint();
  }

  _RenderReorderDragDropPreviewLine(
    this._columnSizes,
    this._rowSizes,
    this._lineColor,
    this._lineWidth,
    this._translateOffset,
    this._currentDropColumn,
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
    // paint column lines
    // for (var i = 0; i < _columnSizes.length; i++) {
    //   canvas.translate(_columnSizes[i], 0);
    //   if (i == _currentDropColumn) {
    //     canvas.drawLine(
    //       Offset.zero,
    //       Offset(0, size.height),
    //       linePaintCache.value,
    //     );
    //     break;
    //   }
    // }
    canvas.translate(currentDropColumn.toDouble(), 0);
    canvas.drawLine(
      Offset.zero,
      Offset(0, size.height),
      linePaintCache.value,
    );
    canvas.restore();
  }
}
