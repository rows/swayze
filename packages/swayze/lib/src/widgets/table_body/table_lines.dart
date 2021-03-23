import 'package:cached_value/cached_value.dart';
import 'package:flutter/widgets.dart';

import '../../core/style/style.dart';
import 'table_body.dart';

/// A [Widget] that paints the lines that separate the cells.
///
/// Should be the placed on [TableBody].
class TableLines extends StatelessWidget {
  /// The size of each visible column
  final List<double> columnSizes;

  /// The size of each visible row
  final List<double> rowSizes;

  final SwayzeStyle swayzeStyle;

  /// The offset in which the painting of lines will be translated by.
  final Offset translateOffset;

  const TableLines({
    Key? key,
    required this.columnSizes,
    required this.rowSizes,
    required this.swayzeStyle,
    required this.translateOffset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lineColor = swayzeStyle.cellSeparatorColor;
    final lineWidth = swayzeStyle.cellSeparatorStrokeWidth;

    if (lineWidth == 0.0 || lineColor.alpha == 0) {
      return const SizedBox.shrink();
    }

    return _TableLinesPainter(
      columnSizes: columnSizes,
      rowSizes: rowSizes,
      lineColor: lineColor,
      lineWidth: lineWidth,
      translateOffset: translateOffset,
    );
  }
}

class _TableLinesPainter extends LeafRenderObjectWidget {
  /// The size of each visible column
  final List<double> columnSizes;

  /// The size of each visible row
  final List<double> rowSizes;

  final Color lineColor;

  final double lineWidth;

  /// The offset in which the painting of lines will be translated by.
  final Offset translateOffset;

  const _TableLinesPainter({
    Key? key,
    required this.columnSizes,
    required this.rowSizes,
    required this.lineColor,
    required this.lineWidth,
    required this.translateOffset,
  }) : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderTableAreaLines(
      columnSizes,
      rowSizes,
      lineColor,
      lineWidth,
      translateOffset,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderTableAreaLines renderObject,
  ) {
    renderObject
      ..columnSizes = columnSizes
      ..rowSizes = rowSizes
      ..lineWidth = lineWidth
      ..lineColor = lineColor
      ..translateOffset = translateOffset;
  }
}

class _RenderTableAreaLines extends RenderBox {
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

  _RenderTableAreaLines(
    this._columnSizes,
    this._rowSizes,
    this._lineColor,
    this._lineWidth,
    this._translateOffset,
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

    /// TODO(renancaraujo): figure out this weird offset
    canvas.translate(-0.5, -0.5);

    canvas.translate(translateOffset.dx, translateOffset.dy);

    canvas.save();
    // paint column lines
    for (var i = 0; i < _columnSizes.length; i++) {
      canvas.translate(_columnSizes[i], 0);
      canvas.drawLine(
        Offset.zero,
        Offset(0, size.height),
        linePaintCache.value,
      );
    }
    canvas.restore();

    canvas.save();
    // paint row lines
    for (var index = 0; index < _rowSizes.length; index++) {
      canvas.translate(0, _rowSizes[index]);
      canvas.drawLine(
        Offset.zero,
        Offset(size.width, 0),
        linePaintCache.value,
      );
    }
    canvas.restore();
  }
}
