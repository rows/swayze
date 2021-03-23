import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A widget that forces all children to render at maximum size possible given
/// the current [BoxConstraints]
class ExpandAll extends MultiChildRenderObjectWidget {
  ExpandAll({
    Key? key,
    List<Widget> children = const <Widget>[],
  }) : super(key: key, children: children);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderExpandAll();
  }
}

class _ExpandAllData extends ContainerBoxParentData<RenderBox> {}

class _RenderExpandAll extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ExpandAllData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ExpandAllData> {
  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ExpandAllData) {
      child.parentData = _ExpandAllData();
    }
  }

  @override
  void performLayout() {
    final childConstraints = BoxConstraints.tight(size);

    RenderObject? child = firstChild;
    while (child != null) {
      child.layout(childConstraints);
      final childParentData = child.parentData! as _ExpandAllData;
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
    return defaultHitTestChildren(result, position: position);
  }
}
