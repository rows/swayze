import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'header.dart';
import 'header_item.dart';

/// A [RenderObjectWidget] that places each one of the [children] in a linear
/// disposition respecting each child size.
///
/// See also:
/// - [Header] that uses this widget dis display the visible [HeaderItem]s.
class HeaderDisplacer extends MultiChildRenderObjectWidget {
  /// The axis in which the [children] will be displaced side by side.
  final Axis axis;
  final double frozenExtent;
  final int frozenCount;
  final double displacement;
  final Color background;

  HeaderDisplacer({
    Key? key,
    List<HeaderItem> children = const [],
    required this.axis,
    required this.frozenExtent,
    required this.frozenCount,
    required this.displacement,
    required this.background,
  }) : super(key: key, children: children);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderHeaderDisplacer(
      frozenExtent: frozenExtent,
      frozenCount: frozenCount,
      displacement: displacement,
      background: background,
    )..axis = axis;
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHeaderDisplacer renderObject,
  ) {
    renderObject
      ..axis = axis
      ..frozenExtent = frozenExtent
      ..frozenCount = frozenCount
      ..displacement = displacement
      ..background = background;
  }
}

class _HeaderDisplacerData extends ContainerBoxParentData<RenderBox> {}

class _RenderHeaderDisplacer extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _HeaderDisplacerData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _HeaderDisplacerData> {
  _RenderHeaderDisplacer({
    List<RenderBox>? children,
    Axis axis = Axis.horizontal,
    required double frozenExtent,
    required int frozenCount,
    required double displacement,
    required Color background,
  })  : _axis = axis,
        _frozenExtent = frozenExtent,
        _frozenCount = frozenCount,
        _displacement = displacement,
        _background = background {
    addAll(children);
  }

  Axis _axis;

  Axis get axis => _axis;

  set axis(Axis axis) {
    _axis = axis;
    markNeedsLayout();
  }

  double _frozenExtent;

  double get frozenExtent => _frozenExtent;

  set frozenExtent(double frozenExtent) {
    _frozenExtent = frozenExtent;
    markNeedsLayout();
  }

  int _frozenCount;

  int get frozenCount => _frozenCount;

  set frozenCount(int frozenCount) {
    _frozenCount = frozenCount;
    markNeedsLayout();
  }

  double _displacement;

  double get displacement => _displacement;

  set displacement(double displacement) {
    _displacement = displacement;
    markNeedsLayout();
  }

  Color _background;

  Color get background => _background;

  set background(Color background) {
    _background = background;
    markNeedsPaint();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _HeaderDisplacerData) {
      child.parentData = _HeaderDisplacerData();
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    var mainAxisExtent = 0.0;

    var child = firstChild;
    switch (_axis) {
      case Axis.horizontal:
        final innerConstraints =
            BoxConstraints.tightFor(height: constraints.maxHeight);
        while (child != null) {
          final childSize = child.getDryLayout(innerConstraints);
          mainAxisExtent += childSize.width;
          child = childAfter(child);
        }
        return constraints
            .constrain(Size(mainAxisExtent, constraints.maxHeight));
      case Axis.vertical:
        final innerConstraints =
            BoxConstraints.tightFor(width: constraints.maxWidth);
        while (child != null) {
          final childSize = child.getDryLayout(innerConstraints);
          mainAxisExtent += childSize.height;
          child = childAfter(child);
        }
        return constraints
            .constrain(Size(constraints.maxWidth, mainAxisExtent));
    }
  }

  @override
  void performLayout() {
    final constraints = this.constraints;
    var child = firstChild;
    var mainAxisExtent = 0.0;
    var childIndex = 0;
    switch (_axis) {
      case Axis.horizontal:
        final innerConstraints =
            BoxConstraints.tightFor(height: constraints.maxHeight);
        while (child != null) {
          child.layout(innerConstraints, parentUsesSize: true);
          final childParentData = child.parentData! as _HeaderDisplacerData;

          // Frozen headers should have its offset
          // compensating the displacement.
          if (childIndex < frozenCount) {
            childParentData.offset = Offset(
              mainAxisExtent + displacement.abs(),
              0.0,
            );
          } else {
            childParentData.offset = Offset(mainAxisExtent, 0.0);
          }

          mainAxisExtent += child.size.width;
          assert(child.parentData == childParentData);
          child = childParentData.nextSibling;
          childIndex++;
        }
        size =
            constraints.constrain(Size(mainAxisExtent, constraints.maxHeight));
        break;
      case Axis.vertical:
        final innerConstraints =
            BoxConstraints.tightFor(width: constraints.maxWidth);
        // ignore: invariant_booleans
        while (child != null) {
          child.layout(innerConstraints, parentUsesSize: true);
          final childParentData = child.parentData! as _HeaderDisplacerData;

          // Frozen headers should have its offset
          // compensating the displacement.
          if (childIndex < frozenCount) {
            childParentData.offset = Offset(
              0.0,
              mainAxisExtent + displacement.abs(),
            );
          } else {
            childParentData.offset = Offset(0.0, mainAxisExtent);
          }

          mainAxisExtent += child.size.height;
          assert(child.parentData == childParentData);
          child = childParentData.nextSibling;
          childIndex++;
        }
        size =
            constraints.constrain(Size(constraints.maxWidth, mainAxisExtent));
        break;
    }
    assert(size.isFinite);
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToFirstActualBaseline(baseline);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var child = lastChild;
    var childIndex = childCount - 1;

    while (child != null) {
      final childParentData = child.parentData! as _HeaderDisplacerData;
      context.paintChild(child, childParentData.offset + offset);
      child = childParentData.previousSibling;

      // The first non frozen header  should paint a rectangle equal to the
      // background to "clip" header displaced "under" the frozen headers.
      if (childIndex == frozenCount && frozenCount > 0) {
        final backgroundExtent = frozenExtent + displacement.abs();

        final width =
            axis == Axis.horizontal ? max(backgroundExtent, 0.0) : size.width;
        final height =
            axis == Axis.vertical ? max(backgroundExtent, 0.0) : size.height;

        context.canvas.drawRect(
          offset & Size(width, height),
          Paint()..color = background,
        );
      }
      childIndex--;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}
