import 'package:flutter/widgets.dart';
import 'package:swayze_math/swayze_math.dart';

import '../../../../helpers/basic_types.dart';
import 'selection_style.dart';

/// The most simple description of a portion of the grid that is supposed to
/// be selected or to receive a special decoration (defined by [style]).
///
/// Bottom and right values are non-inclusive, this means that a selection with
/// a bottom value of 14 includes up to the row with index 13.
///
/// Each side of the regularly rectangle-shaped region can receive a null value,
/// This mens that the selection ahs no clear bound (unbounded)
/// for that size, deferring the
/// boundaries to the size of the table.
///
/// For example, a selection with the following side values:
///  - left: 4
///  - top: 2
///  - right: null
///  - bottom 4
///
/// That selection will include all cells in the rows 2 and 3 and in the columns
/// starting from 4 until the end of the table to the right.
///
/// A table with both top and bottom values set to null will include entire
/// columns. The same applies to left and right selecting entire rows.
///
/// A table with all side values set to null will include all cells of a table.
///
/// Side values are assumed to be normalized, then subclasses should make sure
/// that these conditions are always true:
/// - top <= bottom
/// - left <= right
@immutable
abstract class Selection {
  SelectionStyle? get style;

  int? get top;

  int? get left;

  int? get right;

  int? get bottom;

  /// The coordinate within the selection that describes its 'origin',
  /// usually diametrically opposed to [focusCoordinate].
  IntVector2 get anchorCoordinate;

  /// The coordinate within the selection that describes the location where
  /// further directional changes should be based on.
  ///
  /// For example, if a selection is supposed to expand top the top, the new
  /// size will be calculated in such a way that should include the cell with a
  /// coordinate that equals to:
  ///
  /// ```
  /// // given focusCoordinate is f
  /// newF = IntVector2(f.left, f.top -1)
  /// ```
  ///
  /// Usually diametrically opposed to [anchorCoordinate].
  IntVector2 get focusCoordinate;
}

/// Non overridable [Selection] methods.
extension SelectionMethods on Selection {
  /// Bound a [Selection] to a [Range2D].
  ///
  /// Unbounded corners will receive the corresponding side from the [Range2D].
  ///
  /// If the given selection is located completely outside the given range, it
  /// will return a Range in which [Range2D.isNil] will be true.
  Range2D bound({
    required Range2D to,
  }) {
    final xRange = to.xRange;
    final yRange = to.yRange;

    final left = this.left?.clamp(xRange.start, xRange.end) ?? xRange.start;
    final top = this.top?.clamp(yRange.start, yRange.end) ?? yRange.start;

    final right = this.right?.clamp(xRange.start, xRange.end) ?? xRange.end;
    final bottom = this.bottom?.clamp(yRange.start, yRange.end) ?? yRange.end;

    return Range2D.fromPoints(IntVector2(left, top), IntVector2(right, bottom));
  }
}

/// Describes a [Selection] that is bounded at least in one dimension.
/// As a consequence it should have an [anchor] and a [focus] that should
/// influence the computation of [anchorCoordinate] and [focusCoordinate]
///
/// [EdgeType] is defined by which type of data structure the subclass is.
abstract class SelectionWithEdges<EdgeType> implements Selection {
  /// The edge that should include [anchorCoordinate]. anchor is the origin of
  /// a selection, it is the edge that should remain unchanged in an expansion
  /// operation.
  EdgeType get anchor;

  /// The edge that should include [focusCoordinate]. Focus should correspond
  /// the edge that should be changed in a expansion operation.
  EdgeType get focus;
}

