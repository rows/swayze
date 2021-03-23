import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class CellRootPainter extends MultiChildRenderObjectWidget {
  final double cellSeparatorStrokeWidth;

  CellRootPainter({
    Key? key,
    required Widget cellContent,
    required this.cellSeparatorStrokeWidth,
    Iterable<Widget> cellHoverWidgets = const <Widget>[],
  }) : super(
          key: key,
          children: <Widget>[
            cellContent,
            ...cellHoverWidgets,
          ],
        );

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderCellRootPainter(cellSeparatorStrokeWidth);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderCellRootPainter renderObject,
  ) {
    renderObject..cellSeparatorStrokeWidth = cellSeparatorStrokeWidth;
  }
}

class _CellRootParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderCellRootPainter extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _CellRootParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _CellRootParentData> {
  _RenderCellRootPainter(this._cellSeparatorStrokeWidth);

  /// See [SwayzeStyle.cellSeparatorStrokeWidth]
  double _cellSeparatorStrokeWidth;

  double get cellSeparatorStrokeWidth => _cellSeparatorStrokeWidth;

  set cellSeparatorStrokeWidth(double value) {
    _cellSeparatorStrokeWidth = value;
    markNeedsPaint();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _CellRootParentData) {
      child.parentData = _CellRootParentData();
    }
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void performLayout() {
    final lineStrokeCompensation = Offset(
      -cellSeparatorStrokeWidth,
      -cellSeparatorStrokeWidth,
    );

    final contentSize = size + lineStrokeCompensation;

    final cellContentConstraints = BoxConstraints.loose(contentSize);

    final RenderObject? cellContent = firstChild;

    cellContent!.layout(cellContentConstraints);
    final childParentData = cellContent.parentData! as _CellRootParentData;
    childParentData.offset = Offset.zero;

    var child = childParentData.nextSibling;

    final cellHoverConstraints = BoxConstraints.tight(contentSize);
    while (child != null) {
      child.layout(cellHoverConstraints);
      final childParentData = child.parentData! as _CellRootParentData;
      childParentData.offset = Offset.zero;
      child = childParentData.nextSibling;
    }

    assert(size.isFinite);
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToFirstActualBaseline(baseline);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final cellContent = firstChild!;

    final cellContentParentData =
        cellContent.parentData! as _CellRootParentData;

    final isCellContentHit = result.addWithPaintOffset(
      offset: cellContentParentData.offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset? transformed) {
        assert(transformed == position - cellContentParentData.offset);
        return cellContent.hitTest(result, position: transformed!);
      },
    );

    var cellHoverChild =
        (cellContent.parentData! as _CellRootParentData).nextSibling;

    while (cellHoverChild != null) {
      final childParentData = cellHoverChild.parentData! as _CellRootParentData;
      final isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset? transformed) {
          assert(transformed == position - childParentData.offset);
          return cellHoverChild!.hitTest(result, position: transformed!);
        },
      );
      if (isHit) {
        return true;
      }
      cellHoverChild = childParentData.nextSibling;
    }
    return isCellContentHit;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }

    return false;
  }
}
