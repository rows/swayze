import 'package:cached_value/cached_value.dart';
import 'package:flutter/widgets.dart';

import '../shared/border_info.dart';
import 'table_body.dart';

/// A [Widget] that paints the lines that separate the cells.
///
/// Should be the placed on [TableBody].
class TableLines extends StatelessWidget {
  /// The size of each visible column
  final List<double> columnSizes;

  /// The size of each visible row
  final List<double> rowSizes;

  //final SwayzeStyle swayzeStyle;
  final BorderInfo borderInfo;

  /// The offset in which the painting of lines will be translated by.
  final Offset translateOffset;

  const TableLines({
    Key? key,
    required this.columnSizes,
    required this.rowSizes,
    required this.borderInfo,
    required this.translateOffset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasFrozen =
        borderInfo.isOnAFrozenColumnsArea || borderInfo.isOnAFrozenRowsArea;
    final isFrozenVisible = borderInfo.frozenBorderSide.color.alpha > 0 ||
        borderInfo.frozenBorderSide.width > 0;
    final isCellVisible = borderInfo.cellBorderSide.color.alpha > 0 ||
        borderInfo.cellBorderSide.width > 0;
    if ((!hasFrozen && !isCellVisible) ||
        (!isFrozenVisible && !isCellVisible)) {
      return const SizedBox.shrink();
    }

    return _TableLinesPainter(
      columnSizes: columnSizes,
      rowSizes: rowSizes,
      borderInfo: borderInfo,
      translateOffset: translateOffset,
    );
  }
}

class _TableLinesPainter extends LeafRenderObjectWidget {
  /// The size of each visible column
  final List<double> columnSizes;

  /// The size of each visible row
  final List<double> rowSizes;

  // final Color lineColor;

  // final double lineWidth;
  final BorderInfo borderInfo;

  /// The offset in which the painting of lines will be translated by.
  final Offset translateOffset;

  const _TableLinesPainter({
    Key? key,
    required this.columnSizes,
    required this.rowSizes,
    required this.borderInfo,
    required this.translateOffset,
  }) : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderTableAreaLines(
      columnSizes,
      rowSizes,
      borderInfo,
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
      ..borderInfo = borderInfo
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

  BorderInfo _borderInfo;

  BorderInfo get borderInfo => _borderInfo;

  set borderInfo(BorderInfo value) {
    _borderInfo = value;
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
    this._borderInfo,
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

  CachedValue<Paint> paintCache(BorderSide side) => CachedValue(
        () {
          return Paint()
            ..color = side.color
            ..strokeWidth = side.width;
        },
      ).withDependency<BorderSide?>(() => side);

  late final frozenLinePaintCache = paintCache(borderInfo.frozenBorderSide);

  late final cellLinePaintCache = paintCache(borderInfo.cellBorderSide);

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;

    /// TODO(renancaraujo): figure out this weird offset
    canvas.translate(-0.5, -0.5);

    canvas.translate(translateOffset.dx, translateOffset.dy);

    canvas.save();

    // paint column lines
    final lastColumn = _columnSizes.length - 1;
    final bool isFrozenColumnArea = borderInfo.isOnAFrozenColumnsArea;
    for (var i = 0; i < _columnSizes.length; i++) {
      canvas.translate(_columnSizes[i], 0);
      canvas.drawLine(
        Offset.zero,
        Offset(0, size.height),
        isFrozenColumnArea && i == lastColumn
            ? frozenLinePaintCache.value
            : cellLinePaintCache.value,
      );
    }
    canvas.restore();

    canvas.save();
    // paint row lines
    final lastRow = _rowSizes.length - 1;
    final bool isFrozenRowArea = borderInfo.isOnAFrozenRowsArea;
    for (var index = 0; index < _rowSizes.length; index++) {
      canvas.translate(0, _rowSizes[index]);
      canvas.drawLine(
        Offset.zero,
        Offset(size.width, 0),
        isFrozenRowArea && index == lastRow
            ? frozenLinePaintCache.value
            : cellLinePaintCache.value,
      );
    }
    canvas.restore();
  }
}