/// Describes a [SelectionWithEdges] in which is completely bounded in one
/// [Axis] and partially or no bounded in the other axis
/// (called here cross-axis).
///
/// Since it subclasses an one dimensional [Range], [start] and [end] act as
/// the edges ([RangeEdge]) in the main [axis]
abstract class AxisBoundedSelection extends Range
    implements SelectionWithEdges<int> {
  /// Specified by [AxisBoundedSelection.crossAxisPartiallyBounded] defines
  /// which edge of the crossAxis [crossAxisBound] represents.
  final RangeEdge? crossAxisBoundedEdge;

  /// A dimensional index in the cross axis that defines one of its edges
  /// (as on [crossAxisBoundedEdge].
  final int? crossAxisBound;

  /// The axis completely bounded by [start] ad [end].
  final Axis axis;

  /// Defines with [RangeEdge] of the bounded axis represents the anchor.
  final RangeEdge anchorEdge;

  @override
  int get anchor => _indexOn(anchorEdge);

  @override
  int get focus => _indexOn(anchorEdge.opposite);

  /// Creates a [AxisBoundedSelection] in which the opposite axis to [axis] is
  /// unbounded in both edges.
  const AxisBoundedSelection.crossAxisUnbounded({
    required this.axis,
    required this.anchorEdge,
    // left fot horizontal, top for vertical
    required int start,
    // right fot horizontal, bottom for vertical
    required int end,
  })  : crossAxisBound = null,
        crossAxisBoundedEdge = null,
        super(start, end);

  /// Creates a [AxisBoundedSelection] in which the opposite axis to [axis] is
  /// partially bounded, this means that at least the and or start edges
  /// of that axis should be provided.
  const AxisBoundedSelection.crossAxisPartiallyBounded({
    required this.axis,
    required this.anchorEdge,
    // left fot horizontal, top for vertical
    required int start,
    // right fot horizontal, bottom for vertical
    required int end,
    required RangeEdge this.crossAxisBoundedEdge,
    required int this.crossAxisBound,
  }) : super(start, end);

  @override
  int? get left {
    if (axis == Axis.horizontal) {
      return start;
    }
    final crossAxisBoundedEdge = this.crossAxisBoundedEdge;
    if (crossAxisBoundedEdge == null) {
      return null;
    }
    switch (crossAxisBoundedEdge) {
      case RangeEdge.leading:
        return crossAxisBound;
      case RangeEdge.trailing:
        return null;
    }
  }

  @override
  int? get right {
    if (axis == Axis.horizontal) {
      return end;
    }
    final crossAxisBoundedEdge = this.crossAxisBoundedEdge;
    if (crossAxisBoundedEdge == null) {
      return null;
    }
    switch (crossAxisBoundedEdge) {
      case RangeEdge.leading:
        return null;
      case RangeEdge.trailing:
        return crossAxisBound;
    }
  }

  @override
  int? get top {
    if (axis == Axis.vertical) {
      return start;
    }
    final crossAxisBoundedEdge = this.crossAxisBoundedEdge;
    if (crossAxisBoundedEdge == null) {
      return null;
    }
    switch (crossAxisBoundedEdge) {
      case RangeEdge.leading:
        return crossAxisBound;
      case RangeEdge.trailing:
        return null;
    }
  }

  @override
  int? get bottom {
    if (axis == Axis.vertical) {
      return end;
    }
    final crossAxisBoundedEdge = this.crossAxisBoundedEdge;
    if (crossAxisBoundedEdge == null) {
      return null;
    }
    switch (crossAxisBoundedEdge) {
      case RangeEdge.leading:
        return null;
      case RangeEdge.trailing:
        return crossAxisBound;
    }
  }

  /// The [focusCoordinate] is the first coordinate of the given [focus]
  /// column/row.
  @override
  IntVector2 get focusCoordinate {
    final crossAxisValue = crossAxisBound ?? 0;
    return axis == Axis.horizontal
        ? IntVector2(focus, crossAxisValue)
        : IntVector2(crossAxisValue, focus);
  }

  /// The [anchorCoordinate] is the first coordinate of the given [anchor]
  /// column/row.
  ///
  /// See also:
  /// - [SelectionModel.anchorCoordinate];
  /// - [anchorEdge];
  @override
  IntVector2 get anchorCoordinate {
    final crossAxisValue = crossAxisBound ?? 0;
    return axis == Axis.horizontal
        ? IntVector2(anchor, crossAxisValue)
        : IntVector2(crossAxisValue, anchor);
  }

  /// Converts [RangeEdge] into an actual dimensional index.
  int _indexOn(RangeEdge rangeEdge) {
    switch (rangeEdge) {
      case RangeEdge.leading:
        return start;
      case RangeEdge.trailing:
        return end - 1;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is AxisBoundedSelection &&
          runtimeType == other.runtimeType &&
          crossAxisBoundedEdge == other.crossAxisBoundedEdge &&
          crossAxisBound == other.crossAxisBound &&
          axis == other.axis &&
          anchorEdge == other.anchorEdge;

  @override
  int get hashCode =>
      super.hashCode ^
      crossAxisBoundedEdge.hashCode ^
      crossAxisBound.hashCode ^
      axis.hashCode ^
      anchorEdge.hashCode;
}

/// Describes a [SelectionWithEdges] in which is completely bounded in all
/// sides. All side values are guaranteed to be non-null.
///
/// As a result, it naturally takes form of a [Range2D] and the edges are
/// described by coordinates [IntVector2] that represent each [Corner].
abstract class BoundedSelection extends Range2D
    implements SelectionWithEdges<IntVector2> {
  /// Defines which [Corner] represents the [anchorCoordinate]
  final Corner anchorCorner;

  BoundedSelection({
    required IntVector2 leftTop,
    required IntVector2 rightBottom,
    required this.anchorCorner,
  }) : super.fromPoints(leftTop, rightBottom);

  @override
  IntVector2 get anchor => _coordinatesOn(anchorCorner);

  @override
  IntVector2 get focus => _coordinatesOn(anchorCorner.opposite);

  @override
  int? get left => leftTop.dx;

  @override
  int? get right => rightBottom.dx;

  @override
  int? get top => leftTop.dy;

  @override
  int? get bottom => rightBottom.dy;

  bool get isSingle => size == const IntVector2.symmetric(1);

  /// Converts [Corner] into an actual cell coordinate.
  IntVector2 _coordinatesOn(Corner corner) {
    switch (corner) {
      case Corner.leftTop:
        return leftTop;
      case Corner.rightTop:
        return rightTop - const IntVector2(1, 0);
      case Corner.leftBottom:
        return leftBottom - const IntVector2(0, 1);
      case Corner.rightBottom:
        return rightBottom - const IntVector2(1, 1);
    }
  }

  /// See also:
  /// - [Selection.anchorCoordinate];
  /// - [anchorCorner];
  @override
  IntVector2 get anchorCoordinate => anchor;

  /// See also:
  /// - [Selection.focusCoordinate];
  /// - [anchorCorner];
  @override
  IntVector2 get focusCoordinate => focus;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is BoundedSelection &&
          runtimeType == other.runtimeType &&
          anchorCorner == other.anchorCorner;

  @override
  int get hashCode => super.hashCode ^ anchorCorner.hashCode;
}
